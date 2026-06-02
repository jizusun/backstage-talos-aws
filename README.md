# Backstage Platform on Talos Kubernetes

Production-ready deployment of [Spotify Backstage](https://backstage.io) developer portal on [Talos Linux](https://www.talos.dev) Kubernetes across 5 AWS environments.

## Architecture

```
Users → NLB → Talos Kubernetes (Cilium CNI)
                    ├── Backstage (React + Node.js)
                    ├── RDS PostgreSQL
                    ├── ElastiCache Redis
                    ├── S3 (Assets)
                    └── ECR (Images)
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| OS/Compute | Talos Linux | Immutable, API-only Kubernetes |
| Networking | Cilium (eBPF) | Kube-proxy replacement, observability |
| IaC | OpenTofu | Infrastructure automation |
| CI/CD | GitHub Actions | Pipeline automation |
| Policy | Open Policy Agent | Governance and compliance |
| Tooling | mise | Tool/env/task management |

## Environments

| Environment | Region | Sizing | Cost |
|-------------|--------|--------|------|
| dev | us-east-1 | 1 CP + 1 Worker (spot) | ~$50/mo |
| test | us-east-1 | 3 CP + 2 Workers | ~$150/mo |
| perf | us-east-1 + us-west-2 | 3 CP + 3 Workers | ~$350/mo |
| staging | us-east-1 + us-west-2 | 3 CP + 2 Workers | ~$300/mo |
| production | us-east-1 + us-west-2 | 3 CP + 3 Workers | ~$500/mo |

## Quick Start

### Prerequisites

```bash
# Install mise (tool manager)
curl https://mise.run | sh

# Install all project tools
mise install
```

### Local Development

```bash
# Validate infrastructure code
mise run validate

# Deploy Backstage locally with Kind
mise run dev

# Access Backstage
kubectl port-forward svc/backstage 3000:3000
open http://localhost:3000
```

### Deploy to AWS

```bash
# Plan for dev environment
mise run plan dev

# Apply (via GitHub Actions or manually)
mise run test-e2e
```

## Project Structure

```
├── mise.toml                     # Tools, env vars, task runner
├── terraform/
│   ├── modules/
│   │   ├── vpc/                  # Multi-AZ VPC
│   │   ├── talos-cluster/        # Talos K8s cluster + NLB + IAM
│   │   ├── rds/                  # PostgreSQL (encrypted, Multi-AZ)
│   │   ├── elasticache/          # Redis (encrypted)
│   │   ├── s3/                   # Object storage (KMS, private)
│   │   └── ecr/                  # Container registry
│   ├── environments/             # Per-environment tfvars
│   ├── main.tf                   # Root module composition
│   └── versions.tf               # Provider requirements
├── charts/backstage/             # Helm chart
│   ├── templates/                # K8s manifests
│   └── values/                   # Per-environment values
├── .github/workflows/
│   ├── infrastructure.yml        # test → plan → approval → apply
│   ├── application.yml           # build → scan → deploy
│   └── policy-check.yml          # OPA validation on PRs
├── policies/opa/
│   ├── deployment-approval.rego  # Approval gates (staging/prod)
│   ├── secret-scanning.rego      # Credential detection
│   └── terraform-compliance.rego # Encryption, tagging, Multi-AZ
├── .mise/tasks/                  # Bun TypeScript task scripts
└── docs/                         # Architecture & design docs
```

## Available Tasks

```bash
mise run lint              # Lint and validate all code
mise run plan <env>        # Generate OpenTofu plan
mise run fmt               # Auto-format code
mise run test:ut           # Terratest module validation
mise run test:it           # Integration tests (Kind + OPA)
mise run test:e2e          # Deploy to real AWS
mise run dev               # Full local dev environment
mise run clean             # Remove local clusters
```

## Testing Pyramid

```
        E2E (AWS)           ← $50/month, weekly
      Apply/Destroy         ← FakeCloud, free
    Integration (Kind)      ← Local, free
  Unit (validate/lint/opa)  ← Local, free
```

95% of issues caught at $0 cost before touching AWS.

## Security & Policy

### OPA Policies Enforced
1. **Deployment Approval** — staging/production require authorized approver
2. **Secret Scanning** — blocks hardcoded credentials in PRs
3. **Infrastructure Compliance** — encryption, tagging, Multi-AZ for production

### Infrastructure Security
- Talos: No SSH, no shell, API-only access
- RDS: Encrypted at rest, private subnets only
- Redis: Encryption at rest + in transit
- S3: KMS encryption, public access blocked
- ECR: Immutable tags, scan on push

## CI/CD Pipelines

### Infrastructure Pipeline
```
Push to terraform/ → Validate → Plan → OPA Check → [Approval] → Apply
```

### Application Pipeline
```
Push to charts/ → Build Image → Trivy Scan → Secret Scan → Helm Deploy
```

### Policy Pipeline
```
Any PR → OPA Test → Deployment Logic Check → Secret Scan
```

## Documentation

- [Implementation Plan](docs/backstage-platform-engineering-plan.md)
- [Testing Pyramid](docs/testing-pyramid.md)
- [Talos IRSA & Feature Gap](docs/talos-irsa-and-feature-gap.md)
- [Talos vs EKS Cost](docs/talos-vs-eks-cost.md)
- [Talos Deep Dive](docs/talos-terraform-deep-dive.md)
- [Terratest Guide](docs/terratest.md)
- [OPA Guide](docs/opa.md)

## License

MIT
