cluster_name     = "backstage-perf"
environment      = "perf"
region           = "us-east-1"
secondary_region = "us-west-2"
multi_region     = true
vpc_cidr         = "10.2.0.0/16"

control_plane = {
  count         = 3
  instance_type = "c5.large"
}

worker_groups = [{
  name          = "default"
  instance_type = "c5.large"
  desired_size  = 3
  min_size      = 3
  max_size      = 6
  capacity_type = "ON_DEMAND"
}]

database = {
  instance_class          = "db.r5.large"
  allocated_storage       = 100
  multi_az                = true
  backup_retention_period = 7
}
