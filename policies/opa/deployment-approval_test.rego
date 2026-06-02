package deployment.approval_test

import data.deployment.approval
import future.keywords.if

test_dev_allowed if {
	approval.allow with input as {"environment": "dev"}
}

test_production_denied if {
	not approval.allow with input as {"environment": "production", "approval_status": "pending"}
}

test_production_approved if {
	approval.allow with input as {
		"environment": "production",
		"approval_status": "approved",
		"approver": "platform-lead",
	}
		 with data.authorized_approvers as {"production": ["platform-lead"]}
}

test_production_unauthorized_approver if {
	not approval.allow with input as {
		"environment": "production",
		"approval_status": "approved",
		"approver": "random-user",
	}
		 with data.authorized_approvers as {"production": ["platform-lead"]}
}

test_staging_approved if {
	approval.allow with input as {
		"environment": "staging",
		"approval_status": "approved",
		"approver": "security-lead",
	}
		 with data.authorized_approvers as {"staging": ["security-lead"]}
}

test_violation_production_unapproved if {
	count(approval.violation) > 0 with input as {
		"environment": "production",
		"approval_status": "pending",
	}
}
