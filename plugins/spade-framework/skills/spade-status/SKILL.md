---
name: spade-status
description: Show the current SPADE phase and progress for active work. Use when someone asks "where are we", "what is the status", "show me progress", "what phase are we in", or any question about the current state of work in progress. Also use at the start of a session to orient on active work.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using exec_command.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use. Use these values
for all Linear operations. If the file doesn't exist, ask the human which
team and project to use, or suggest running `/spade-onboard` first.

## Mode Resolution

Before any tracker call or local-file access, resolve the operating mode
**once** per `docs/FRAMEWORK.md` § Mode Resolver:

- Read `mode:` from `.spade/config`. An explicit value (`linear`,
  `local`, or `hybrid`) wins immediately.
- If `mode:` is absent, auto-detect: probe with a `list_teams` MCP call
  (try/skip, 5-second timeout). Resolve `linear` if it returns a team
  set containing `linear.team_id`; otherwise resolve `local`.
- Failure policy: an explicit `mode` with a configured `team_id` and a
  failing probe is a **fail-loud abort**; an absent `mode` with a
  failing probe **degrades quietly to `local`**.

Do not embed the resolver algorithm — it is single-sourced in
FRAMEWORK.md. The resolved mode governs the data source below.

# SPADE Status

You are providing a status overview of active SPADE work. This helps humans
understand where things stand at a glance.

Read `../spade/references/continuity.md` completely before classifying a run summary.

## What To Show

For every full-loop item, read its newest continuity summary per `/spade`'s `references/continuity.md` status-read contract.
Status is read-only and structural: do not validate external claims, repair state, write a successor, or present recorded state as permission to continue.

### In `linear` / `hybrid` mode

1. Query for active parent issues (status not "Done"). Include items with
   any of: `ai-planned`, `ai-delivered`, `spade:quick`, or standard SPADE
   status labels.
2. **Separate fast-track items from full-loop items.** Any issue with the
   `spade:quick` label belongs in its own "Fast-track items" subsection —
   these have no sub-issues, no Plan document, and are tracked by PR state
   rather than SPADE phase.
3. For each full-loop active issue, show:
   - Issue ID and title
   - Current SPADE phase (based on status)
   - Number of sub-issues: total, completed, in progress, pending
   - Delivery mode breakdown: how many AI-delivered vs human-delivered
   - Any blocked or flagged items
   - Continuity: validation required, halted, complete, legacy restart required, invalid, or not recorded
   - The recorded next action prefixed with `unvalidated` until `/spade` validates it
4. For each fast-track item, show:
   - Issue ID and title
   - `type:*` classification (bug / tweak / chore / docs / refactor)
   - PR state (no PR yet / open / merged / merged+evaluated)
   - Whether the gate-check template has been filled
5. Present both groups as clean summary tables.

### In `local` mode

Read active work from local files under `.spade/`. Make **zero** Linear
MCP calls.

1. Glob `.spade/scopes/*.md` for Scope files (per FRAMEWORK.md § Local
   Layout). If the directory is empty or absent, say there is no active
   SPADE work and suggest running `/spade-scope`.
2. For each file, parse the YAML frontmatter and read `status:` and
   `title:`. Tolerate legacy files with missing or unknown fields —
   never rewrite them.
3. Map each `status:` to a SPADE phase using the Phase Identification
   table below, then skip any Scope whose phase is Done.
4. For each remaining Scope, check whether a matching Plan file exists
   at `.spade/plans/<slug>-plan.md` (the slug is the Scope's filename
   slug). Report plan presence in the Progress column: `Plan ready` if
   the file exists, `Not yet planned` if it does not.
5. If the Scope has a stable `id`, look for `.spade/runs/<id>.md` and classify
   its newest summary structurally per the continuity status-read contract.
   If a legacy Scope lacks an `id`, report `legacy restart required` when old
   trace history exists and `not recorded` otherwise; never invent or backfill
   an id.
6. Present the same status table as the `linear` / `hybrid` branch (see
   `## Output Format`). Sub-issue counts, delivery-mode breakdowns, and
   the per-Scope sub-issue detail table need a tracker, so omit them in
   `local` mode — a local Scope has no sub-issues. Fast-track items are
   a tracker concept (`spade:quick` label), so there is no Fast-track
   subsection in `local` mode.

## Output Format

```
## SPADE Status

### Full-loop items

| Issue | Phase | Progress | Continuity | Blocked |
|-------|-------|----------|------------|---------|
| M-68: Build telemetry worker | Delivering | 3/5 tasks done | validation required; unvalidated `continue:task:M-68-4` | None |
| M-72: Knox Guard analysis | Approval | Plan ready, awaiting review | halted; unvalidated `gate:approve` | Human approval |
| M-75: Slack alerting | Scoped | Not yet planned | not recorded | None |

### Fast-track items

| Issue | Type | PR state | Notes |
|-------|------|----------|-------|
| M-91: Fix typo in README | type:docs | merged | Awaiting human Done |
| M-93: Bump default timeout to 30s | type:tweak | open | PR in review |
| M-95: Rename helper function | type:refactor | no PR yet | In progress |

### Detail: M-68 — Build telemetry worker

Phase: **Delivering** (3 of 5 sub-issues complete)

| Sub-issue | Mode | Status |
|-----------|------|--------|
| M-68-1: Temporal worker scaffold | ai-delivered | Done |
| M-68-2: Databricks connection | ai-delivered | Done |
| M-68-3: Normalisation logic | ai-delivered | Done |
| M-68-4: Elasticsearch indexing | ai-delivered | In Progress |
| M-68-5: Slack failure alerting | human-delivery | Todo |

Next action: Complete M-68-4, then M-68-5 needs human attention.
```

When a continuity summary exists, replace the generic `Next action` sentence with its recorded action prefixed by `Unvalidated:` and tell the human to invoke `/spade` for live validation.
For `invalid` or `legacy restart required`, recommend `/spade` for the bounded inspect, restart, or cancel path and never recommend direct task execution.

## Phase Identification

Map issue statuses to SPADE phases:

| Status | Phase | What is happening |
|--------|-------|-------------------|
| Scoped | S | Scope written, not yet planned |
| Planning | P | AI generating plan and sub-issues |
| Approval | A | Plan ready, awaiting human review |
| Delivering | D | Sub-issues being worked |
| Evaluating | E | Delivery complete, human verifying |
| Done | ✓ | Shipped and verified |

If an issue has no status or an unrecognised status, flag it and ask
the human to clarify.

## Recommendations

After showing status, suggest next actions:

Apply phase-based recommendations only when continuity is `validation required`
with a compatible recorded next action, or when continuity is `not recorded`.
For `invalid` or `legacy restart required`, recommend `/spade` for bounded
inspect, restart, or cancel recovery instead of `/spade-plan`, direct task
execution, or `/spade-evaluate`.
For `halted` or `complete`, surface the recorded human gate or terminal state
instead of deriving a next action from the tracker phase alone.

- Issues in "Scoped" → suggest running `/spade-plan`
- Issues in "Approval" → remind the human to review the plan
- Issues in "Delivering" with all sub-issues done → suggest `/spade-evaluate`
- Issues stuck in any phase for too long → flag for attention
- Fast-track items with merged PRs awaiting Done → remind the human to
  close them out
- Fast-track items with no PR yet → suggest running `/spade-quick` or
  ask whether the work has stalled
