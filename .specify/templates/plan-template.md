# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design. See
`.specify/memory/constitution.md` v2.2.0 for full principle text.*

For each principle, answer and cite evidence in the plan. Log any violation in
Complexity Tracking with a concrete reason the simpler alternative was rejected.

- **I. Slack Is a Full Workflow Surface** — If this adds an inbound Slack path,
  which mechanism is used (socket mode / event subscriptions / webhook
  callbacks / tunnel) and where does the credential live? State-mutating Slack
  components are permitted; just disclose the shape.
- **II. Claude Runs YOLO (with carve-outs)** — Does this plan touch AWS?
  Remember the standing carve-out: AWS mutations (Terraform apply, Lambda
  deploys, RDS writes, IAM, secret rotation) require operator confirmation.
  Is any NEW carve-out proposed here? If yes, justify and note that durable
  carve-outs belong in the constitution, not the plan.
- **III. Solo-Operator Simplicity** — Does this require multi-env
  infrastructure, promotion gates, compliance work, coverage thresholds, or a
  strict TDD discipline? If yes, justify (a learning-project reason like "to
  learn X" is acceptable; state it plainly). AWS resources are managed by
  Terraform and live in a single account/region — note any deviation.
- **IV. Three Independent Monitoring Paths** — If this adds an always-on
  dependency (inbound Slack handler, agent, new MCP, scheduled job, Lambda),
  which monitoring path covers it (Healthchecks heartbeat / synthetic Slack
  delivery / MCP health) or does it add a justified fourth path?
- **V. Outgrow Slack When It Hurts** — Is this adding new flow inside Slack,
  or porting an existing flow out to TUI / CLI / dashboard? If adding: is the
  flow small and well-scoped, or is it already showing signs of the fragility
  threshold (brittle button states, webhook chains, silent failures)?

Initial Constitution Check: [PASS | VIOLATIONS LOGGED]
Post-Design Constitution Check: [PASS | VIOLATIONS LOGGED]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
