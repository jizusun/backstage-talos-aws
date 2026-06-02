mock_provider "aws" {}

variables {
  cluster_name              = "test-cluster"
  vpc_id                    = "vpc-123"
  private_subnet_ids        = ["subnet-1", "subnet-2"]
  cluster_security_group_id = "sg-123"
  environment               = "production"
  db_password               = "testpass123"
  instance_class            = "db.r5.large"
  allocated_storage         = 100
  multi_az                  = true
}

run "encrypted_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "RDS must have encryption enabled"
  }
}

run "production_has_deletion_protection" {
  command = plan

  assert {
    condition     = aws_db_instance.this.deletion_protection == true
    error_message = "Production RDS must have deletion protection"
  }
}

run "dev_skips_deletion_protection" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == false
    error_message = "Dev RDS should not have deletion protection"
  }
}
