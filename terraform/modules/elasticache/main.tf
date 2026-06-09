module "redis" {
  #checkov:skip=CKV_TF_1:Using versioned registry module
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  cluster_id           = "${var.cluster_name}-redis"
  replication_group_id = "${var.cluster_name}-redis"
  description          = "Redis for Backstage session/cache"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = var.node_type

  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  tags = var.tags
}

resource "aws_security_group" "redis" {
  #checkov:skip=CKV2_AWS_5:SG is attached via module.redis security_group_ids
  name        = "${var.cluster_name}-redis"
  description = "ElastiCache Redis access from Talos cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis access from Talos cluster"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.cluster_security_group_id]
  }

  tags = var.tags
}
