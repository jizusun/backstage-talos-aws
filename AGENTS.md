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
