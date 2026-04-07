# RyanClaw

A Slack-first autonomous AI agent.

RyanClaw is an opinionated take on [OpenClaw](https://github.com/openclaw/openclaw) that goes all-in on Slack as the agentic OS. Instead of spreading across 20+ messaging platforms, RyanClaw treats Slack as the primary interface where agents coordinate, execute tasks, report status, and interact with users.

## Architecture

See [slack-agentic-os-v3.md](slack-agentic-os-v3.md) for the full v3 architecture.

Slack is a one-way notification surface fed by outbound webhooks from a home server, with `@Claude` available in-channel for read-only analysis backed by MCP tools. Decisions happen at the CLI or in Claude Code, not in Slack.

### Slack app

The **Agentic Hub** app is defined in [`agentic-hub.manifest.yaml`](agentic-hub.manifest.yaml). It provides incoming webhooks to 7 channels (`#alerts`, `#ops`, `#feed-x`, `#claude-code`, `#briefing`, `#triage`, `#sandbox`) with no interactive components, no slash commands, and no event subscriptions.

To recreate the app: paste the manifest YAML into the "From an app manifest" flow at [api.slack.com/apps](https://api.slack.com/apps), install to the workspace, then add per-channel webhooks in app settings.
