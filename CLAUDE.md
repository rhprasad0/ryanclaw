# RyanClaw

Slack-first autonomous AI agent, inspired by OpenClaw. Python codebase.

## Key files

- `.specify/memory/constitution.md` — architectural principles (v2.2: Slack full workflow surface; Claude runs YOLO except for AWS mutations, which require operator confirmation; hybrid home-server + AWS runtime with RyanClaw as a least-privilege `ryanclaw_*`-schema tenant of the shared RDS; three monitoring paths, with Lambda-hosted MCPs intentionally outside path 3). Authoritative source for scope and constraints.
- `agentic-hub.manifest.yaml` — Slack app manifest. Scopes grow per feature plan; currently `incoming-webhook`-only but expansion is expected.

## Conventions

- **Formatting**: ruff + black
- **Linting**: ruff
- **Testing**: pytest
- **Type hints**: Expected on all function signatures
