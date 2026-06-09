module "bucket" {
  #checkov:skip=CKV_TF_1:Using versioned registry module
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.cluster_name}-assets"

  versioning = { enabled = true }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [{
    id     = "transition-and-expire"
    status = "Enabled"

    transition                             = [{ days = 30, storage_class = "STANDARD_IA" }]
    expiration                             = { days = 365 }
    abort_incomplete_multipart_upload_days = 7
  }]

  tags = var.tags
}
