# AGENTS.md

## Tool Management

This project uses [mise](https://mise.jdx.dev) as the single tool manager, task runner, and environment configuration.

### Rules

1. **Always use `mise exec --` to run any tool** — never call binaries directly
2. **Always use `mise run <task>`** to run project tasks — never raw shell scripts
3. **Never install tools globally** — all tools are managed via `mise.toml`
4. **Add new tools to `mise.toml`** using `mise use <tool>@<version> --pin`
5. **Use `[env]` section in `mise.toml`** for environment variables, not `.env` files
6. **Run `mise lock`** after adding or updating tools — always commit `mise.lock`

## Code Conventions

### Infrastructure (OpenTofu/Terraform)

- Use **OpenTofu** (`tofu` CLI), not Terraform — but keep HCL compatible with both
- One module per infrastructure concern (vpc, rds, ecr, etc.)
- Every module must have `variables.tf`, `outputs.tf`, and `main.tf`
- Use variable validation blocks for user-facing inputs
- Root module composes child modules — never put resources directly in root
- Use workspaces for environment separation, `environments/*.tfvars` for config
- Backend is S3 with native state locking — always use `-backend=false` for local testing

### Tasks (Bun TypeScript)

- All tasks live in `.mise/tasks/` as executable Bun TypeScript files
- Use `#!/usr/bin/env bun` shebang and `//MISE` directives for metadata
- Use Bun's `$` shell API (`import { $ } from "bun"`) for command execution
- No bash scripts, no Python scripts — Bun is the single scripting runtime
- Task names: short, lowercase, colon-separated for grouping (`test:ut`, `test:it`)

### Policies (OPA/Rego)

- One `.rego` file per policy domain
- Every policy must have a corresponding `_test.rego` file
- Use `import future.keywords.if` and `import future.keywords.in`
- Tests must cover both allow and deny cases
- Externalize data (approvers, thresholds) into `data.json`

### Helm Charts

- Commit chart dependencies (`charts/` directory) — don't rely on `helm dep build` in CI
- Environment-specific values in `charts/<name>/values/<env>.yaml`
- Use `local.yaml` for Kind development

## Testing

### Testing Pyramid

```
      E2E (AWS)           ← Real infra, $50/month, weekly
    Integration           ← Kind + Terratest + OPA eval, $0, minutes
  Unit (lint/validate)    ← tofu + tflint + trivy + opa + helm, $0, seconds
```

### Running Tests

```bash
mise run lint       # Layer 1: static analysis
mise run test:ut    # Layer 1+: Terratest module validation
mise run test:it    # Layer 2: Kind + OPA + secret scan (depends on lint + test:ut)
mise run test:e2e   # Layer 3: real AWS (needs credentials)
```

### What Gets Tested Where

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

## CI/CD

### GitHub Actions

- `pr-validation.yml` is the only workflow that runs on PRs
- `infrastructure.yml` and `application.yml` only trigger on push to `main`
- Do **not** use `jdx/mise-action` — install tools directly with setup actions (opentofu, bun, helm, go)
- Reason: mise-action fails installing some tools (talosctl) in CI runners

### Deployment Flow

```
dev/test/perf: push → validate → plan → apply (automatic)
staging/prod:  push → validate → plan → approval → apply (manual gate)
```

## Project Structure

```
.
├── mise.toml                  # Tools + env vars (no inline tasks)
├── .mise/tasks/               # All tasks as Bun TypeScript files
├── terraform/
│   ├── modules/               # Reusable infrastructure modules
│   ├── environments/          # Per-environment tfvars
│   ├── test/                  # Terratest (Go)
│   └── versions.tf            # Provider requirements + backend
├── charts/backstage/          # Helm chart + committed dependencies
├── policies/opa/              # Rego policies + tests + data
├── .github/workflows/         # CI/CD pipelines
└── docs/                      # Architecture and design documentation
```

## Key Decisions (Context)

- **Talos Linux** over EKS: immutable OS, $360/month savings, API-only operations
- **OpenTofu** over Terraform: open-source, BSL-free, same HCL syntax
- **Bun** over bash/python/node: single fast runtime for all scripting
- **OPA** over Sentinel/Checkov: required by test spec, most flexible
- **GitHub Actions** over Harness: free, native Git integration; Harness is optional addon
- **Kind** for local testing: fast, lightweight, sufficient for Helm validation
- **No FakeCloud/LocalStack**: doesn't support EC2/VPC APIs needed for our modules
