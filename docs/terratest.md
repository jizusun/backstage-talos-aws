# Terratest — When & How to Apply

## What is Terratest?

Go-based testing framework for infrastructure code. Validates that Terraform modules behave correctly by running real commands (`init`, `plan`, `apply`, `destroy`).

## When to Use Terratest

| Scenario | Use Terratest? | Why |
|----------|---------------|-----|
| Validate module syntax/structure | ✅ | `Init` + `Validate` per module without AWS |
| Test variable validation | ✅ | Pass bad inputs, assert errors |
| Verify plan output (resource counts) | ✅ | `InitAndPlan` + inspect plan struct |
| Full apply/destroy integration test | ✅ | Real cloud resources, verify connectivity |
| Quick syntax check in CI | ❌ | Use `tofu validate` instead (faster) |
| Policy compliance | ❌ | Use OPA instead (declarative) |
| Security scanning | ❌ | Use Trivy/tflint instead |

## How We Apply It

### Level 1: Module Validation (No AWS, fast)

```go
// Validates module can initialize and passes syntax checks
func TestVPCModuleValidation(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir:    "../modules/vpc",
        TerraformBinary: "tofu",
    }
    terraform.Init(t, opts)
    terraform.Validate(t, opts)
}
```

**When**: Every PR, every commit  
**Cost**: $0  
**Time**: ~15 seconds per module

### Level 2: Plan Inspection (No AWS, medium)

```go
// Validates plan creates expected resources
func TestVPCPlanCreatesSubnets(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir:    "../modules/vpc",
        TerraformBinary: "tofu",
        Vars: map[string]interface{}{
            "cluster_name": "test",
            "az_count":     2,
        },
        PlanFilePath: "./plan.out",
    }
    plan := terraform.InitAndPlanAndShowWithStruct(t, opts)
    assert.Equal(t, 2, plan.ResourceChanges["aws_subnet.public"].Count)
}
```

**When**: Before merging to main  
**Cost**: $0 (plan only, no real resources)  
**Time**: ~30 seconds

### Level 3: Apply/Destroy Integration (Needs AWS)

```go
// Creates real resources, validates, then destroys
func TestVPCCreatesInAWS(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir:    "../modules/vpc",
        TerraformBinary: "tofu",
        Vars: map[string]interface{}{
            "cluster_name": "terratest-vpc",
            "environment":  "dev",
        },
    }
    defer terraform.Destroy(t, opts)
    terraform.InitAndApply(t, opts)

    vpcId := terraform.Output(t, opts, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

**When**: Weekly, before releases  
**Cost**: AWS charges during test (minutes)  
**Time**: 3-10 minutes

## Best Practices

1. **Run tests in parallel** — `t.Parallel()` reduces total time
2. **Always `defer Destroy`** — prevents orphaned resources
3. **Use unique names** — avoid conflicts between parallel tests
4. **Separate unit from integration** — tag with build constraints
5. **Set timeouts** — prevent hanging tests: `-timeout 30m`
6. **Use plan-only for CI** — reserve apply/destroy for nightly runs

## Our Implementation

```
terraform/test/
└── modules_test.go    # 6 tests: Init+Validate per module
```

All tests run without AWS credentials (Level 1 only). Level 2-3 tests added when AWS access is available.

## Limitations

- **Cannot test data sources** — `aws_availability_zones` needs real API
- **Slow for apply tests** — 3-10 min per module
- **Requires Go** — team needs Go knowledge
- **State conflicts** — parallel apply tests need unique naming
