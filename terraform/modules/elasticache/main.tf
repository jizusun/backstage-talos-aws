resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_name}-redis"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
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

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.cluster_name}-redis"
  description          = "Redis for Backstage session/cache"

  engine             = "redis"
  engine_version     = "7.1"
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters
  port               = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = var.kms_key_id
  auth_token                 = var.auth_token

  tags = var.tags
}
