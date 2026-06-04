resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${aws_lb.api.dns_name}:443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = var.control_plane.count == 1
        proxy                          = { disabled = true }
        network                        = { cni = { name = "none" } }
        externalCloudProvider = {
          enabled = true
          manifests = [
            "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml"
          ]
        }
      }
      machine = {
        kubelet = {
          extraArgs = { "cloud-provider" = "external" }
        }
        features = {
          kubePrism = { enabled = true, port = 7445 }
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${aws_lb.api.dns_name}:443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [
    yamlencode({
      cluster = {
        proxy   = { disabled = true }
        network = { cni = { name = "none" } }
      }
      machine = {
        kubelet = {
          extraArgs = { "cloud-provider" = "external" }
        }
      }
    })
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = aws_instance.controlplane[*].public_ip
  nodes                = aws_instance.controlplane[*].private_ip
}

# --- Compute ---

data "aws_ami" "talos" {
  most_recent = true
  owners      = ["540036508848"] # Sidero Labs

  filter {
    name   = "name"
    values = ["talos-${var.talos_version}-*-amd64"]
  }
}

resource "aws_instance" "controlplane" {
  #checkov:skip=CKV_AWS_88:Talos needs public IP for API bootstrap
  count = var.control_plane.count

  ami                    = data.aws_ami.talos.id
  instance_type          = var.control_plane.instance_type
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile   = aws_iam_instance_profile.controlplane.name
  ebs_optimized          = true
  monitoring             = true

  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = data.talos_machine_configuration.controlplane.machine_configuration

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cp-${count.index}"
    Role = "controlplane"
  })
}

resource "aws_instance" "worker" {
  for_each = { for idx, w in local.worker_instances : idx => w }

  ami                    = data.aws_ami.talos.id
  instance_type          = each.value.instance_type
  subnet_id              = var.private_subnet_ids[each.key % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.cluster.id]
  iam_instance_profile   = aws_iam_instance_profile.worker.name
  ebs_optimized          = true
  monitoring             = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = data.talos_machine_configuration.worker.machine_configuration

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-worker-${each.key}"
    Role = "worker"
  })
}

locals {
  worker_instances = flatten([
    for group in var.worker_groups : [
      for i in range(group.desired_size) : {
        instance_type = group.instance_type
        group_name    = group.name
      }
    ]
  ])
}

# --- Networking ---

resource "aws_lb" "api" {
  name               = "${var.cluster_name}-api"
  load_balancer_type = "network"
  internal           = false
  subnets            = var.public_subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  access_logs {
    bucket  = var.lb_access_logs_bucket
    enabled = var.lb_access_logs_bucket != ""
  }

  tags = var.tags
}

resource "aws_lb_target_group" "k8s_api" {
  name     = "${var.cluster_name}-k8s"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = 6443
  }
}

resource "aws_lb_target_group" "talos_api" {
  name     = "${var.cluster_name}-talos"
  port     = 50000
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = 50000
  }
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}

resource "aws_lb_listener" "talos_api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 50000
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.talos_api.arn
  }
}

resource "aws_lb_target_group_attachment" "cp_k8s" {
  count            = var.control_plane.count
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.controlplane[count.index].id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "cp_talos" {
  count            = var.control_plane.count
  target_group_arn = aws_lb_target_group.talos_api.arn
  target_id        = aws_instance.controlplane[count.index].id
  port             = 50000
}

# --- Security Group ---

resource "aws_security_group" "cluster" {
  #checkov:skip=CKV_AWS_382:Cluster requires unrestricted egress for internet access
  name        = "${var.cluster_name}-cluster"
  description = "Talos cluster internal communication and API access"
  vpc_id      = var.vpc_id

  # Internal cluster communication
  ingress {
    description = "Internal cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Kubernetes API
  ingress {
    description = "Kubernetes API access"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Talos API
  ingress {
    description = "Talos API access"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# --- IAM ---

resource "aws_iam_role" "controlplane" {
  name = "${var.cluster_name}-cp"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cp_ccm" {
  role       = aws_iam_role.controlplane.name
  policy_arn = aws_iam_policy.ccm.arn
}

resource "aws_iam_policy" "ccm" {
  #checkov:skip=CKV_AWS_355:CCM requires broad resource scope for ELB management
  #checkov:skip=CKV_AWS_290:CCM requires write access without constraints (AWS pattern)
  name = "${var.cluster_name}-ccm"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:*",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "controlplane" {
  name = "${var.cluster_name}-cp"
  role = aws_iam_role.controlplane.name
}

resource "aws_iam_role" "worker" {
  name = "${var.cluster_name}-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_name}-worker"
  role = aws_iam_role.worker.name
}

# --- Bootstrap ---

resource "talos_machine_bootstrap" "this" {
  depends_on = [aws_instance.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = aws_instance.controlplane[0].public_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = aws_instance.controlplane[0].public_ip
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.root}/../kubeconfig"
}
