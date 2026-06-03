package terraform.compliance_test

import data.terraform.compliance
import future.keywords.if

test_unencrypted_rds if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.this",
    "change": {"after": {"storage_encrypted": false, "tags": {"Environment": "dev", "ManagedBy": "opentofu"}}},
  }]}
}

test_encrypted_rds if {
  count(compliance.violation) == 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.this",
    "change": {"after": {"storage_encrypted": true, "multi_az": true, "tags": {"Environment": "dev", "ManagedBy": "opentofu"}}},
  }]}
}

test_production_non_multi_az if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.production",
    "change": {"after": {"storage_encrypted": true, "multi_az": false, "tags": {"Environment": "production", "ManagedBy": "opentofu"}}},
  }]}
}
