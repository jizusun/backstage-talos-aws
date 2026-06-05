cluster_name = "backstage-production"
environment  = "production"
region       = "us-east-1"
vpc_cidr     = "10.4.0.0/16"

control_plane = {
  count         = 3
  instance_type = "m5.large"
}

worker_groups = [{
  name          = "default"
  instance_type = "m5.large"
  desired_size  = 3
}]

database = {
  instance_class          = "db.r5.large"
  allocated_storage       = 200
  multi_az                = true
  backup_retention_period = 30
}
