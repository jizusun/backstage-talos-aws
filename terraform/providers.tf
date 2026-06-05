provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "backstage-platform"
      ManagedBy   = "opentofu"
      Environment = terraform.workspace
    }
  }
}
