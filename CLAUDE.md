# RyanClaw

Slack-first autonomous AI agent, inspired by OpenClaw. Python codebase.

## Key files

- `.specify/memory/constitution.md` — architectural principles (v2.4: Slack full workflow surface; Claude runs YOLO except for AWS mutations, which require operator confirmation; hybrid home-server + AWS runtime with RyanClaw as a least-privilege `ryanclaw_*`-schema tenant of the shared RDS; two monitoring paths — Healthchecks heartbeat and synthetic Slack delivery via post-and-confirm-200). Authoritative source for scope and constraints.
- `agentic-hub.manifest.yaml` — Slack app manifest. Scopes grow per feature plan; currently `incoming-webhook`-only but expansion is expected.

## Conventions

- **Formatting**: ruff + black
- **Linting**: ruff
- **Testing**: pytest
- **Type hints**: Expected on all function signatures

## Cron management

Multiple system crons live in this repo; additions must not clobber siblings.

- **Never** `crontab <file>` or `echo ... | crontab -` — both replace the entire user crontab.
- Safe scripted append: `(crontab -l 2>/dev/null; echo "NEW LINE") | crontab -`.
- Prefer `/etc/cron.d/<name>` drop-in files where possible — each file is independent.
- Always run `crontab -l` first to confirm existing state before mutating.

## Public repository

This repo is public. Before staging or committing, flag anything that could compromise security: secrets, API keys, credentials, webhook URLs, Slack tokens, AWS account IDs, RDS endpoints or connection strings, internal hostnames/IPs, or infra details that shouldn't be disclosed. When in doubt, stop and ask before committing.
