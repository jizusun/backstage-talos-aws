package security.secrets

import future.keywords.if
import future.keywords.in

secret_patterns := {
	"aws_access_key": `AKIA[0-9A-Z]{16}`,
	"aws_secret_key": `[A-Za-z0-9/+=]{40}`,
	"private_key": `-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----`,
	"password_assignment": `(?i)(password|passwd|pwd)\s*[:=]\s*[\"'][^\"']{8,}[\"']`,
	"api_key": `(?i)(api[_-]?key|apikey)\s*[:=]\s*[\"'][^\"']+[\"']`,
	"generic_secret": `(?i)(secret|token)\s*[:=]\s*[\"'][^\"']{8,}[\"']`,
}

# Allowlisted file patterns (not scanned)
allowlisted_paths := [
	"*.test.*",
	"*_test.go",
	"policies/opa/*",
]

violation[{"msg": msg, "file": file_path, "pattern": pattern_name}] if {
	file := input.files[_]
	file_path := file.path
	not is_allowlisted(file_path)
	secret_patterns[pattern_name]
	regex.match(secret_patterns[pattern_name], file.content)
	msg := sprintf("Potential %s detected in %s", [pattern_name, file_path])
}

is_allowlisted(path) if {
	pattern := allowlisted_paths[_]
	glob.match(pattern, ["/"], path)
}
