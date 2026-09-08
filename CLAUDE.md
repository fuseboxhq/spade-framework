# CLAUDE.md

This project uses the SPADE Framework for human-AI collaboration.
Read AGENTS.md before doing anything. It defines mandatory behaviour.

## SPADE Skills

Canonical skills live in `src/skills/`.
Claude invokes the generated `.claude/skills/` projection by name.
Never edit the generated projection directly.

| Skill | What it does |
|-------|-------------|
| `/spade` | Orchestrator entry point for Deliver, Plan, Scope, or Stub; Deliver includes project-native checks, a fixed-range two-axis review, and merge by policy when guards are live |
| `/spade-frontier` | Govern major-work discovery one question at a time, then graduate through human-owned Scope authoring |
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope; each task is one strict card (What / Done when / How / Verify / Needs / Blocks / Who); surfaces matching prior learnings |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-handoff` | Hand an approved Plan to a fresh CLI agent (Claude Code or Amp) in a new terminal window to deliver it; opt-in, macOS-only, configured via `/spade-onboard` |
| `/spade-review` | Dynamic-cast Scope and Plan review, plus fixed-range Delivery Review on independent Scope and engineering-standard axes |
| `/spade-learn` | Capture a learning for `.spade/learnings/` so future Plans reference it; `--refresh` for housekeeping |
| `/leads` | Capture out-of-scope discoveries without derailing current work; list, show, promote, or close them later |
| `/unslop` | Cut AI tells from any writing and add human voice; SPADE applies it to every human-facing output |
| `/spade-quick` | Fast-track path for trivial work (typos, tweaks, small fixes) |
| `/spade-unhinged` | Run one explicitly confirmed throwaway experiment under a continuous protected-path gate; retained work gets a non-shipping Draft PR audit |
| `/spade-research` | Landscape research via an isolated Opus 4.7 subagent (read-only); optional Linear artefact with explicit consent (v1.3.0+) |
| `/spade-evaluate` | Record a criterion-by-criterion evidence matrix and the verdict when every criterion is machine-verifiable; human-only rows go to the human |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-list` | List active Scopes by SPADE phase |
| `/spade-update` | Update the framework and run applicable consumer migration procedures |
| `/spade-onboard` | Analyse codebase and fill in architecture docs for a new project |
| `/spade-intent` | Create or maintain INTENT.md — the project's durable statement of intent (problem, users, what it does, success, non-goals, maturity) |

## Architecture

Read these files before generating any Plan:

- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

## Linear Integration

This project tracks work in Linear. When Linear MCP is available:

- Parent issues are Scopes (human-written)
- Sub-issues are Plan tasks (AI-generated, full loop only)
- Use SPADE status labels: Scoped, Planning, Approval, Delivering, Evaluating, Done
- Full-loop labels: `ai-planned`, `ai-delivered`, `human-delivery`, `plan-rejected`, `needs-arch-review`
- Fast-track labels: `spade:quick`, `type:bug`, `type:tweak`, `type:chore`, `type:docs`, `type:refactor`

## Fast-Track Path

For trivial work — typos, one-line tweaks, small config changes, docs
updates — use `/spade-quick` instead of the full loop. The PR description
is the audit artefact. No sub-issues, no separate Plan, no approval gate
beyond PR review. Gate criteria and rules live in AGENTS.md under
"Fast-Track Path (Small Work)". When in doubt, use the full loop.

## Key Rules

- Never write code without a Scope, a valid fast-track gate pass, or an
  explicitly confirmed non-shipping `/spade-unhinged` experiment inside its
  canonical path gate
- Never deliver without an approved Plan (on the full loop); the Deliver level
  records a machine-attributed approval
- Move a parent issue to Done only on a recorded Evaluate verdict of PASS;
  the human owns Ship
- Never disarm or route around a mechanical guard; a deny is a halt to surface
- Always document Plans on the parent issue
- Always read ARCHITECTURE.md before planning
- Flag any architectural conflicts before proceeding
- Never create sub-issues on the fast-track path
- Never misuse `/spade-quick` for work that fails any gate criterion
- Never merge, mark ready, or treat an `[unhinged]` Draft PR as shipping approval

<!--
  Framework-repo note: consumer repos carry a compressed SPADE section
  between `SPADE-FRAMEWORK-START vX.Y.Z` and `SPADE-FRAMEWORK-END`
  markers. This repo is the framework itself, so the content above IS
  the source of truth and no wrapped block is needed. /spade-onboard
  refuses to run here.
-->
