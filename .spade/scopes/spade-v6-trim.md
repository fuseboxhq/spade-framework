---
name: spade-v6-trim
title: SPADE v6 - cut the framework down to what current models need
status: delivering
type: refactor
phase: deliver
created: 2026-09-25
updated: 2026-09-25
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

## Scope: SPADE v6 - cut the framework down to what current models need

**Intent:** SPADE's spine (a human-owned finish line, stop rules, independent verification, human Ship) matches how current models work best, but the instruction volume on top of it no longer does.
A single Deliver run makes the agent read roughly 50k tokens of procedure, the always-loaded consumer fragments restate the same rules three times, and the tests pin exact sentences so every simplification fails CI.
v6 keeps the spine, deletes the procedure current models do not need, and moves the few hard rules into places that enforce them (guards) or state them once.

Drafted by the agent at Kevin's direction on 2026-09-25 after a review against Anthropic's Opus 5.5, context-engineering, skills, and dynamic-workflows guidance; Kevin approved full implementation in the same session.

### Acceptance Criteria

1. The always-loaded consumer fragments shrink to at most 3 KiB (`fragments/AGENTS-section.md`) and 1 KiB (`fragments/CLAUDE-section.md`), state each rule once, contain an explicit keep-going / stop-and-ask rule, and no longer tell the agent to demand a Scope for questions, debugging, spikes, or small direct requests.
2. The skill set drops `spade-approve`, `spade-frontier`, `spade-handoff`, `spade-intent`, `spade-list`, and `spade-unhinged`; their surviving duties move into `spade-plan` (approval), `spade-onboard` (INTENT.md), and `spade-status` (listing). The eight reviewer personas collapse into one `spade-reviewer` agent that takes a lens. `src/CAPABILITIES.md`, projections, installers, and the plugin payloads agree.
3. Every canonical `SKILL.md` is at most 12 KiB, and the procedure a Deliver run is told to read (orchestrator plus the skills and references it routes to, plus `docs/FRAMEWORK.md`) totals at most 60 KiB, down from about 196 KiB plus a 136 KiB FRAMEWORK.md.
4. Plans use a short format (approach with rejected forks, risks, a checkbox task list with done-when and verify per task) stored at `.spade/plans/<scope-id>.md`, which is also the resume point; `spade-run-state/v1`, per-task Linear sub-issues, the strict card schema, and the delivery-approach vocabulary are gone.
5. `/spade-review` defaults to one isolated reviewer that reports only merge-blocking problems with file, line, why, and how to show it fails, plus an unconfirmed list; lens reviewers run in parallel only when the change carries that risk; no skill contains "think hard" style instructions or pinned model names.
6. Prose-pinning tests are removed and replaced by structural lint (inventory, budgets, projections, tokens) plus a small manual behavioural eval harness under `tests/evals/`; guard, lifecycle, install, and onboarding tests still pass.
7. `bin/spade-guard` and `docs/FRAMEWORK.md` § Mechanical guards stay consistent, with the `unhinged` mode and handoff surfaces removed; `tests/hooks/guards.sh` passes.
8. The release is v6.0.0 with a `5.1.0 -> 6.0.0` fragment-refresh migration, a CHANGELOG entry, and README, ARCHITECTURE, PATTERNS, ANTI-PATTERNS, and INTENT updated to match.

### Constraints

- Markdown plus shell only; no runtime or build step (ANTI-PATTERNS).
- `setup` and `setup.ps1` stay in parity.
- Guards stay the home for invariants that need no judgement; the 14-category security-sensitive path surface stays the single definition.
- Claude and Codex keep capability parity through `scripts/project-hosts.sh`.
- Architecture conflicts, recorded here and resolved in this change: PATTERNS "The Plan is tracker-canonical ... one sub-issue per task" and ANTI-PATTERNS "ten explicit gate criteria" are both superseded.

### Dependencies

None. Linear MCP is not reachable from this session, so the Scope and Plan live under `.spade/` as the tracker fallback.

### Out of Scope

- The lifecycle helper's migration engine, installer receipts, and HTML renderer internals (code, not context).
- Changing the merge policy or the security-sensitive path taxonomy.
- Kevin's global CLAUDE.md and Codex AGENTS.md cleanup, handled separately outside this repository.
