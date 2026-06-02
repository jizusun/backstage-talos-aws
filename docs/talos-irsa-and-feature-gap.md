# Talos on AWS: IRSA & Feature Gap Analysis

## Pod Identity vs IRSA

Both solve the same problem: give pods AWS permissions without static credentials.

| | **IRSA** (2019) | **Pod Identity** (2023) |
|--|-----------------|-------------------------|
| **How it works** | OIDC token → STS → temp credentials | AWS agent on node → credentials injected |
| **Setup** | Create OIDC provider + IAM trust policy per role | Install agent + one API call |
| **Trust policy** | Unique per cluster (contains OIDC URL) | Universal (reusable across clusters) |
| **Portability** | ✅ Works on any K8s (including Talos) | ❌ EKS only |
| **Complexity** | Higher (OIDC provider, thumbprints) | Lower (no OIDC management) |
| **Session tags** | Manual | Automatic |

**For Talos**: Only IRSA is available. Pod Identity requires EKS-specific agent.

---

## How IRSA Works on Talos

### The Flow

```
Pod starts
  → K8s API server signs JWT token (projected volume)
    → AWS SDK reads token file
      → Calls STS AssumeRoleWithWebIdentity
        → STS fetches public keys from your OIDC endpoint
          → Verifies JWT signature
            → Returns temporary credentials
              → Pod accesses AWS services
```

### What STS Verifies

1. **Signature**: JWT signed by key matching public JWKS?
2. **Issuer (`iss`)**: Matches registered OIDC provider URL?
3. **Audience (`aud`)**: Contains `sts.amazonaws.com`?
4. **Subject (`sub`)**: Matches IAM trust policy condition? (e.g., `system:serviceaccount:backstage:backstage-sa`)
5. **Expiry (`exp`)**: Token not expired?

### What Gets Injected into the Pod

```yaml
env:
  - name: AWS_ROLE_ARN
    value: "arn:aws:iam::123456789:role/backstage-role"
  - name: AWS_WEB_IDENTITY_TOKEN_FILE
    value: "/var/run/secrets/eks.amazonaws.com/serviceaccount/token"

volumes:
  - name: aws-iam-token
    projected:
      sources:
        - serviceAccountToken:
            audience: sts.amazonaws.com
            expirationSeconds: 3600
            path: token
```

The AWS SDK detects these env vars automatically — no code changes needed.

---

## Setting Up IRSA on Talos

### Step 1: Configure Talos API Server

```yaml
# Talos machine config patch
cluster:
  apiServer:
    extraArgs:
      service-account-issuer: "https://s3.us-east-1.amazonaws.com/my-cluster-oidc"
      service-account-key-file: "/etc/kubernetes/pki/sa.pub"
      service-account-signing-key-file: "/etc/kubernetes/pki/sa.key"
```

### Step 2: Host OIDC Discovery on S3

```bash
# Upload two files to a public S3 bucket:

# 1. Discovery document
aws s3 cp openid-configuration s3://my-cluster-oidc/.well-known/openid-configuration

# 2. Public signing keys
kubectl get --raw /openid/v1/jwks > jwks.json
aws s3 cp jwks.json s3://my-cluster-oidc/openid/v1/jwks
```

**Discovery document** (`.well-known/openid-configuration`):
```json
{
  "issuer": "https://s3.us-east-1.amazonaws.com/my-cluster-oidc",
  "jwks_uri": "https://s3.us-east-1.amazonaws.com/my-cluster-oidc/openid/v1/jwks",
  "response_types_supported": ["id_token"],
  "subject_types_supported": ["public"],
  "id_token_signing_alg_values_supported": ["RS256"]
}
```

### Step 3: Register OIDC Provider in AWS IAM

```hcl
resource "aws_iam_openid_connect_provider" "talos" {
  url             = "https://s3.us-east-1.amazonaws.com/my-cluster-oidc"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
}
```

### Step 4: Create IAM Role with Trust Policy

```hcl
resource "aws_iam_role" "backstage" {
  name = "backstage-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.talos.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.talos.url, "https://", "")}:sub" = "system:serviceaccount:backstage:backstage-sa"
          "${replace(aws_iam_openid_connect_provider.talos.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
```

### Step 5: Install Pod Identity Webhook

```bash
# This webhook mutates pods to inject token volumes + env vars
# Works on ANY Kubernetes, not just EKS
helm install pod-identity-webhook \
  --set config.defaultAudience=sts.amazonaws.com \
  ./charts/amazon-eks-pod-identity-webhook
```

### Step 6: Annotate ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage-sa
  namespace: backstage
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789:role/backstage-role"
```

---

## EKS vs Talos Feature Gap

### Features Lost with Talos

| Feature | EKS | Talos | Impact |
|---------|-----|-------|--------|
| **Managed Control Plane** | AWS manages | Self-managed | You handle upgrades |
| **Pod Identity** | Native | Not available | Use IRSA instead |
| **Fargate** | Serverless pods | Not available | Must manage nodes |
| **Managed Node Groups** | AWS manages ASG | Self-managed | More Terraform |
| **EKS Add-ons** | 1-click install | Manual Helm | Use Cilium + Helm |
| **EKS Auto Mode** | Built-in Karpenter | Install yourself | Extra setup |
| **Console Integration** | Full visibility | None | Use kubectl/Grafana |
| **CloudWatch Insights** | Native | Manual Prometheus | More flexible |
| **AWS Support** | Enterprise K8s support | Community only | No escalation |

### Features Gained with Talos

| Feature | Benefit |
|---------|---------|
| **Immutable OS** | No drift, no shell access |
| **No Control Plane Fee** | $0 vs $72/month per cluster |
| **No Forced Upgrades** | Upgrade on your schedule |
| **No Vendor Lock-in** | Portable to any cloud |
| **Faster Boot** | ~2 min vs ~10+ min |
| **Smaller Attack Surface** | No systemd, no package manager |
| **Full etcd Access** | Direct backup/restore |
| **Cilium Native** | eBPF networking built-in |

### Features That Work the Same

| Feature | Notes |
|---------|-------|
| **IRSA** | Works with manual OIDC setup |
| **EBS CSI Driver** | Install via Helm |
| **Cluster Autoscaler** | Works with ASGs |
| **ALB/NLB** | AWS LB Controller works |
| **S3, RDS, ElastiCache** | All AWS services accessible |
| **Helm/kubectl** | Standard K8s API |

### Impact on Backstage Project

| Gap | Workaround | Effort |
|-----|------------|--------|
| No Pod Identity | IRSA (this document) | Medium |
| No Managed Nodes | ASG via Terraform module | Low |
| No EKS Add-ons | Helm install Cilium, EBS CSI | Low |
| No Console | Grafana + Hubble dashboards | Low |
| No AWS Support | Siderolabs community + docs | Acceptable |

---

## Summary

**Extra work for IRSA on Talos vs EKS**:
1. Host 2 JSON files on S3 (OIDC discovery + JWKS)
2. Register OIDC provider in IAM
3. Install pod-identity-webhook

**Total extra effort**: ~1 hour of Terraform + Helm setup.  
**Result**: Same pod-level IAM permissions as EKS, fully automated via Terraform.
