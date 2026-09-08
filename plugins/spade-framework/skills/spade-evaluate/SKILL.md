---
name: spade-evaluate
description: Evaluate a delivered fixed-range diff against the original Scope and repository engineering standards. Produces a current two-axis Delivery Review plus one classified evidence-matrix row per acceptance criterion, records the PASS, PARTIAL, or FAIL verdict when every row is machine-verifiable with fresh evidence, otherwise recommends one for the human, closes the issue on a PASS, and leaves Ship to the human. Use when delivery is complete, someone says "evaluate this", "check if this is done", or "verify the output", or all delivery tasks are complete.
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
FRAMEWORK.md. The resolved mode governs every tracker-vs-local branch in
this skill:

- **`linear`** — the tracker is canonical; operate against Linear MCP.
- **`local`** — `.spade/` files are canonical; make **zero Linear MCP
  calls**; read and write the paths in FRAMEWORK.md § Local Layout.
- **`hybrid`** — the tracker is canonical; after a successful tracker
  write, mirror to `.spade/` best-effort per FRAMEWORK.md § Hybrid Mode.

# SPADE Evaluate

You are helping a human evaluate delivered output against the original Scope.
Evaluation is distinct from Approval. Approval validates the approach.
Evaluation validates the output.

## Quick-Path Branch (spade:quick items)

**Before doing anything else, check the parent issue's labels.** If it has
`spade:quick`, this is a fast-track item and the evaluation rules are
different — skip the rest of this skill's default flow and use the
quick-path procedure below.

Quick-path items have **no sub-issues**, **no separate Plan document**,
and **no Delivery Bundles**. The PR description is the audit artefact.
The `type:*` label tells you what kind of change it was.

### Quick-path evaluation steps

1. **Find the PR.** Look for a PR URL in the issue comments, or search
   for a PR that references the issue ID.
2. **Check merge status.** Is the PR merged, open, or closed without merge?
3. **Check CI.** For merged PRs, confirm CI was green at merge. For open
   PRs, confirm CI is currently green.
4. **Read the PR description.** It must follow the `/spade-quick` template:
   Type, SPADE path, Linear link, What, Why, Change, Verification checklist,
   and the Gate check with all ten boxes ticked.
5. **Validate the gate retrospectively.** Glance at the diff — does the
   actual change still match every gate criterion? Specifically check:
   - ≤ ~50 LoC changed
   - One file or tight cluster
   - No new dependencies (check package manifest files in the diff)
   - No schema / migration files touched
   - No auth, crypto, or permission-check code touched
6. **Check the labels.** Confirm `spade:quick` and a `type:*` label are
   applied, plus `ai-delivered` or `human-delivery`.

### Quick-path verdict

- **PASS** — PR merged, CI green, template filled, gate still holds on
  review. Close the issue on that basis.
- **PARTIAL** — Something small is missing or wrong (a missed verification
  step, a typo in the fix, a gate-check box that shouldn't have been ticked
  on closer inspection).
  - If the PR has **NOT merged yet**: push fixes as **new commits to the
    same branch/PR**. Re-request review if appropriate.
  - If the PR **has merged**: open a **new quick-path PR** that references
    the original (e.g. title prefix "Follow-up to #123 for PARTIAL eval
    findings"). Run the full `/spade-quick` workflow for the follow-up PR,
    including the gate check and the template.
  - **NEVER create sub-issues to track the fix.** Sub-issues are forbidden
    on the quick path regardless of verdict.
- **FAIL** — The change fails the gate retrospectively (e.g. actually
  touched a schema, or actually broke a public API). The fast-track was
  misused. The work must be rolled back and redone through `/spade-scope`
  with a proper Plan. Apply `plan-rejected` to the original issue if it
  exists, explain in a comment what gate criterion was violated, and
  recommend re-opening the work as a full-loop Scope.

### Quick-path Linear updates

- If PASS: move the issue to Done on the strength of the merged, green PR.
  Post a brief eval comment confirming the PR meets all gate criteria and
  the acceptance criteria (from the PR description's "What" / "Why").
- If PARTIAL: post an eval comment listing the specific findings and what
  the follow-up looks like (new commits vs new PR).
- If FAIL: post an eval comment explaining the gate violation and move
  the issue back to the human for re-scoping.

Do NOT iterate sub-issues for quick-path items — they do not exist.
Do NOT look for a Plan document — there isn't one. The rest of this
skill, from "Before You Start" onward, applies only to full-loop items.

---

## Full-Loop Evaluation

For items that are NOT `spade:quick`-labelled, follow the standard
evaluation flow below.

## Before You Start

1. Read the original Scope (parent issue), including all acceptance criteria
2. Read the Plan that was approved. **Read order**: tracker first
   (the Linear parent-issue comment posted by `/spade-plan`), then
   `.spade/plans/<issue-id>-plan.md` as a fallback. The local file
   exists only for Linear-less environments (v1.2.0+) or as a
   pre-v1.2.0 historical archive — if the tracker has the Plan, that
   is the canonical copy.
3. Review what was actually delivered across all sub-issues
4. Resolve the final delivered `head_sha` and obtain a current Delivery Review
   for the exact fixed range. Invoke `/spade-review` in Delivery Review mode if
   the report is missing, incomplete, degraded, or tied to another head.

## Acceptance evidence contract

Read `references/acceptance-evidence.md` completely before classifying
criteria, running checks, or recommending the full-loop verdict.

The load-bearing invariants are:

- every acceptance criterion appears exactly once in the evidence matrix;
- every row is classified as `diff-verifiable`, `runtime-verifiable`,
  `external-state`, or `human-only`;
- runtime and UI evidence is freshly produced against the final reviewed head;
- UI evidence is required only when the criterion has a UI surface and is
  selected for the claim being proved;
- external state is proven only by an authoritative read, never inferred from
  repository state;
- human-only criteria remain open until the human confirms them;
- findings from both Delivery Review axes remain visible during synthesis; and
- the agent gathers evidence and records PASS, PARTIAL, or FAIL when every row
  is machine-verifiable, the human selects it otherwise, and whoever records a
  PASS also moves the issue to Done. Ship stays human.

## Evaluation Checks

Run each acceptance criterion from the Scope as a check:

### For Each Acceptance Criterion

1. **State the criterion** exactly as written in the Scope.
2. **Classify it** using the four-value acceptance-evidence vocabulary.
3. **Gather current evidence** at the broadest reliable check named by the
   relevant card's **Verify** field in the Plan.
4. **Record the evidence** including exact command and concise result, range or
   head SHA, authoritative external source, or human confirmation as applicable.
5. **Set the row status** to `satisfied`, `open`, or `failed` and name the gap
   whenever it is not satisfied.
6. **Set the criterion verdict** to Pass, Partial, or Fail from that evidence.

### Additional Quality Checks

Use the independent repository engineering-standard axis from Delivery Review
for quality checks beyond the acceptance criteria.
Synthesize, but do not replace, its findings with these final questions:

- **Does it actually work in practice?** Not just in theory, not just in tests,
  but in the real environment with real data.
- **Are there quality issues?** Code quality, edge cases, error handling,
  logging, documentation.
- **Are there regressions?** Has the delivered work broken anything that
  was previously working?
- **Would you be comfortable shipping this?** The gut-check question. If the
  answer is no, articulate why.

## Output Format

Apply the `/unslop` pass to the evaluation's prose - narrative, evidence
notes, and gap descriptions - never to commands, SHAs, or matrix values.

Present the evaluation in this format:

```markdown
## Evaluation: [Scope Title]

### Delivery Review

- **Range:** [base_sha..head_sha and source]
- **Scope-conformance axis:** [complete/incomplete and finding count]
- **Engineering-standards axis:** [complete/incomplete and finding count]
- **Pass eligible:** [true/false with reasons]

### Acceptance Evidence Matrix

| # | Criterion | Class | Evidence | Head / freshness | Status | Verdict | Open gap |
|---|-----------|-------|----------|------------------|--------|---------|----------|
| 1 | [Exact criterion] | diff-verifiable/runtime-verifiable/external-state/human-only | [Source, command + result, or confirmation] | [head SHA/current/not applicable] | satisfied/open/failed | Pass/Partial/Fail | [None or exact gap] |
| 2 | [Exact criterion] | ... | ... | ... | ... | ... | ... |

### Quality Assessment

- **Functionality:** [Works / Partially works / Broken]
- **Code quality:** [Good / Acceptable / Needs work]
- **Test coverage:** [Adequate / Gaps identified]
- **Edge cases:** [Handled / Partially handled / Not addressed]
- **Documentation:** [Complete / Partial / Missing]

### Agent Recommendation

[PASS / PARTIAL / FAIL with reasons from both review axes and the evidence matrix]

### Overall Verdict

[PASS — ready to ship | PARTIAL — specific fixes needed | FAIL — rework required]
[Recorded by: agent | human]

When every row is diff-verifiable or runtime-verifiable, satisfied, fresh on
the reviewed head, and both review axes completed, record the verdict
yourself: it equals the agent recommendation. Through `exec_command`, write
`.spade/guard/reviewed-head-<pr>` as one line, `<reviewed head sha> <verdict>`,
so the merge guard can bind an on-green merge to a PASS on exactly that head
(`docs/FRAMEWORK.md` § Mechanical guards). A PARTIAL or FAIL line is written
too and denies the merge until a later PASS replaces it.
Otherwise the verdict is a fixed-option human decision: ask via
**`request_user_input when available, otherwise a concise direct question`** (per `docs/FRAMEWORK.md` § "Asking the Human")
with the three options *PASS — ready to ship*, *PARTIAL — fixes
needed*, *FAIL — rework required*.
If PASS is not evidence-supported, say so plainly while still leaving the final
selection to the human.
The same structured-choice rule applies to the quick-path verdict at the top of
this skill; never use a free-form "what's the verdict?" prompt for the final
decision.

### Required Actions (if not passing)

1. [Specific action needed]
2. [Specific action needed]
```

## After Evaluation

### Learning candidate handoff

After synthesizing the two Delivery Review axes, acceptance-evidence matrix, required checks, and human verdict, apply `/spade-learn`'s candidate gate to that bounded evidence.
Use only a failed assumption, recurring pitfall, new project constraint, reusable pattern, or correction to an active learning.
Ordinary successful completion, generic quality advice, and restated findings produce `candidate:none` without a prompt.
When one evidence-backed candidate exists, invoke `/spade-learn`'s candidate branch so the human sees one deduplicated draft and chooses Public-safe, Private, or Skip before any learning write.
Do not mine the wider conversation or persist the draft in the evaluation report or run state.
Learning capture never changes the recorded verdict, the Done transition, the merge policy, or the Ship decision.

### If PASS

- Post the verdict on the issue. Done is the audit-trail closure point, so
  record the PASS first and close on the strength of it, never the other way
  round.
- If you recorded the verdict, move the issue to "Done", then hand back to the
  caller: `/spade` Deliver merges by `autonomy.deliver.merge`; standalone, tell
  the human the PR is ready under their merge policy.
- If the human recorded the verdict, ask them to confirm they are satisfied
  before you close the issue.
- Ship stays human, expressed through the merge policy.

### If PARTIAL (minor fixes needed) — full loop only

- List the specific fixes required
- These go back to Deliver — create new sub-issues or reopen existing ones
- The fixes should be small and targeted, not a re-plan
- After fixes are delivered, run evaluation again

**For quick-path items, see the Quick-Path Branch at the top of this
skill — sub-issue creation is forbidden there regardless of verdict.**

### If FAIL (fundamental problems)

- Explain what went wrong and where the approach broke down
- Recommend whether to:
  - **Re-plan**: The approach was wrong. Go back to Plan with lessons learned.
  - **Re-scope**: The Scope was unclear or the problem was misunderstood.
    Go back to Scope with the human.
- Do not attempt to patch a fundamentally broken delivery

## Linear Integration

In `linear` or `hybrid` mode:
1. Update parent issue status to "Evaluating"
2. Add the evaluation report as a comment on the parent issue
3. If fixes needed, create new sub-issues or reopen relevant ones
4. If passed, move the parent issue to "Done" on the strength of the
   recorded PASS. If the verdict is PARTIAL or FAIL, or any evidence row is
   still open, leave it in "Evaluating".

In `local` mode, make no Linear MCP calls: write the evaluation report
into the local Scope file's body, and set its frontmatter `status:`
(the resulting phase) and `updated:` (today's date) per FRAMEWORK.md
§ Local Layout. Set it to `done` on a recorded PASS and leave it at
`evaluating` otherwise.
