# Testing Pyramid — Backstage on Talos

```
              ▲
             / \
            / E2E \            ← Real AWS Talos cluster — $50/month
           /  Tests \
          /───────────\
         /             \
        / Integration    \     ← kumo apply/destroy + Kind + OPA eval — $0
       /    Tests         \
      /─────────────────────\
     /                       \
    /     Unit Tests           \  ← tofu validate, tflint, trivy, opa test, helm lint — $0
   /                             \
  /─────────────────────────────────\
```

---

## Unit Tests ($0, seconds)

**Run**: Every commit, every PR  
**Task**: `mise run lint` + `mise run test:unit`

| What             | Tool                          | Validates                                |
|------------------|-------------------------------|------------------------------------------|
| Syntax & schema  | `tofu validate`               | HCL correctness                          |
| Formatting       | `tofu fmt -check`             | Code style                               |
| Provider rules   | `tflint`                      | AWS deprecations, invalid types          |
| Security         | `trivy config`                | Misconfigurations                        |
| Policy logic     | `opa test`                    | 14 tests (approval, secrets, compliance) |
| Chart validity   | `helm lint` + `helm template` | K8s manifests                            |
| Module structure | Terratest `Init` + `Validate` | 6 modules                                |
| Module logic     | `tofu test` + `mock_provider` | 7 assertions (RDS, S3, ECR)              |

---

## Integration Tests ($0, minutes)

**Run**: Every PR, before merge  
**Task**: `mise run test:integration` + `mise run test:apply`

| What                | Tool                | Validates                            |
|---------------------|---------------------|--------------------------------------|
| Apply/destroy cycle | kumo + Terratest    | S3 module creates/destroys correctly |
| K8s deployment      | Kind + Helm dry-run | Backstage chart deploys to cluster   |
| Approval gates      | OPA eval            | Production blocked, dev allowed      |
| Secret scanning     | OPA eval + bun scan | No credentials in codebase           |

---

## E2E Tests ($50/month, 30 min)

**Run**: Weekly or before release  
**Task**: `mise run test:e2e`

| What               | Tool                    | Validates                 |
|--------------------|-------------------------|---------------------------|
| Full Talos cluster | `tofu apply` (real AWS) | Cluster bootstraps        |
| IRSA               | Pod → STS → AWS         | Credentials flow          |
| NLB + networking   | `curl`                  | Traffic reaches Backstage |
| RDS connectivity   | Backstage → PostgreSQL  | Database works            |
| Talos operations   | `talosctl upgrade`      | Rolling update            |

---

## Running Tests

```bash
mise run lint          # Unit: static analysis
mise run test:unit       # Unit: Terratest module validation
mise run test:integration       # Integration: Kind, OPA eval, secret scan
mise run test:apply    # Integration: kumo apply/destroy
mise run test:e2e      # E2E: real AWS (needs credentials)
```

---

## Cost Efficiency

| Layer       | Issues Caught | Cost      | Speed   |
|-------------|---------------|-----------|---------|
| Unit        | 70%           | $0        | Seconds |
| Integration | 25%           | $0        | Minutes |
| E2E         | 5%            | $50/month | 30 min  |

**95% of issues caught at $0 cost.**
