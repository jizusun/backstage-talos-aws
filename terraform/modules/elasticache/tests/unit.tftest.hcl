mock_provider "aws" {}
mock_provider "random" {}

variables {
  cluster_name              = "test-cluster"
  vpc_id                    = "vpc-12345"
  private_subnet_ids        = ["subnet-1", "subnet-2"]
  cluster_security_group_id = "sg-12345"
}

run "validates_successfully" {
  command = plan

  assert {
    condition     = aws_security_group.redis.description == "ElastiCache Redis access from Talos cluster"
    error_message = "Security group should have correct description"
  }
}
