<!--
SYNC IMPACT REPORT
Version: 2.3.0 → 2.4.0
Bump rationale: MINOR — Principle IV path 2 mechanism simplified. The
synthetic Slack-delivery check no longer reads messages back via the Slack
Web API; instead it confirms the incoming webhook returned status 200 with
body "ok". This drops the bot token and channel-ID dependencies as part of
the Slack Pro tier transition (no bot user on the Agentic Hub app). A
webhook-returns-200-but-message-silently-dropped edge case is no longer
detected automatically — the operator accepts that gap.

Principles modified:
  IV. "Two Independent Monitoring Paths" — path 2 mechanism changed from
      "post + read-back via Slack Web API" to "post + confirm 200/ok
      webhook response." Principle title unchanged; the rule still
      mandates two independent paths.

Principles unchanged:
  I.   Slack Is a Full Workflow Surface
  II.  Claude Runs YOLO (AWS carve-out intact)
  III. Solo-Operator Simplicity
  V.   Outgrow Slack When It Hurts

Sections touched:
  - Technical Constraints: unchanged.
  - Development Workflow: unchanged.

Templates realigned:
  ✅ README.md — v2.3 → v2.4; path 2 summary updated.
  ✅ CLAUDE.md — v2.3 → v2.4.
  ✅ .specify/templates/plan-template.md — version reference bumped.
  ✅ scripts/slack_synthetic_post.py — deleted.
  ✅ scripts/slack_synthetic_verify.py — deleted.
  ✅ scripts/slack_synthetic_check.py — new; merges post + verify into a
     single post-and-confirm-200 probe.
  ✅ .env.example — SLACK_BOT_TOKEN and SLACK_SANDBOX_CHANNEL_ID removed.
  ✅ .specify/templates/spec-template.md — unchanged.
  ✅ .specify/templates/tasks-template.md — unchanged.

Deferred items / TODOs:
  - None.
-->

# RyanClaw Constitution

RyanClaw is a solo-operator "Slack Agent OS" — a personal learning project,
not a production system, not an enterprise deliverable. This constitution
encodes the architectural principles currently in force. Tone is deliberately
pragmatic and relaxed. Enterprise defaults (strict TDD, coverage thresholds,
SLAs, compliance regimes, multi-env promotion gates) are explicitly out of
scope.

v2.0 deliberately inverted the cautious v1.0 stance on two principles (Slack
surface and Claude autonomy). v2.1 acknowledges the hybrid runtime (home
server plus a narrow AWS surface) and starts a YOLO carve-out list with AWS
mutations as the first entry. v2.2 tightens RDS tenancy to a least-privilege
role and narrows the MCP health check to home-server scope. v2.3 drops the
MCP health check entirely — third-party MCPs self-alert via their SaaS
pages and Lambda MCPs surface at call time, which turned out to be enough.
v2.4 simplifies path 2 to a post-and-confirm-200 check, removing the Slack
bot token dependency after the Slack Pro tier transition.

## Core Principles

### I. Slack Is a Full Workflow Surface

Slack MAY be used as a two-way surface. Interactive buttons, slash commands,
event subscriptions, Workflow Builder flows, Bolt apps, emoji-driven
automation, and socket-mode or tunnel-backed inbound paths are all on the
table. State mutation from Slack is permitted.

**Why**: v1.0 forbade inbound paths to eliminate a whole category of exposure
work (tunnels, credentials, drift). That was the right starting posture, but
it also ruled out learning what "Slack-as-workflow-engine" actually costs at
this scale. v2.0 flipped the bet and finds out.

**How to apply**: Features MAY propose Slack-driven state changes, inbound
components, or cross-channel automation. The plan should note which inbound
mechanism it uses (socket mode / event subscriptions / webhook callbacks /
tunnel) and where the credential lives. Principle IV still applies — any new
inbound surface must fit one of the three monitoring paths or add a justified
fourth.

### II. Claude Runs YOLO

Claude (in Slack and in Claude Code sessions) MAY execute state-changing
actions, multi-step sequences, and autonomous operations without per-step
operator confirmation. Default permission posture is auto-approve. The
operator reviews outcomes, not intermediate steps.

**Why**: v1.0's "Claude proposes, operator disposes" posture was designed to
keep a misstep cheap. It also made the operator the bottleneck on every
trivial action. v2.0 treats operator confirmation as friction rather than
safety net and finds out what actually breaks. That's the learning.

**How to apply**: Plans MAY delegate any action to Claude — merges, deploys,
MCP state mutation, job-pipeline changes, Slack workflow actions, local infra
edits — subject to the carve-outs below. If a specific action category
reveals a blast radius large enough to want a gate back, add it to the
carve-out list in a future amendment; do not rely on ad-hoc gates scattered
across individual plans.

**YOLO carve-outs** (actions that require explicit operator confirmation
despite the YOLO default):

- **AWS mutations** — Claude MUST NOT autonomously make changes in AWS. That
  covers `terraform apply` / `terraform destroy`, Lambda code deploys, RDS
  schema or data writes, IAM edits, secret rotation, and any AWS SDK or CLI
  call that creates, updates, or deletes a resource. Operator confirms each
  such action. Read-only operations (describing resources, tailing
  CloudWatch logs, running scoped SELECTs through a read-only role, `terraform
  plan`) remain YOLO.

### III. Solo-Operator Simplicity

One operator. Runtime is a hybrid: a home server running system cron, plus a
narrow AWS surface (an RDS instance shared with the separate jobs-pipeline
repo, and Lambdas that host MCP servers authored here). There are no
separate dev / staging / prod environments — whatever is deployed is prod,
and "testing in prod" is the stated stance. No promotion gates, no
multi-tenancy, no compliance regime, no SLAs, no on-call rotation, no
coverage threshold, no TDD discipline imposed as a gate.

**Why**: This is a learning project. Enterprise ceremony (multi-env
promotion, approval chains, coverage gates) adds friction without adding
safety at this scale, and trains bad instincts for what actually matters in a
home-server-plus-a-bit-of-cloud system of one. Breaking prod is acceptable
cost; the learning from breakage is the point.

**How to apply**: Reject proposals that import multi-env patterns, compliance
scaffolding, or coverage gates without a concrete reason they pay off here.
Tests, types, and linters are welcome when they accelerate learning or catch
real regressions; none are gates. "I want to try this pattern to learn it"
is a valid reason — state it plainly. AWS resources go into the one and
only environment; name them plainly (`ryanclaw-mcp-foo`), don't prefix with
env names.

### IV. Two Independent Monitoring Paths

Operational health MUST be covered by two independent paths: (1) a
Healthchecks.io heartbeat pinged by the home server every 5 minutes, and
(2) a synthetic Slack-delivery check that posts a timestamped ping to
`#sandbox` and confirms the webhook returned 200/ok, alerting `#ops` via
webhook on any non-success response. Path 1 catches "home server or cron
dead"; path 2 catches "Agentic Hub webhook URL broken, rate-limited, or
otherwise rejecting."

**Why**: Silent failure is the real enemy. These two paths together cover
the failure modes that actually bite at this scale. MCP uptime isn't worth
its own monitoring cron: third-party MCPs (Exa, Slack, Google Calendar,
the jobs-pipeline MCP) self-alert via their SaaS provider pages, and
Lambda-hosted MCPs authored in this repo surface failures at call time
when the operator hits one from Slack or Claude Code.

**How to apply**: Any new always-on dependency (inbound Slack handler,
agent, scheduled job, Lambda) either states which of the two paths covers
it, justifies a third path, or explicitly accepts the gap in the plan.
Home-server crons and inbound Slack handlers fit path 1 or path 2
naturally — "no monitoring" is not a valid answer for those. Lambda MCPs
and third-party MCPs are the accepted exception, per the Why above.

### V. Outgrow Slack When It Hurts

Slack can host workflow logic, state, and control surfaces under v2.0. When a
given flow starts paying for itself in Slack-specific fragility — brittle
button states, webhook chains that break silently, event handlers racing,
threads drifting out of sync — port it to a TUI, CLI, or dashboard. The
discipline is recognizing the moment, not preventing entry.

**Why**: v1.0 refused Slack workflow logic preventively. With I and II
inverted, that refusal no longer fits. But Slack-as-workflow-engine still
works only until it doesn't, and the sooner the operator notices "doesn't,"
the cheaper the port. Recognition replaces prevention.

**How to apply**: When operator time is being consumed by maintaining Slack
state machines rather than working on the underlying problem, that is the
signal. Log the port as a plan rather than incrementally patching the Slack
flow in place.

## Technical Constraints

- **Language**: Python. All function signatures carry type hints.
- **Formatting / linting**: ruff + black. Run before committing.
- **Testing**: pytest, when tests earn their keep. No coverage threshold, no
  TDD gate.
- **Home server**: system cron for scheduled jobs (briefing, monitoring
  pings, synthetic delivery check). Inbound Slack paths are permitted here —
  socket mode, event subscriptions, tunnels (Cloudflare / Tailscale / ngrok)
  are all fair game, declared per feature.
- **AWS footprint**: single AWS account, single region by default.
  Multi-region requires Complexity Tracking justification. All AWS resources
  are managed by Terraform; manual console edits are tolerated while
  exploring but ported to Terraform before the feature closes.
- **AWS Lambda**: hosts MCP servers authored in this repo. Cold starts are
  acceptable; hot availability is not a requirement at this stage.
- **AWS RDS**: shared with the separate jobs-pipeline repo. RyanClaw is a
  tenant, not an owner — schema ownership lives with the jobs-pipeline repo.
  RyanClaw connects via a least-privilege role whose grants are limited to
  the `ryanclaw_*` schema(s); DDL or writes against any other schema are
  blocked at the role level, not just by convention. Cross-repo coordination
  happens out-of-band; if a RyanClaw feature needs a change in a
  jobs-pipeline-owned schema, open an issue on the jobs-pipeline repo rather
  than writing DDL here.
- **Slack app**: Agentic Hub manifest (`agentic-hub.manifest.yaml`) grows
  scopes as features require (socket mode, event subscriptions, interactive
  components, slash commands). Update the manifest in the same feature plan
  that needs the new scope.
- **Claude permissions**: Default posture is YOLO — Claude Code auto-approves
  tool calls, and Claude-in-Slack MAY take state-changing actions through its
  MCP tools. Carve-outs (currently: AWS mutations) live in Principle II, not
  in individual plans.
- **MCP tooling**: Exa, Jobs Pipeline, Slack, Google Calendar run always-on.
  Podcast MCP connects only during demo-prep windows. Custom MCPs authored
  in this repo deploy to AWS Lambda.
- **Secrets**: `.env` at project root, gitignored. AWS credentials and MCP
  tokens live there. Never committed, never echoed in webhook payloads, log
  lines, or Slack messages.

## Development Workflow

- Plans and specs produced by `/speckit.*` commands MUST be checked against
  the Core Principles as a gate before execution. A principle violation
  either justifies itself in the plan's Complexity Tracking section or the
  plan is revised.
- Amendments happen when the operator learns something worth encoding. No
  approval process — update this file, bump the version, prepend a Sync
  Impact Report comment, propagate changes to `.specify/templates/` in the
  same commit.
- Commits pass ruff, black, and pytest locally. CI is optional; if added
  later it is not a merge gate by default, per Principle III.
- Claude Code and Claude-in-Slack MAY execute state changes directly under
  Principle II, EXCEPT for AWS mutations — those require operator
  confirmation per the carve-out in II. `terraform plan` is YOLO;
  `terraform apply` is not.
- AWS changes land as Terraform diffs committed to this repo (or
  feature-branch commits). Manual console tinkering is fine during
  exploration but gets reconciled to Terraform before the feature ships.

## Governance

This constitution is the tiebreaker when plans or specs propose patterns
that conflict with its principles. It supersedes inherited speckit template
defaults and any enterprise conventions pulled in from external sources.

Amendments follow semantic versioning:

- **MAJOR**: A principle is removed, renumbered, or redefined incompatibly.
- **MINOR**: A new principle or major section is added, or existing
  guidance is materially expanded. YOLO carve-outs introduced later count
  here.
- **PATCH**: Clarifications, wording tweaks, typo fixes.

When amending: update this file, bump the version and `Last Amended` date,
prepend a Sync Impact Report comment summarizing the change, and verify that
`.specify/templates/` files still align.

Complexity that violates a principle MUST be tracked in the plan's Complexity
Tracking table with a concrete reason the simpler alternative was rejected.
"It's more elegant" is not a reason. "I want to learn X by building it this
way" is a valid reason for a learning project — state it plainly and move on.

**Version**: 2.4.0 | **Ratified**: 2026-04-14 | **Last Amended**: 2026-04-14
