cluster_name = "test-full"
environment  = "staging"
vpc_cidr     = "10.1.0.0/16"

control_plane = {
  count         = 3
  instance_type = "m5.large"
}

worker_groups = [{
  name          = "default"
  instance_type = "m5.xlarge"
  desired_size  = 3
}]

database = {
  instance_class          = "db.r5.large"
  allocated_storage       = 100
  multi_az                = true
  backup_retention_period = 14
}
