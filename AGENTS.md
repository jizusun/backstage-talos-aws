# AGENTS.md

## Tool Management

This project uses [mise](https://mise.jdx.dev) as the single tool manager, task runner, and environment configuration.

### Rules

1. **Call tools directly** (tofu, helm, opa, etc.) — mise activates them via shell integration or file tasks. Use `mise exec --` if shell integration is not activated.
2. **Always use `mise run <task>`** to run project tasks instead of raw shell scripts. `mise <task>` is a shorthand for `mise run <task>`. Use `mise tasks` to list available tasks.
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
mise run test:ut    # Layer 1: Terratest module validation
mise run test:it    # Layer 2: Kind + OPA + secret scan (depends on lint + test:ut)
mise run test:apply # Layer 2: kumo apply/destroy
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

### Terratest vs `tofu test`

- **`tofu test`** for logic assertions (variable validation, conditional resources, planned values)
- **Terratest** for structural validation (init/validate) and future apply/destroy integration tests
- Do **not** duplicate logic tests in Terratest — use `tofu test` with `mock_provider` instead
- Terratest needs AWS only for apply/destroy tests; our current tests run without credentials

## CI/CD

### GitHub Actions

- `pr-validation.yml` is the only workflow that runs on PRs
- `infrastructure.yml` and `application.yml` only trigger on push to `main`
- Use `jdx/mise-action@v2` — `mise.toml` is the single source of truth for tool versions
- If a tool fails to install in CI, exclude it from `mise.toml` and add to a CI-only override

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
│   └── versions.tf           # Provider requirements + backend
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

## Guidance for Future Work

### Before Adding Dependencies

- Check if the tool is available via `mise registry | grep <tool>` before manual install
- Verify download URLs still exist — upstream projects remove old releases (e.g., helm 3.16.3 was removed)
- Pin exact versions, never use `latest` in `mise.toml`
- Run `mise lock` after any change — the lockfile ensures reproducibility across platforms

### Before Adding AWS Emulators

- `tofu validate` and `tofu plan -backend=false` work **offline** — no emulator needed for syntax/structure
- `tofu test` with `mock_provider` covers logic assertions without any AWS endpoint
- AWS emulators (kumo, moto, etc.) are only useful for **apply/destroy cycle testing**
- Most emulators don't support all services — verify your module's APIs are covered before investing time
- Real AWS ($50/month dev cluster) gives 100% confidence — often cheaper than debugging emulator gaps

### When Writing CI Workflows

- Always validate locally first (`mise run lint && mise run test:it`) before pushing to see CI results
- `mise-action` installs **all** tools in `mise.toml` — if one fails, the whole step fails
- Check actual CI error logs before assuming which tool caused the failure
- Commit chart dependencies and lock files — don't rely on network fetches during CI
- Use `concurrency` groups to cancel stale runs on the same branch

### When Debugging CI Failures

- Use `gh run view <id> --log` to get full logs locally
- Search for the actual error: `grep -i "error\|fail" | grep -v "set-failed"`
- Common causes: version 404 (upstream removed), network timeout, missing secrets
- If `mise-action` fails: check which specific tool install errored, not just "mise failed"

### When Writing Tests

- Every policy file needs a `_test.rego` — untested policies are untrustworthy
- OPA tests must cover both **allow** and **deny** cases
- Prefer `tofu test` over Terratest for logic — it's faster and native
- Use Bun's `$` API carefully with pipes — write to files instead of piping stdin in Bun shell
- Integration tests should be idempotent — clean up Kind clusters, kill background processes
