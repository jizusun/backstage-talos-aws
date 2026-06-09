module "ecr" {
  #checkov:skip=CKV_TF_1:Using versioned registry module
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  repository_name                 = "${var.cluster_name}/backstage"
  repository_image_tag_mutability = "IMMUTABLE"

  repository_image_scan_on_push = true
  repository_encryption_type    = "KMS"

  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })

  tags = var.tags
}
