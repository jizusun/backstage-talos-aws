# Testing Pyramid

```
            /\
           /  \
          / E2E\             Terratest · real AWS · $50/month
         /______\
        /        \
       /Integration\         tofu test + kumo · Kind + OPA · $0
      /______________\
     /                \
    /   Unit Tests     \     tofu test (mock_provider) · opa test · $0
   /____________________\
  ══════════════════════════
  │   Static Analysis     │  tofu validate · tflint · trivy · checkov · $0
  ══════════════════════════
```

> Static analysis is the **foundation** below the pyramid — it validates code correctness but doesn't test behavior.

---

## Static Analysis ($0, seconds)

**Not testing** — validates code correctness without executing logic.

**Run**: Every commit (pre-commit hook)
**Task**: `mise run lint`

| What | Tool | Validates |
|------|------|-----------|
| Syntax & schema | `tofu validate` | HCL correctness, module structure |
| Formatting | `tofu fmt -check` | Code style |
| Provider rules | `tflint` | AWS deprecations, invalid types |
| Security misconfig | `trivy config` | CIS benchmarks (Terraform) |
| Security misconfig | `checkov` | Best practices, compliance |
| Chart validity | `helm lint` + `helm template` | K8s manifests |
| Workflow validity | `actionlint` | GitHub Actions syntax |
| Secrets | `gitleaks` | Leaked credentials |

---

## Unit Tests ($0, seconds)

**Tests logic** — asserts that code produces correct behavior with mock inputs.

**Run**: Every commit, every PR
**Task**: `mise run test:unit`

| What | Tool | Validates |
|------|------|-----------|
| Module logic | `tofu test` + `mock_provider` | ElastiCache, S3 plan assertions |
| Policy logic | `opa test` | 14 tests (approval, secrets, compliance) |

---

## Integration Tests ($0, minutes)

**Tests interactions** — verifies components work together against emulated services.

**Run**: Every PR, before merge
**Task**: `mise run test:integration` + `mise run test:apply`

| What | Tool | Validates |
|------|------|-----------|
| Apply/destroy cycle | `tofu test` + kumo | S3 module creates/destroys correctly |
| K8s deployment | Kind + Helm dry-run | Backstage chart deploys to cluster |
| Approval gates | OPA eval | Production blocked, dev allowed |
| Secret scanning | OPA eval + bun scan | No credentials in codebase |

---

## E2E Tests ($50/month, 30 min)

**Tests the real system** — deploys to AWS, verifies externally observable behavior.

**Run**: Weekly or before release
**Task**: `mise run test:e2e` (requires `E2E=1` + AWS credentials)

| What | Tool | Validates |
|------|------|-----------|
| Full stack deploy | Terratest `InitAndApply` | All modules create successfully |
| K8s API reachable | Terratest HTTP retry | NLB → cluster connectivity |
| Database endpoint | Terratest output check | RDS accessible from cluster |
| Clean teardown | Terratest `Destroy` | No orphaned resources |

---

## Running Tests

```bash
mise run lint               # Static analysis (not testing)
mise run test:unit          # Unit: tofu test (mock_provider) + opa test
mise run test:apply         # Integration: tofu test + kumo apply/destroy
mise run test:integration   # Integration: Kind, OPA eval, secret scan
mise run test:e2e           # E2E: real AWS (needs E2E=1 + credentials)
```

---

## Tool Selection

| Layer | `tofu test` | Terratest |
|-------|-------------|-----------|
| Unit (plan-level) | ✅ Primary — fast, native HCL | ❌ Overkill |
| Integration (emulator) | ✅ Apply/destroy with kumo | ❌ Unnecessary |
| E2E (real AWS) | ❌ Can't verify external behavior | ✅ HTTP calls, retries, SDK |

**Principle**: `tofu test` for "does my HCL produce the right plan?", Terratest for "does my deployed infra actually work?"

---

## Cost Efficiency

| Layer | Tool | Cost | Speed |
|-------|------|------|-------|
| Static analysis | Linters | $0 | Seconds |
| Unit | tofu test + opa test | $0 | Seconds |
| Integration | tofu test + kumo + Kind | $0 | Minutes |
| E2E | Terratest + real AWS | $50/month | 30 min |
