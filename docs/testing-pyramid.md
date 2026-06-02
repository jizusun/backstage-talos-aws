# Testing Pyramid — Backstage on Talos

```
              ▲
             / \
            / E2E \            ← AWS (real infra) — $50/month
           /  Tests \
          /───────────\
         /             \
        / Integration    \     ← Kind + OPA eval — $0
       /    Tests         \
      /─────────────────────\
     /                       \
    /     Unit Tests           \  ← tofu validate, opa test, helm lint — $0
   /        (Local)              \
  /───────────────────────────────\
```

---

## Layer 1: Unit Tests ($0, seconds)

**Run**: Every commit, every PR

| What | Tool | Tests |
|------|------|-------|
| OpenTofu syntax | `tofu validate` | Module structure, variable validation |
| OpenTofu formatting | `tofu fmt -check` | Code style consistency |
| OPA policies | `opa test` | Policy logic correctness |
| Helm charts | `helm lint` | Chart structure validity |
| Helm templates | `helm template --validate` | Rendered YAML correctness |

---

## Layer 2: Integration Tests ($0, minutes)

**Run**: Every PR, before merge

| What | Tool | Tests |
|------|------|-------|
| OPA compliance | `opa eval` on sample plan JSON | Policies catch violations |
| OPA approval logic | `opa eval` with test inputs | Approval gates work correctly |
| Backstage on Kind | `kind` + `helm install` | App deploys, health checks pass |

> **Note**: `tofu plan` requires real AWS APIs for data sources (availability zones, AMIs).
> Full plan validation happens in Layer 3 (E2E) with real AWS credentials.

---

## Layer 3: End-to-End Tests ($50/month, ~30 min)

**Run**: Weekly or before release

| What | Tool | Tests |
|------|------|-------|
| Full tofu plan | `tofu plan` (real AWS) | Resource graph validated |
| Full tofu apply | `tofu apply` (real AWS) | Cluster bootstraps correctly |
| IRSA | Pod → STS → AWS service | Credentials flow works |
| NLB + ingress | `curl https://backstage.dev` | Traffic reaches Backstage |
| RDS connectivity | Backstage → PostgreSQL | Database connection works |
| Talos upgrades | `talosctl upgrade` | Rolling update succeeds |

---

## Cost Efficiency

| Layer | Issues Caught | Cost | Speed |
|-------|--------------|------|-------|
| Unit | 70% | $0 | Seconds |
| Integration | 20% | $0 | Minutes |
| E2E | 10% | $50/month | 30 min |

**90% of issues caught at $0 cost.**

---

## Running Locally

```bash
# Layer 1: Unit tests
mise run validate

# Layer 2: Integration tests
mise run test-integration   # Kind + Backstage deploy
```
