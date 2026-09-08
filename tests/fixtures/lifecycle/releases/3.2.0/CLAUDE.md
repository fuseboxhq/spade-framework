consumer-owned prefix

<!-- SPADE-FRAMEWORK-START v3.2.0 -->

## SPADE Framework

This project uses the SPADE Framework for human-AI collaboration.
Read the SPADE section in AGENTS.md for mandatory behaviour rules.

### SPADE Skills

| Skill | What it does |
|-------|-------------|
| `/spade` | Orchestrator entry point: Deliver, Plan, Scope, or Stub; Deliver includes project-native checks and a fixed-range two-axis review |
| `/spade-frontier` | Govern major-work discovery one question at a time, then graduate through human-owned Scope authoring |
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope; each task declares an execution posture and tracer-bullet outcome; surfaces prior learnings |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-review` | Dynamic-cast Scope and Plan review, plus fixed-range Delivery Review on independent Scope and engineering-standard axes |
| `/spade-learn` | Capture a learning under `.spade/learnings/` so future Plans reference it; `--refresh` for housekeeping |
| `/spade-quick` | Fast-track path for trivial work (typos, tweaks, small fixes) |
| `/spade-research` | Landscape research via an isolated Opus 4.7 subagent (read-only); optional Linear artefact with explicit consent (v1.3.0+) |
| `/spade-evaluate` | Record a criterion-by-criterion evidence matrix and recommend a verdict for human Evaluate |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs |
| `/spade-intent` | Create or maintain INTENT.md — the project's durable intent (problem, users, what it does, success, non-goals, maturity) |

### Architecture Context

Read these files before generating any Plan:
- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

### SPADE Labels

Full-loop labels: `ai-planned`, `ai-delivered`, `human-delivery`,
`plan-rejected`, `needs-arch-review`

Fast-track labels: `spade:quick`, `type:bug`, `type:tweak`, `type:chore`,
`type:docs`, `type:refactor`

### Fast-Track Path

For trivial work — typos, one-line tweaks, small config changes, docs
updates — use `/spade-quick` instead of the full loop. The PR description
is the audit artefact. No sub-issues, no separate Plan, no approval gate
beyond PR review. Gate criteria and rules live in AGENTS.md under
"Fast-Track Path (Small Work)". When in doubt, use the full loop.

### Key Rules

- Never write code without a Scope (or a valid fast-track gate pass)
- Never deliver without an approved Plan (on the full loop)
- Never mark a parent issue Done.
  The human owns the final Evaluate verdict, Done, and Ship.
- Always document Plans on the parent issue
- Always read architecture docs before planning
- Never create sub-issues on the fast-track path
- Never misuse `/spade-quick` for work that fails any gate criterion
<!-- SPADE-FRAMEWORK-END -->

consumer-owned suffix
