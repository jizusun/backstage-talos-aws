cluster_name = "backstage-staging"
environment  = "staging"
region       = "us-east-1"
vpc_cidr     = "10.3.0.0/16"

control_plane = {
  count         = 3
  instance_type = "m5.large"
}

worker_groups = [{
  name          = "default"
  instance_type = "m5.large"
  desired_size  = 2
}]

database = {
  instance_class          = "db.r5.large"
  allocated_storage       = 100
  multi_az                = true
  backup_retention_period = 14
}
