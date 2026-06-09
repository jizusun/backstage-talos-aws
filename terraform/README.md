# Terraform Infrastructure

Example implementation deploying Backstage on Talos Linux (AWS) to demonstrate the harness patterns.

## Architecture

```
Users → NLB → Talos Kubernetes (Cilium CNI)
                    ├── Backstage (React + Node.js)
                    ├── RDS PostgreSQL
                    ├── ElastiCache Redis
                    ├── S3 (Assets)
                    └── ECR (Images)
```

## Modules

| Module | Source | Purpose |
|--------|--------|---------|
| vpc | `terraform-aws-modules/vpc/aws` | VPC with public/private subnets |
| talos | `isovalent/terraform-aws-talos` | Talos K8s cluster with Cilium, CCM, metrics-server |
| rds | local | PostgreSQL with IAM auth, SSL, enhanced monitoring |
| elasticache | local | Redis with auth token, KMS encryption, multi-AZ failover |
| s3 | local | Assets bucket with lifecycle, logging, KMS encryption |
| ecr | local | Container registry with KMS encryption, lifecycle policy |

## Usage

```bash
# Initialize (use -backend=false for local development)
tofu init -backend=false

# Validate
tofu validate

# Plan for an environment
tofu plan -var-file=environments/dev.tfvars -var="db_password=changeme"

# Apply
tofu apply -var-file=environments/dev.tfvars -var="db_password=changeme"
```

## Environments

| Environment | File | Auto-deploy |
|-------------|------|-------------|
| dev | `environments/dev.tfvars` | yes |
| test | `environments/test.tfvars` | yes |
| perf | `environments/perf.tfvars` | yes |
| staging | `environments/staging.tfvars` | manual approval |
| production | `environments/production.tfvars` | manual approval |

## Testing

```bash
# Unit tests (no AWS credentials needed)
cd test && go test -v -timeout 5m

# Apply/destroy with kumo emulator
KUMO=1 go test -v -run TestS3ApplyDestroy -timeout 5m
```

## Structure

```
├── main.tf              # Root composition (all modules wired together)
├── variables.tf         # Input variables with validation
├── outputs.tf           # Cluster, DB, and registry outputs
├── versions.tf          # Provider requirements + S3 backend
├── providers.tf         # AWS provider with default tags
├── environments/        # Per-environment variable values
├── modules/
│   ├── vpc/             # Networking
│   ├── rds/             # Database
│   ├── elasticache/     # Cache
│   ├── s3/              # Object storage
│   └── ecr/             # Container registry
└── test/
    ├── modules_test.go  # Terratest: init + validate each module
    ├── apply_test.go    # Terratest: S3 apply/destroy via kumo
    └── fixtures/s3/     # Test fixture for apply/destroy
```
