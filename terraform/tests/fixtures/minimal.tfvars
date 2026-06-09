cluster_name = "test-minimal"
environment  = "dev"

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
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  multi_az          = false
}
