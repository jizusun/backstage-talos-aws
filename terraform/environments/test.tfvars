cluster_name = "backstage-test"
environment  = "test"
region       = "us-east-1"
vpc_cidr     = "10.1.0.0/16"

control_plane = {
  count         = 3
  instance_type = "t3.medium"
}

worker_groups = [{
  name          = "default"
  instance_type = "t3.medium"
  desired_size  = 2
}]

database = {
  instance_class          = "db.t3.small"
  allocated_storage       = 50
  multi_az                = false
  backup_retention_period = 7
}
