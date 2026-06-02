mock_provider "aws" {}

variables {
  cluster_name = "test-cluster"
}

run "immutable_tags" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "ECR must have immutable tags"
  }
}

run "scan_on_push_enabled" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "ECR must scan images on push"
  }
}
