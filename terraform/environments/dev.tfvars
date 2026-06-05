cluster_name = "backstage-dev"
environment  = "dev"
region       = "us-east-1"
vpc_cidr     = "10.0.0.0/16"

control_plane = {
  count         = 1
  instance_type = "t3.small"
}

worker_groups = [{
  name          = "default"
  instance_type = "t3.small"
  desired_size  = 1
}]

database = {
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  multi_az                = false
  backup_retention_period = 1
}
