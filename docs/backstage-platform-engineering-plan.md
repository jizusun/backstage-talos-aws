# Backstage Platform Engineering — Implementation Plan

## Executive Summary

Deploy Spotify's Backstage developer portal on **Talos Kubernetes** across 5 AWS environments, demonstrating senior platform engineering through infrastructure automation, CI/CD pipelines, and policy enforcement.

**Key Decisions**:
- **Kubernetes**: Talos Linux (immutable, API-only, $360/month savings vs EKS)
- **CI/CD**: GitHub Actions (primary) + Harness (optional)
- **Policy**: Open Policy Agent for governance automation
- **Local Testing**: Kind + OpenTofu plan for zero-cost development

---

## Architecture Overview

```
Users → NLB → Talos Kubernetes Cluster → RDS PostgreSQL
                    │                         │
                    ├── Backstage Pods         ├── ElastiCache Redis
                    ├── Cilium CNI (eBPF)     ├── S3 (Assets)
                    └── Monitoring Stack       └── ECR (Images)
```

**Infrastructure Components** (Test Task 1):
- Networking: VPC + NLB
- Computing: Talos Kubernetes
- Data Store: RDS PostgreSQL + Redis + S3
- Container Registry: ECR

---

## Environment Strategy

| Environment | Region | Sizing | Cost |
|-------------|--------|--------|------|
| **dev** | us-east-1 | 1 CP + 1 Worker (spot) | ~$50/mo |
| **test** | us-east-1 | 3 CP + 2 Workers | ~$150/mo |
| **perf** | us-east-1 + us-west-2 | 3 CP + 3 Workers | ~$350/mo |
| **staging** | us-east-1 + us-west-2 | 3 CP + 2 Workers | ~$300/mo |
| **production** | us-east-1 + us-west-2 | 3 CP + 3 Workers | ~$500/mo |
| **Total** | | | **~$1,350/mo** |

Multi-region (active-passive) for perf, staging, and production as required.

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2) — Cost: $0
- Terraform module development (VPC, Talos, RDS, S3, ECR)
- Advanced Terraform: workspaces, remote state, module composition, Terratest
- Local validation with Kind (Backstage) + OpenTofu plan (infrastructure)
- Repository structure and Git workflow setup

### Phase 2: Security & Policy (Week 3) — Cost: $0
- OPA policy: approval gates for staging/production deployments
- OPA policy: secret scanning to prevent hardcoded credentials
- Infrastructure compliance policies (encryption, tagging)
- Pod security standards and network policies

### Phase 3: CI/CD Pipelines (Week 4) — Cost: $0
- **GitHub Actions** (primary):
  - Infrastructure pipeline: test → plan → approval → apply
  - Application pipeline: build → scan → test → deploy
  - Policy validation on every PR
- **Harness** (optional): equivalent pipeline demonstrating preferred stack

### Phase 4: AWS Deployment (Weeks 5-6) — Cost: $50 → $1,350
- Gradual rollout: dev → test → perf → staging → production
- Validate Talos + AWS integrations in dev first
- Multi-region deployment for upper environments
- Backstage application deployment and verification

### Phase 5: Operations & Documentation (Week 7) — Cost: included
- Monitoring: Prometheus + Grafana + Cilium Hubble + CloudWatch
- Documentation as code: architecture, infrastructure, pipeline diagrams
- Operational runbooks for Talos management and disaster recovery

---

## Test Requirements Mapping

| Test Task | Requirement | Solution |
|-----------|-------------|----------|
| **Task 0** | Multi-tier OSS project | Backstage (React → Node.js → PostgreSQL) |
| **Task 1** | Infrastructure as Code | Terraform + Talos + AWS (5 environments) |
| **Task 2.1** | Infra Pipeline | GitHub Actions: test → plan → approval → apply |
| **Task 2.2** | Service Pipeline | GitHub Actions: build → scan → deploy |
| **Task 3** | Policy as Code | OPA: deployment approvals + secret scanning |
| **Task 4** | Documentation | Architecture + infra + pipeline diagrams |

---

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Infrastructure** | Terraform | Required by test, advanced features demonstrated |
| **Kubernetes** | Talos Linux | Immutable OS, cost savings, security-first |
| **Networking** | Cilium (eBPF) | Built into Talos module, kube-proxy replacement |
| **CI/CD** | GitHub Actions + Harness | Free primary + preferred optional |
| **Policy** | Open Policy Agent | Required by test, enterprise governance |
| **Monitoring** | Prometheus + Grafana | Industry standard, Talos native support |
| **Local Dev** | Kind + OpenTofu plan | Zero-cost development and validation |

---

## Cost & Timeline

| Week | Phase | Cost |
|------|-------|------|
| 1-2 | Foundation & Terraform | $0 |
| 3 | Security & OPA | $0 |
| 4 | CI/CD Pipelines | $0 |
| 5 | AWS Dev Validation | $50 |
| 6 | Full Deployment | $1,350 |
| 7 | Operations & Docs | $1,350 |

**Total Duration**: 7 weeks  
**Development Cost**: $0 (weeks 1-4)  
**AWS Cost**: ~$2,750 total (weeks 5-7)  
**Monthly Ongoing**: ~$1,350/month (21% cheaper than EKS)

---

## Deliverables

- **Git Repository**: Terraform, Helm charts, pipelines, policies, documentation
- **Live Service**: Backstage portal accessible via public URL
- **Pipeline Execution**: GitHub Actions screenshots with approval workflows
- **Policy Enforcement**: OPA evaluation examples (pass/fail)
- **Architecture Diagrams**: Application, infrastructure, and pipeline designs
