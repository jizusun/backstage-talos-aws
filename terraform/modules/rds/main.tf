module "db" {
  #checkov:skip=CKV_TF_1:Using versioned registry module
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.cluster_name}-backstage"

  engine         = "postgres"
  engine_version = "15.8"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_encrypted     = true

  db_name  = "backstage"
  username = "backstage"
  password = var.db_password

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period             = var.backup_retention_period
  copy_tags_to_snapshot               = true
  auto_minor_version_upgrade          = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = var.kms_key_id
  skip_final_snapshot                 = var.environment == "dev"
  deletion_protection                 = var.environment == "production"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = true
  monitoring_interval                 = 60
  create_monitoring_role              = true

  family = "postgres15"
  parameters = [
    { name = "rds.force_ssl", value = "1" },
    { name = "pgaudit.log", value = "all" },
    { name = "log_statement", value = "all" }
  ]

  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.cluster_name}-db"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  #checkov:skip=CKV2_AWS_5:SG is attached via module.db vpc_security_group_ids
  name        = "${var.cluster_name}-db"
  description = "RDS PostgreSQL access from Talos cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from Talos cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.cluster_security_group_id]
  }

  tags = var.tags
}
