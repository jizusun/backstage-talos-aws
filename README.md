# Terraform Harness Blueprint

A GitHub template for building **infrastructure test harnesses** around Terraform/OpenTofu projects. The emphasis is on engineering rigor — testing pyramid, policy-as-code, CI/CD validation gates — not the infrastructure itself.

Backstage on Talos Linux (AWS) is included as an **example implementation** to demonstrate the harness patterns in a realistic context.

## What This Template Provides

```text
      E2E (AWS)           ← Real infra, expensive, weekly
    Integration           ← Kind + Terratest + OPA eval, $0, minutes
  Unit (lint/validate)    ← tofu + tflint + trivy + opa + helm, $0, seconds
```

95% of issues caught at $0 cost before touching a cloud provider.

### Harness Components

| Component | Purpose |
|-----------|---------|
| OpenTofu validate + tflint + trivy | Static analysis and security scanning |
| `tofu test` with mock_provider | Logic assertions without cloud credentials |
| Terratest (Go) | Structural validation, apply/destroy cycles |
| OPA/Rego policies + tests | Governance gates (approval, secrets, compliance) |
| Kind cluster + Helm lint | Kubernetes deployment validation |
| GitHub Actions pipelines | Automated validation on every PR |

### Policy Gates (OPA)

- **Deployment approval** — staging/production require authorized approver
- **Secret scanning** — blocks hardcoded credentials
- **Infrastructure compliance** — encryption, tagging, multi-AZ enforcement

### CI/CD Flow

```text
PR:            lint → unit test → integration test → policy check
dev/test/perf: push → validate → plan → apply (automatic)
staging/prod:  push → validate → plan → approval → apply (manual gate)
```

## Example Implementation

The included example deploys Backstage on Talos Linux across AWS environments:

```
Users → NLB → Talos Kubernetes (Cilium CNI)
                    ├── Backstage (React + Node.js)
                    ├── RDS PostgreSQL
                    ├── ElastiCache Redis
                    ├── S3 (Assets)
                    └── ECR (Images)
```

This exists to show the harness in action against real modules — swap it out with your own infrastructure.

## Quick Start

```bash
# Use this template on GitHub, then:
curl https://mise.run | sh
mise install

# Run the full harness locally
mise run lint        # Layer 1: static analysis
mise run test:ut     # Layer 1: module validation (no AWS needed)
mise run test:it     # Layer 2: Kind + OPA + Helm (no AWS needed)
mise run test:e2e    # Layer 3: real AWS (needs credentials)
```

## Project Structure

```
├── mise.toml                     # Tools, env vars, task runner
├── .mise/tasks/                  # Bun TypeScript task scripts
├── terraform/
│   ├── modules/                  # Reusable infrastructure modules
│   ├── environments/             # Per-environment tfvars
│   ├── test/                     # Terratest (Go)
│   └── versions.tf              # Provider requirements + backend
├── charts/backstage/             # Helm chart (example workload)
├── policies/opa/                 # Rego policies + tests + data
├── .github/workflows/            # CI/CD pipelines
│   ├── pr-validation.yml         # Runs full harness on PRs
│   ├── infrastructure.yml        # Deploy on push to main
│   └── application.yml           # App deploy on push to main
└── docs/                         # Architecture and design docs
```

## Testing Details

| Tool | Layer | What It Validates |
|------|-------|-------------------|
| `tofu validate` | 1 | HCL syntax, module structure |
| `tflint` | 1 | Provider-specific rules, deprecations |
| `trivy` | 1 | Security misconfigurations |
| `opa test` | 1 | Policy logic correctness |
| `helm lint/template` | 1 | Chart validity |
| Terratest (Go) | 1+ | Module init/validate in isolation |
| `tofu test` | 1+ | Module assertions with mock_provider |
| Kind + Helm dry-run | 2 | K8s deployment validity |
| OPA eval | 2 | Approval gates, secret scanning |
| `tofu apply` (AWS) | 3 | Real infrastructure creation |

## Adapting This Template

1. **Click "Use this template"** on GitHub
2. Replace `terraform/modules/` with your own infrastructure
3. Update `policies/opa/` with your governance rules
4. Adjust `charts/` for your workload (or remove if not using K8s)
5. Keep the harness structure — it works for any Terraform project

## Technology Choices

| Tool | Why |
|------|-----|
| OpenTofu | Open-source, BSL-free, same HCL as Terraform |
| mise | Single tool/env/task manager — reproducible everywhere |
| Bun | Fast TypeScript runtime for all task scripts |
| OPA/Rego | Flexible policy engine, testable, data-driven |
| Kind | Fast local K8s for integration tests |
| GitHub Actions | Free CI, native Git integration |

## Documentation

- [Testing Pyramid](docs/testing-pyramid.md)
- [Terratest Guide](docs/terratest.md)
- [OPA Guide](docs/opa.md)
- [Implementation Plan](docs/backstage-platform-engineering-plan.md)

## License

MIT
