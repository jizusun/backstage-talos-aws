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

module "s3" {
  source       = "../../../modules/s3"
  cluster_name = "kumo-test"
}

output "bucket_name" {
  value = module.s3.bucket_name
}
