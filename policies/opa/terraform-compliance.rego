package terraform.compliance

import future.keywords.if
import future.keywords.in

required_tags := {"Project", "Environment", "ManagedBy"}

# AWS resource types that support tags
taggable_types := {
  "aws_instance",
  "aws_db_instance",
  "aws_s3_bucket",
  "aws_ecr_repository",
  "aws_elasticache_replication_group",
  "aws_security_group",
  "aws_lb",
  "aws_vpc",
  "aws_subnet",
  "aws_iam_role",
  "aws_iam_policy",
  "aws_eip",
}

# All RDS instances must have encryption enabled
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type == "aws_db_instance"
  resource.change.after.storage_encrypted == false
  msg := sprintf("%s: database must have encryption enabled", [resource.address])
}

# All S3 buckets must block public access
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.change.after.block_public_acls == false
  msg := sprintf("%s: S3 bucket must block public access", [resource.address])
}

# ElastiCache must have encryption at rest
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type == "aws_elasticache_replication_group"
  resource.change.after.at_rest_encryption_enabled == false
  msg := sprintf("%s: ElastiCache must have at-rest encryption", [resource.address])
}

# Production databases must be Multi-AZ
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type == "aws_db_instance"
  contains(resource.address, "production")
  resource.change.after.multi_az == false
  msg := sprintf("%s: production database must be Multi-AZ", [resource.address])
}

# All taggable resources must have required tags
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type in taggable_types
  resource.change.actions[_] in ["create", "update"]
  tags := object.get(resource.change.after, "tags", {})
  tags != null
  provided := {tag | tags[tag]}
  missing := required_tags - provided
  count(missing) > 0
  msg := sprintf("%s: missing required tags %v", [resource.address, missing])
}

# All taggable resources must not have null tags
violation[{"msg": msg}] if {
  resource := input.resource_changes[_]
  resource.type in taggable_types
  resource.change.actions[_] in ["create", "update"]
  tags := object.get(resource.change.after, "tags", null)
  tags == null
  msg := sprintf("%s: resource has no tags, required: %v", [resource.address, required_tags])
}
