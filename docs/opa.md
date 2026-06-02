# OPA (Open Policy Agent) — When & How to Apply

## What is OPA?

A general-purpose policy engine that evaluates structured data against declarative Rego policies. For Terraform, it validates plan JSON to enforce compliance before `apply`.

## When to Use OPA

| Scenario | Use OPA? | Why |
|----------|----------|-----|
| Enforce encryption on all databases | ✅ | Declarative rule, catches at plan time |
| Require approval for prod deploys | ✅ | Workflow governance |
| Block hardcoded secrets in code | ✅ | Pattern matching on file content |
| Require specific tags on resources | ✅ | Metadata compliance |
| Validate instance types are valid | ❌ | Use tflint (provider-aware) |
| Check HCL syntax | ❌ | Use `tofu validate` |
| Test module creates correct resources | ❌ | Use Terratest or `tofu test` |

## How OPA Fits in the Pipeline

```
Code Push → tofu plan → tofu show -json → OPA eval → Pass/Fail → tofu apply
                                              ↑
                                     policies/*.rego
```

### Enforcement Points

| Point | What's Evaluated | Example |
|-------|-----------------|---------|
| **PR time** | Policy logic tests | `opa test policies/ -v` |
| **Pre-plan** | Source code scanning | Secret detection in `.tf` files |
| **Post-plan** | Plan JSON | Encryption, tagging, Multi-AZ compliance |
| **Pre-apply** | Deployment approval | Staging/production gating |
| **Post-apply** | State file | Drift detection (optional) |

## How We Apply It

### Policy 1: Deployment Approval Gates

**When**: Before `tofu apply` on staging/production  
**Input**: Deployment metadata (environment, approver, status)  
**Action**: Block or allow deployment

```rego
package deployment.approval

default allow := false

# No approval needed for dev/test
allow if { input.environment in ["dev", "test", "perf"] }

# Staging/production require authorized approver
allow if {
    input.environment in ["staging", "production"]
    input.approval_status == "approved"
    input.approver in data.authorized_approvers[input.environment]
}
```

### Policy 2: Secret Scanning

**When**: Every PR (pre-merge)  
**Input**: File contents from repository  
**Action**: Block merge if credentials detected

```rego
package security.secrets

violation[{"msg": msg, "file": file_path}] if {
    file := input.files[_]
    regex.match(`AKIA[0-9A-Z]{16}`, file.content)
    msg := sprintf("AWS access key detected in %s", [file.path])
}
```

### Policy 3: Infrastructure Compliance

**When**: After `tofu plan`, before `tofu apply`  
**Input**: Plan JSON (`tofu show -json tfplan`)  
**Action**: Block apply if violations found

```rego
package terraform.compliance

# All databases must be encrypted
violation[{"msg": msg}] if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    msg := sprintf("%s: encryption required", [resource.address])
}
```

## Limitations of OPA with Terraform Plans

From the official OPA docs:

> Some information may not be available at plan time:
> - **Unknown values**: Computed attributes determined at apply time
> - **Dynamic blocks**: Configurations depending on runtime evaluation
> - **Function calls**: Results not yet evaluated

### What Plan JSON CAN Validate
- ✅ Resource types and names
- ✅ Explicitly set attributes (encryption, tags, instance_class)
- ✅ Resource counts and dependencies
- ✅ Provider configurations

### What Plan JSON CANNOT Validate
- ❌ Generated ARNs, IDs, endpoints
- ❌ Computed security group rules (from data sources)
- ❌ Dynamic block expansions from unknown values
- ❌ Actual runtime behavior

## Best Practices

1. **Test policies independently** — `opa test` with mock inputs
2. **Fail fast** — run OPA before apply, not after
3. **Version policies** — store in Git alongside infrastructure code
4. **Separate concerns** — one `.rego` file per policy domain
5. **Use data files** — externalize approver lists, tag requirements
6. **Gradual enforcement** — start with `warn`, move to `deny`
7. **Document violations** — include remediation in error messages

## Our Implementation

```
policies/opa/
├── deployment-approval.rego       # Approval gates
├── secret-scanning.rego           # Credential detection
├── terraform-compliance.rego      # Encryption, tagging, Multi-AZ
├── data.json                      # Authorized approvers
├── deployment-approval_test.rego  # 6 test cases
└── terraform-compliance_test.rego # 3 test cases
```

**Total**: 9 policy tests, 3 policy domains, all passing locally and in CI.

## OPA vs Alternatives

| Tool | Best For | Language |
|------|----------|----------|
| **OPA/Conftest** | Custom policies, Terraform plan validation | Rego |
| **Sentinel** | Terraform Cloud/Enterprise (HashiCorp native) | Sentinel |
| **Checkov** | Pre-built compliance checks (CIS, SOC2) | Python/YAML |
| **tfsec/Trivy** | Security scanning with built-in rules | Go |

**Our choice**: OPA — required by test spec, most flexible, works with any CI/CD.
