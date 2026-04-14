# RyanClaw

A Slack-first autonomous AI agent.

RyanClaw is an opinionated take on [OpenClaw](https://github.com/openclaw/openclaw) that goes all-in on Slack as the agentic OS. Instead of spreading across 20+ messaging platforms, RyanClaw treats Slack as the primary interface where agents coordinate, execute tasks, report status, and interact with users.

## Architecture

Architectural principles live in [`.specify/memory/constitution.md`](.specify/memory/constitution.md) (currently v2.4).

In short: Slack is a full two-way workflow surface — inbound paths, interactive components, and state mutation from Slack are all permitted. Claude (in Slack and in Claude Code) runs YOLO — autonomous execution is the default, with AWS mutations (Terraform apply, Lambda deploys, RDS writes, IAM, secret rotation) carved out and requiring operator confirmation. Runtime is hybrid: a home server running cron plus a narrow AWS surface (RDS shared with a separate jobs-pipeline repo as a least-privilege `ryanclaw_*`-schema tenant, Lambdas hosting MCP servers). Operational health is covered by two independent monitoring paths: a Healthchecks.io heartbeat from the home server and a synthetic Slack-delivery check that posts to `#sandbox` and confirms the Agentic Hub webhook returned 200/ok.

### Slack app

The **Agentic Hub** app is defined in [`agentic-hub.manifest.yaml`](agentic-hub.manifest.yaml). The initial manifest scopes only `incoming-webhook`; scopes will grow as features add inbound paths (socket mode, event subscriptions, interactive components, slash commands).

To recreate the app: paste the manifest YAML into the "From an app manifest" flow at [api.slack.com/apps](https://api.slack.com/apps), install to the workspace, then configure webhooks and any additional scopes per the current feature plan.
