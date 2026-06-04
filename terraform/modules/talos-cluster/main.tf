module "talos" {
  #checkov:skip=CKV_TF_1:Using release tag for upstream module versioning
  source = "git::https://github.com/isovalent/terraform-aws-talos.git?ref=v0.15.1"

  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  region             = var.region
  tags               = var.tags

  control_plane = {
    instance_type = var.control_plane.instance_type
    count         = var.control_plane.count
  }

  worker_groups = [for wg in var.worker_groups : {
    name          = wg.name
    instance_type = wg.instance_type
  }]

  workers_count         = try(var.worker_groups[0].desired_size, 2)
  external_source_cidrs = var.allowed_cidrs
}

data "aws_security_groups" "cluster" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "group-name"
    values = ["${var.cluster_name}*"]
  }

  depends_on = [module.talos]
}
