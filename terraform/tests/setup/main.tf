# Shared setup for integration tests against kumo emulator
terraform {
  required_version = ">= 1.8.0"
}

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

variable "cluster_name" {
  type    = string
  default = "kumo-test"
}

module "s3" {
  source       = "../../modules/s3"
  cluster_name = var.cluster_name
}

output "bucket_id" {
  value = module.s3.bucket_id
}
