# Integration test: apply/destroy S3 module against kumo emulator
# Run: kumo & sleep 2 && tofu test -chdir=terraform/test/fixtures/s3

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}

variables {
  cluster_name = "kumo-test"
}

run "s3_bucket_created" {
  command = apply

  assert {
    condition     = output.bucket_name == "kumo-test-assets"
    error_message = "S3 bucket name should be kumo-test-assets"
  }
}
