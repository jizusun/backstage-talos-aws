package security.secrets_test

import data.security.secrets
import future.keywords.if

test_detects_aws_access_key if {
	count(secrets.violation) > 0 with input as {"files": [{
		"path": "main.tf",
		"content": "access_key = \"AKIAIOSFODNN7EXAMPLE\"",
	}]}
}

test_detects_private_key if {
	count(secrets.violation) > 0 with input as {"files": [{
		"path": "cert.tf",
		"content": "-----BEGIN RSA PRIVATE KEY-----\nMIIE...",
	}]}
}

test_detects_password_assignment if {
	count(secrets.violation) > 0 with input as {"files": [{
		"path": "config.yaml",
		"content": "password = \"supersecret123\"",
	}]}
}

test_clean_file_passes if {
	count(secrets.violation) == 0 with input as {"files": [{
		"path": "main.tf",
		"content": "resource \"aws_instance\" \"web\" {\n  ami = \"ami-123\"\n}",
	}]}
}

test_variable_reference_passes if {
	count(secrets.violation) == 0 with input as {"files": [{
		"path": "main.tf",
		"content": "password = var.db_password",
	}]}
}
