# Slack Agentic OS — v3 Architecture

*Solo operator. Claude Max. Always-on home server. Slack Pro.*

## What changed from v2

- **Interactive buttons removed.** No state-mutation control plane in Slack at all. This eliminates the inbound exposure question entirely.
- **Persistent Claude Code session killed.** Start fresh sessions on demand only.
- **Workflow Builder removed from the briefing path.** Home server posts directly via webhook.
- **Podcast MCP disconnected outside demo windows.** Reconnected manually before AI Tinkerers events.
- **Hard rule on Claude.** Read, analyze, draft, summarize. Never state mutation. Never autonomous multi-step execution.
- **Synthetic checks added** on top of the Healthchecks.io baseline.

## Architecture in one sentence

Slack is a one-way notification surface fed by outbound webhooks from the home server, with `@Claude` available in-channel for read-only analysis backed by MCP tools. Decisions happen at the CLI or in Claude Code, not in Slack.

## Channels (7)

| Channel | Purpose | Notifications |
|---|---|---|
| `#alerts` | Pipeline failures, high-score job matches, infra down | Mobile push |
| `#ops` | Server health, cron confirmations, jobs pipeline activity | Desktop |
| `#feed-x` | Custom X feed via Slackbot — on probation, must earn keep | Manual check |
| `#claude-code` | `@Claude` interaction, Code routing threads | Desktop |
| `#briefing` | Single daily morning digest | Morning push |
| `#triage` | Read-only queue of items needing my attention | Desktop |
| `#sandbox` | Testing, throwaway | Muted |

`#triage` is now a **read-only queue I scan**, not a control surface. When I see something that needs action, I act on it via CLI, Claude Code, or the jobs pipeline directly — not via a Slack button.

## MCP servers

| MCP | Status | Purpose |
|---|---|---|
| Exa Search | Always on | Web research, content sourcing |
| Jobs Pipeline | Always on | `run_query`, `search_jobs`, `dismiss_job` |
| Slack | Always on | Read channels, search workspace, send messages |
| Google Calendar | Always on | Schedule context for briefings and queries |
| Podcast MCP | **Demo windows only** | Disconnected by default; reconnected manually before meetups |

## Integration layers (effectively 1.5)

1. **Outbound webhooks** — home server cron jobs POST to per-channel webhook URLs. The only path from server to Slack.
2. **Claude in Slack** — `@Claude` carries MCP tools. Read/analyze/draft only.

No Workflow Builder. No Bolt app. No inbound callbacks. No interactive components. No emoji control plane.

## The hard line on Claude

Claude in Slack is allowed to:
- query the jobs pipeline DB via MCP
- search the web via Exa
- read Slack channels and threads via Slack MCP
- check the calendar
- summarize, analyze, draft messages, suggest next steps
- route coding tasks to Claude Code (which runs in its own session, not persistent)

Claude in Slack is **not** allowed to:
- mutate state in the jobs pipeline (no `dismiss_job` from Slack — that's done at the CLI)
- post messages to channels other than the one it's invoked in
- trigger workflows or external automations
- make decisions that propagate beyond the thread

If a thread leads to "I should do X," I do X manually. Claude proposes; I dispose.

## Daily briefing path (simplified)

1. 6:55 AM — home server cron generates briefing payload (overnight jobs activity, calendar for the day, current `#triage` count)
2. 7:00 AM — same cron POSTs directly to the `#briefing` webhook
3. Done

One cron, one webhook, one channel. No Workflow Builder, no DM duplicate, no scheduler chain.

## Home server

- Jobs pipeline runs as a system cron
- Briefing cron posts directly to Slack
- Health check cron pings Healthchecks.io every 5 min
- Synthetic Slack-delivery check (see below)
- **No persistent Claude Code session.** Sessions are spun up on demand from the CLI when needed.
- **No inbound exposure.** The server is outbound-only to Slack.

## Monitoring (three independent paths)

1. **Healthchecks.io heartbeat** — server pings every 5 min. SMS/email if it stops. Catches: server down, cron stopped, network gone.
2. **Synthetic Slack delivery check** — twice-daily cron posts a timestamped ping to `#sandbox`. A separate check (also via Healthchecks.io) verifies the post arrived by reading via Slack MCP. Catches: webhook credential broken, Slack API issue, partial delivery failure.
3. **MCP health check** — daily cron hits each MCP server's health/readiness endpoint and reports failures via webhook to `#ops`. Catches: Jobs Pipeline MCP down, Slack MCP degraded, etc.

The Jobs Pipeline MCP is now treated as a monitored dependency, not a convenience. Claude losing data access is a tracked failure mode, not an invisible one.

## `#feed-x` probation criteria

`#feed-x` survives if and only if, after 30 days:
- I have actually checked it at least 3 times per week
- I have used at least one item from it as content fuel
- It has stayed under ~20 items per day

If it fails any of these, it gets archived and the X integration moves to a saved search I check on my own schedule.

## What v3 explicitly does NOT have

- Interactive buttons or any inbound callback path
- Persistent Claude Code sessions
- Workflow Builder anywhere
- Bolt app
- Emoji-driven automation
- Cloudflare Tunnel / Tailscale Funnel (no inbound = no tunnel)
- DM duplication of channel content
- State mutation via Claude
- Multi-step workflows living in Slack threads
- Podcast MCP connected outside demo prep windows
- Logs in chat
- Business+ tier

## The remaining v3 → v4 trap

The teardown's biggest insight stands: **the trap is success.** If this works, the temptation will be to add more workflow logic into Slack — richer cards, more channel specialization, more "just have Claude do it." The discipline is to resist that and instead build a real dashboard or TUI when operational needs grow beyond "alert + summarize + ask Claude a question."

Slack stays the entry point. It does not become the workflow engine.
