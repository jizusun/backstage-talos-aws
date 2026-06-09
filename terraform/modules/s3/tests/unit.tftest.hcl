mock_provider "aws" {}

variables {
  cluster_name = "test-cluster"
}

run "validates_successfully" {
  command = plan

  assert {
    condition     = module.bucket.s3_bucket_id != ""
    error_message = "S3 bucket should be created"
  }
}
