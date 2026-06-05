locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Cluster     = var.cluster_name
  })
}

# --- Networking ---

module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  tags         = local.tags
}

# --- Kubernetes (Talos) ---

module "talos" {
  #checkov:skip=CKV_TF_1:Using release tag for upstream module versioning
  source = "git::https://github.com/isovalent/terraform-aws-talos.git?ref=v0.15.1"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  region             = var.region
  tags               = local.tags

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
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "group-name"
    values = ["${var.cluster_name}*"]
  }

  depends_on = [module.talos]
}

# --- Data ---

module "rds" {
  source = "./modules/rds"

  cluster_name              = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = data.aws_security_groups.cluster.ids[0]
  environment               = var.environment
  instance_class            = var.database.instance_class
  allocated_storage         = var.database.allocated_storage
  multi_az                  = var.database.multi_az
  backup_retention_period   = var.database.backup_retention_period
  db_password               = var.db_password
  tags                      = local.tags
}

module "elasticache" {
  source = "./modules/elasticache"

  cluster_name              = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = data.aws_security_groups.cluster.ids[0]
  tags                      = local.tags
}

# --- Storage ---

module "s3" {
  source = "./modules/s3"

  cluster_name = var.cluster_name
  tags         = local.tags
}

module "ecr" {
  source = "./modules/ecr"

  cluster_name = var.cluster_name
  tags         = local.tags
}
