package terraform.compliance_test

import data.terraform.compliance
import future.keywords.if

all_tags := {"Project": "backstage", "Environment": "dev", "ManagedBy": "opentofu"}

test_unencrypted_rds if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.this",
    "change": {"actions": ["create"], "after": {"storage_encrypted": false, "tags": all_tags}},
  }]}
}

test_encrypted_rds if {
  count(compliance.violation) == 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.this",
    "change": {"actions": ["create"], "after": {"storage_encrypted": true, "multi_az": true, "tags": all_tags}},
  }]}
}

test_production_non_multi_az if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_db_instance",
    "address": "module.rds.aws_db_instance.production",
    "change": {"actions": ["create"], "after": {"storage_encrypted": true, "multi_az": false, "tags": all_tags}},
  }]}
}

test_missing_tags if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_instance",
    "address": "module.talos.aws_instance.cp",
    "change": {"actions": ["create"], "after": {"tags": {"Environment": "dev"}}},
  }]}
}

test_null_tags if {
  count(compliance.violation) > 0 with input as {"resource_changes": [{
    "type": "aws_s3_bucket",
    "address": "module.s3.aws_s3_bucket.this",
    "change": {"actions": ["create"], "after": {"tags": null}},
  }]}
}

test_all_tags_present if {
  count(compliance.violation) == 0 with input as {"resource_changes": [{
    "type": "aws_instance",
    "address": "module.talos.aws_instance.cp",
    "change": {"actions": ["create"], "after": {"tags": all_tags}},
  }]}
}

test_non_taggable_resource_ignored if {
  count(compliance.violation) == 0 with input as {"resource_changes": [{
    "type": "aws_route53_record",
    "address": "module.dns.aws_route53_record.this",
    "change": {"actions": ["create"], "after": {"tags": null}},
  }]}
}
