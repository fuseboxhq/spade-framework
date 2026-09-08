---
name: spade-plan
description: Generate a structured SPADE Plan from a Scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "generate a plan", "break this down", or when an issue is in "Scoped" status and needs a plan. Also triggers when a human references a Linear issue and asks the AI to plan against it.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using Bash.
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

# SPADE Plan

## Invocation by /spade

This skill may be invoked standalone or by the `/spade` orchestrator
(`docs/FRAMEWORK.md` § Autonomy Pipeline). When invoked by the orchestrator at
the **Plan** autonomy level, the orchestrator owns the run trace and halts at
the Approve gate after this skill completes — do not assume autonomy continues
into delivery. Surface a halt (e.g. the plan exceeds `autonomy.size_ceiling`,
or conflicts with ARCHITECTURE/ANTI-PATTERNS) per FRAMEWORK.md § Surfacing
channel so the orchestrator can record it. Behaviour when invoked directly is
unchanged.

You are generating a structured Plan for an approved Scope. The Plan is a
first-class artefact that gets documented and attached to the parent issue.
It is not something that happens invisibly.

## Conversational Style

Planning is collaborative, not a monologue. You generate the Plan, but
the human validates it before anything gets created in Linear.

**How to run this conversation:**

1. **Start by showing your understanding.** Before producing any tasks,
   summarise what you understand from the Scope in 3-4 sentences. Ask
   the human to confirm or correct. This catches misunderstandings early.
2. **Propose the plan, then discuss.** Present the full draft plan, then
   ask targeted questions: "Does the task breakdown feel right? Is there
   anything I'm underestimating? Should any of these be human-delivered
   instead?"
3. **Challenge your own assumptions.** Call out where you're guessing:
   "I'm assuming the Databricks connector supports scheduled queries —
   is that confirmed, or should Task 1 include a spike?"
4. **Be opinionated about task sizing.** If a task feels too large, say
   so and propose a split. If two tasks could be one, suggest merging.
5. **Ask about delivery preference.** Don't assume everything is
   AI-delivered. Some tasks need human context — flag these explicitly.
6. **Iterate before committing.** Do NOT create sub-issues in Linear
   until the human explicitly approves. The plan may need 2-3 rounds.

## Before You Start

1. Read the Scope carefully. Understand the intent, acceptance criteria, and
   constraints.
2. Read ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md if they exist in
   the repository. Your Plan must conform to these documents.
3. **Check `.spade/learnings/` for prior learnings.** If the directory
   exists, glob `.spade/learnings/*.md` (ignore `private/` unless the
   human explicitly opts in). For each file, read the frontmatter and
   surface entries that match the current Scope.

   **Cold-start threshold (v1.1.1).** Count the number of active
   non-archived entries under `.spade/learnings/` (exclude
   `status: archived` and the `private/` subdirectory unless
   opted-in). Call this count `N`.

   - When `N < 20`, the tag-match threshold is **1** — a single shared
     tag is enough to surface a learning. This is the cold-start
     regime: a repo adopting SPADE starts with zero learnings, so
     `≥ 2` means the loop looks dead on day one.
   - When `N ≥ 20`, the tag-match threshold is **2** — require at
     least two matching tags to surface a learning. At this volume
     single-tag coincidence becomes noise; the higher bar filters it.
   - The scope_ref path is unaffected by the threshold. An entry
     whose `scope_ref` equals the current Scope's Linear identifier
     always surfaces, regardless of `N`.

   So the match rule is: an entry surfaces if its `scope_ref` equals
   the current Scope's identifier OR at least `T` of its `tags` appear
   (case-insensitive, word-boundary match) in the Scope title or the
   tech stack row of `ARCHITECTURE.md`, where `T = 1 if N < 20 else 2`.

   Skip entries with `status: archived`.

   The `20` is a deliberate, named number. Changing it requires a new
   Scope. The rationale is documented in
   `docs/FRAMEWORK.md#learnings`.
4. If the Scope references specific systems or components, review the relevant
   code or documentation to understand the current state.
5. If the Scope is missing required fields, flag this and suggest running
   `/spade-scope` to complete it before planning.

## Plan Structure

Every Plan must include:

### Tasks (3-7)

Break the Scope into 3-7 discrete tasks. Each task must be:

- **Small enough** to complete in a focused session (2-4 hours of AI work,
  or a comparable human effort)
- **Independent enough** to pick up without extensive context-switching
  (though dependencies between tasks are normal)
- **Clearly scoped** so the deliverer knows when they are done

**Scopes are written for humans; Plans are written for the agent that
delivers them.** Every task is one strict card - fixed field set, fixed
order, every field present on every task:

- **What:** the change, named concretely - the files, components, or
  behaviour touched. A deliberately preparatory task says so here:
  "groundwork - enables Task N".
- **Done when:** the observable result that proves the task works -
  something a user, operator, caller, or downstream system can see, not
  an implementation activity.
- **How:** the approach in plain words, opening with the delivery
  approach for the task (see below). Name any specific technique, skill,
  pattern, or language and point to where it is defined instead of
  explaining it inline.
- **Verify:** where the result is checked - the tests, command, or
  evidence that confirms "Done when". For non-software tasks, the
  evidence of completion.
- **Needs:** the task numbers this waits on, or `none` ·
  **Blocks:** the task numbers (or external/human hand-offs) waiting on
  this, or `none`.
- **Who:** `AI` or `human` · effort: `brief` (< 1 hour), `moderate`
  (1-4 hours), or `significant` (4+ hours).

Card rules:

- Each field is one sentence - two at most when the task genuinely needs
  it, never a paragraph. Detail that does not fit belongs in the
  Technical Approach Summary, not the card.
- No framework jargon inside a card. A named technique is a pointer
  ("test-first, `FRAMEWORK.md#delivery-approaches`"), not an essay.
- Every field appears on every card, in this order, even when the value
  is `none`.

The card carries everything the old long-form fields carried: the
delivery approach opens **How**, the observable outcome is **Done when**,
where it is checked is **Verify**, dependencies in both directions are
**Needs/Blocks**, and delivery mode plus effort are **Who**.

### Vertical slices

Default each task to a **vertical slice**: behaviour a user, operator,
caller, or downstream system can observe end to end. Organise around
usable outcomes, not layers or specialist hand-offs - "Done when" makes
this concrete on every card.

A schema, shared helper, scaffold, test oracle, migration prerequisite,
or release projection may be intentionally horizontal. Mark it as
groundwork in **What**, name the task it enables, and give it a real
**Done when** so completion is still observable.

### Choosing the delivery approach

The delivery approach opens the **How** field: it declares how the task
will be tackled, not what it builds. The canonical vocabulary and
definitions live in `docs/FRAMEWORK.md#delivery-approaches`. Quick
selection:

- **test-first** - the behaviour is well specified; write failing tests,
  then satisfy them. Default for new features with clear acceptance
  criteria.
- **characterization-first** - touching existing code without adequate
  tests; pin down current behaviour in tests before changing it. Default
  for bug fixes and refactors of untested code.
- **refactor-first** - the area can't cleanly absorb the new behaviour;
  reshape it first, and name the refactor in **What** or **How** so
  reviewers can confirm it is in scope.
- **spike** - the right approach is genuinely unknown; the output is
  learning (a decision record or follow-up task), not shippable code.
- **straight-through** - the change is mechanical enough that ceremony
  adds nothing; say why in **How** ("covered by existing tests",
  "mechanical change"). Never a silent default.

A task may combine approaches when the work naturally splits - write it
in one line: "characterization-first on the existing module, test-first
on the new behaviour".

### Technical Approach

For each task, explain the technical approach:
- What will be built and how
- Which existing patterns from PATTERNS.md apply
- Which libraries or tools will be used
- How it integrates with existing code


### Prior Learnings Considered

If `.spade/learnings/` exists, read `references/prior-learnings.md` completely and apply its matching and evidence contract. Otherwise do not load it.

### Risk Callouts

Identify risks and assumptions:
- What might go wrong?
- What assumptions are being made?
- Where might the Plan need to change based on what we discover during delivery?
- Are there any ANTI-PATTERNS.md conflicts to flag?

### Testing and Verification

Per-task verification lives in each card's **Verify** field. For
software tasks name the tests and what "passing" looks like; for
non-software tasks name the evidence that demonstrates completion.

### Delivery Sequence

Present the tasks in recommended execution order, noting which can run in
parallel and which are sequential.

### Delivery Bundles

Group the tasks into **delivery bundles**. A bundle is the unit of shipping:
one branch, one pull request, closing every sub-issue assigned to it.

**Default: a single bundle containing every task in the Scope.** Six
interlinked tasks should not produce six PRs. Reviewers want the whole
story in one place, and interlinked code that moves together should land
together.

**Only split into multiple bundles when all of these hold:**

- The tasks are genuinely independent — no shared files, no shared
  symbols, and no dependency arrows between them.
- Splitting yields real value: isolated review, isolated revert, or
  independent deploy timing (e.g. a risky migration separated from
  related feature code, or docs-only work separated from code).
- The split does not force the reviewer to mentally stitch the Scope
  back together to understand either half.

If you are unsure, use one bundle. You can always split later; you cannot
easily re-merge six PRs.

For each bundle, specify:

- **Bundle name**: Short identifier, e.g. `etl-core`
- **Branch name**: Suggested git branch, e.g. `spade/M-68-etl-core`
- **PR title**: What the PR will be called
- **Tasks included**: Which task numbers land in this bundle
- **Rationale**: Why this grouping (especially if splitting from the default)

The bundle name is a **Plan-document identifier only**. It names the
branch and PR; it is never a Linear label. Bundle membership lives in
this section and in the parent→sub-issue hierarchy — that is enough for
delivery to group sub-issues under one PR.

## Output Format

Present the Plan in this format:

```markdown
## Plan for: [Scope Title]

**Technical Approach Summary:**
[2-3 sentence overview of the overall approach]

**Risks and Assumptions:**
- [Risk 1]
- [Risk 2]

### Tasks

#### Task 1: [Title]
- **What:** [The change, named concretely; "groundwork - enables Task N" if preparatory]
- **Done when:** [The observable result that proves it works]
- **How:** [Delivery approach, then the approach in plain words with pointers to named techniques/skills]
- **Verify:** [The tests, command, or evidence that confirms Done when]
- **Needs:** [none | Task N] · **Blocks:** [none | Task N | external hand-off]
- **Who:** [AI | human] · [brief | moderate | significant]

[Repeat for each task]

### Delivery Sequence
1. [Task X] (no dependencies, start immediately)
2. [Task Y] (depends on Task X)
3. [Task Z] and [Task W] (parallel, both depend on Task Y)

### Delivery Bundles

#### Bundle 1: [name]
- **Branch:** spade/[issue-id]-[name]
- **PR title:** [title]
- **Tasks:** Task 1, Task 2, Task 3, Task 4
- **Rationale:** Single bundle — all tasks share the ETL module and must
  land together to keep the pipeline coherent.

[If splitting, repeat per bundle with rationale for the split]
```


## Prose Quality

Apply the `/unslop` pass to the Plan's prose (summary, risks, card field
values) before presenting or persisting it; card structure is untouched.

## Saving the Plan

After approval and before any persistence, read `references/storage-and-tracker.md` completely. It owns tracker writes, fallback behavior, partial-state reporting, and revision rules.

## After Planning

After presenting the Plan, explicitly ask the human to review and approve it.
Do not begin delivery. Do NOT save the plan locally or create sub-issues
until the human approves. Say something like:

"The Plan is ready for your review. Please check it against architecture
alignment, completeness, feasibility, risk, task granularity, and delivery
bundling. Let me know if you want changes, or approve it so I can begin
delivery."

Once approved, follow the rule in "Saving the Plan" above:

1. **Tracker-path** (default when Linear is reachable): create
   sub-issues, post the Plan as a comment on the parent issue, and
   update parent issue status to "Approval". No local file is written.
2. **Fallback-path** (Linear unreachable, no tracker parent, or write
   fails): write `.spade/plans/<issue-id>-plan.md` with the fallback
   banner.

Either way, the Plan is now stored canonically and delivery can begin.

You must wait for explicit approval before proceeding to Deliver.

## Plan Revision

If the human requests changes:
1. Apply the `plan-rejected` label to the parent issue (if Linear available)
2. Revise the Plan based on their specific feedback
3. Present the revised Plan for approval again
4. Once re-approved, persist using the path rules in "Saving the Plan"
   above — tracker-path updates the Linear artefacts only (no local file
   write); fallback-path updates `.spade/plans/<issue-id>-plan.md`
5. Remove `plan-rejected` and update status to "Approval" when ready

## Closing Step — Terminal TL;DR (ALWAYS)

Every `/spade-plan` run ends with a plain-English Terminal TL;DR printed
to the human — on **both** the tracker-path (pure `linear`/`hybrid`,
Linear-canonical) and the fallback-path (`local`, or a Linear-write
failure). It is stdout, so it is never gated on a local write. Print it
**after** the Plan is saved canonically and **before** the rendering and
terminal-link step below. For a Plan, the `Ships` line names the delivery
bundles — the actual PR(s)/branch(es) that will land — plus task count
and effort, and the `Next` line points at `/spade-approve`.

The TL;DR's format, labels, voice, ordering and per-artefact rules are
defined once in `docs/FRAMEWORK.md` § Terminal TL;DR. Print the Terminal
TL;DR per that section. Do not re-specify it here.


## Rendering and terminal link

Only when a local Plan file was written, read `references/rendering.md` completely and perform its final render/link step.
