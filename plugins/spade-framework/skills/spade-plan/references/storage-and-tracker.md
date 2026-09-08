# Plan Storage and Tracker Integration

Read this reference completely when an approved Plan is about to be persisted, revised, or mirrored.
## Saving the Plan

In `linear` and `hybrid` mode the Plan is **canonically stored in the
tracker** (today: Linear). In `local` mode `.spade/plans/` is canonical;
it also serves as a **fallback when a tracker write fails and a
read-path for historical archives written under v1.0–v1.1**. Saving
happens when (and only when) the human approves the Plan, never before.

The behaviour gate is **whether the tracker can accept the Plan**, not
merely "is the MCP tool present":

- **Tracker-path** — the resolved mode is `linear` or `hybrid`, the
  Scope has a parent issue ID, and posting the Plan as a comment on that
  parent issue succeeds. In this path the Plan lives in Linear (as the
  parent-issue comment + the sub-issues); in `hybrid` mode it is also
  mirrored to `.spade/plans/` best-effort. In pure `linear` mode do
  **not** write to `.spade/plans/`.

- **Fallback-path** — the resolved mode is `local`; or, in `linear`
  mode, the Scope has no tracker parent or the Linear write fails. (A
  tracker-write failure in `hybrid` mode aborts instead — there is no
  local fallback; see FRAMEWORK.md § Hybrid Mode.) Write the Plan to
  `.spade/plans/<issue-id>-plan.md` using the Scope's tracker
  identifier; if the Scope has no issue ID — the `local`-mode case —
  use the **Scope's slug** (its `name` field and `.spade/scopes/`
  filename) so the file is `.spade/plans/<scope-slug>-plan.md` and
  `/spade-status` and `/spade-list` can locate it.
  Prepend a banner at the top of the body marking it a fallback
  artefact, e.g.:

  ```markdown
  > **Fallback artefact.** Linear was unavailable when this Plan was
  > approved; this file is the canonical Plan until it is promoted to
  > the tracker.
  ```

  After writing, suggest the human commit it:

  ```bash
  git add .spade/plans/M-68-plan.md
  git commit -m "SPADE plan for M-68 (Linear-less fallback)"
  ```

The plan-file frontmatter schema is unchanged — historical archives
under v1.0–v1.1 and fallback writes under v1.2+ are schema-compatible:

```markdown
---
issue: M-68
title: Build ETL pipeline for device telemetry
date: 2026-04-08
status: approved
---
```

Create `.spade/plans/` lazily only when the fallback-path triggers; do
not pre-create the directory in tracker-path runs. If a fallback file
already exists for this issue (from a previous revision or a pre-v1.2.0
archive), overwrite it — git history preserves the old version.

### Linear Integration

In `linear` or `hybrid` mode, the tracker-path runs as follows:

1. Update the parent issue status to "Planning"
2. Create sub-issues for each task with:
   - Title from the Plan; the description is the task's complete card,
     verbatim - a sub-issue must be deliverable from its card alone
   - Label: `ai-planned`
   - Label: `ai-delivered` or `human-delivery` as appropriate
   - Label: `needs-arch-review` if the task touches architecture
   - **No `bundle:` label.** Bundle grouping is recorded in the Plan's
     Delivery Bundles section (attached in step 3) and nowhere else. Do
     **not** create or apply a per-bundle Linear label: bundle names are
     Scope-specific, so a label per Scope only pollutes the workspace
     taxonomy. Delivery reads the bundle grouping from the approved Plan,
     not from a label. The only Linear labels are the stable, reusable
     set above.
   - **No Milestone.** In a Horizon-bound repo (a `horizon:` block in
     `.spade/config`), leave sub-issues **unmilestoned** — Milestone
     membership is parent-Scopes-only so the Horizon rollup counts roadmap
     Scopes, not implementation tasks. Do not inherit the parent's
     Milestone onto its sub-issues. See `docs/FRAMEWORK.md` § Horizon
     Roadmap Binding.
3. Attach the full Plan document (including the Delivery Bundles section)
   as a comment on the parent issue
4. Update the parent issue status to "Approval" when the Plan is ready

If any of those steps fails — MCP unreachable, parent issue missing,
comment write rejected — fall through to the fallback-path above and
write `.spade/plans/<issue-id>-plan.md` instead. Do not retry
indefinitely.

**Surface partial state explicitly.** If the failure happened mid-flow
(for example: parent status moved to Planning, 3 of 7 sub-issues
created, comment write then failed), tell the human exactly which
steps succeeded and which did not — by sub-issue ID where applicable.
The Plan in the fallback file is the single source of truth at that
point; the half-created Linear state is something the human decides
to clean up, complete manually, or leave as-is. Do **not**
auto-delete partially-created sub-issues — destructive cleanup of
shared tracker state is a human decision.
