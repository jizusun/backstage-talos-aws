locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Cluster     = var.cluster_name
  })
}

module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  tags         = local.tags
}

module "talos_cluster" {
  source = "./modules/talos-cluster"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  control_plane      = var.control_plane
  worker_groups      = var.worker_groups
  tags               = local.tags
}

module "rds" {
  source = "./modules/rds"

  cluster_name              = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.talos_cluster.cluster_security_group_id
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
  cluster_security_group_id = module.talos_cluster.cluster_security_group_id
  tags                      = local.tags
}

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
