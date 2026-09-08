---
name: spade-approve
description: Present a SPADE Plan for human review against the approval checklist. Use when a Plan has been generated and needs approval, when someone says "review the plan", "check this plan", "approve", or when an issue is in "Approval" status. Also use when a human wants to see the approval checklist for a specific piece of work.
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

# SPADE Approve

You are helping a human review and approve (or reject) an AI-generated Plan.
Approval is a gate, not a rubber stamp. The biggest risk in SPADE is a weak
Approval gate.

**Contract under the Deliver autonomy level.** When `/spade` runs at the
**Deliver** level, this interactive tap is *skipped*: the orchestrator records a
**machine-attributed** auto-approval and relocates the human gate to the open PR.
A human completes Evaluate against the acceptance criteria, reviews the approach summary and diff, and confirms all required repository checks have passed, then may explicitly ask the agent to merge.
This skill remains the canonical human Approve gate for the Scope
and Plan levels and for any standalone approval; only Deliver bypasses it, and
only with machine attribution and the PR gate downstream. See `docs/FRAMEWORK.md`
§ "The Deliver level".

## The Approval Checklist

Present each check to the human with your assessment, then ask for their
decision.

### 1. Architecture Alignment

- Does the Plan conform to ARCHITECTURE.md?
- Does it use approved patterns from PATTERNS.md?
- Does it avoid everything listed in ANTI-PATTERNS.md?
- Are any new technologies, databases, or frameworks being introduced?
  If so, flag with `needs-arch-review`.

**Your assessment:** [State whether the Plan aligns with architecture docs,
and flag any concerns]

### 2. Completeness

- Are there obvious gaps or missing edge cases?
- Does the Plan cover all acceptance criteria from the Scope?
- Is error handling addressed?
- Is the testing approach sufficient for the risk level?

**Your assessment:** [State whether you see gaps]

### 3. Feasibility

- Can this actually be built this way with the project's constraints?
- Are the effort estimates realistic?
- Are the dependencies between tasks correctly identified?
- Are there external dependencies (APIs, services, access) that might block?

**Your assessment:** [State whether the approach is feasible]

### 4. Risk

- Are the AI's assumptions valid?
- Are the identified risks genuine, or are there risks not mentioned?
- What is the worst case if the Plan is wrong?
- Is there a fallback approach if the primary approach fails?

**Your assessment:** [State your risk assessment]

### 5. Scope

- Is the task breakdown at the right granularity?
- Are tasks small enough for focused delivery sessions?
- Are there tasks that should be split further?
- Are there tasks that could be combined?
- Is the split between AI-delivered and human-delivered tasks correct?

**Your assessment:** [State whether the granularity is right]

### 6. Task Cards and Delivery Shape

- Is every task one complete card - What / Done when / How / Verify /
  Needs / Blocks / Who - with no field missing and no field bloated past
  two sentences?
- Does every "Done when" state an observable result rather than an
  implementation activity?
- Does every "Verify" name the broadest reliable check rather than
  defaulting to the narrowest unit test?
- Are Needs and Blocks explicit in both directions: what the task waits
  on, and what usable outcome or later task waits on it?
- Do tasks cross the necessary layers to produce observable behavior?
- If a task is groundwork, does its "What" say so and name the vertical
  task it enables?
- Does every named technique, skill, or pattern in a card point to where
  it is defined (a FRAMEWORK.md section, PATTERNS.md, or a skill) rather
  than being explained inline?
- Would completing every task produce the Scope outcome, or could all tasks be
  marked done while an acceptance criterion remains unusable?

**Your assessment:** [State whether every card is complete and credible, or
has a justified groundwork exception]

### 7. Delivery Bundling

- Does the Plan group tasks into delivery bundles, or is it silent?
  (A silent Plan defaults to one bundle per Scope — flag that explicitly.)
- For a single-bundle plan: is that the right call given the scope size?
  Will the resulting PR be reviewable in one sitting?
- For a multi-bundle plan: is each split justified? Splits are only
  warranted when tasks share no files or symbols, have no dependency
  arrows between them, and benefit from isolated review, revert, or
  deploy timing. Otherwise the split just multiplies review burden.
- Would the reviewer prefer to see these changes as one story, or as
  several independent ones? Default to one story.
- Are the branch names and PR titles clear enough that the delivery
  phase can execute without re-deciding the bundling?

**Your assessment:** [State whether the bundling minimises reviewer
burden while keeping independently-reversible pieces separate]

## Approval Depth

Scale the review to the risk:

- **Architecture-touching work**: Deep review. Check every pattern choice,
  every new dependency, every integration point. Slow down.
- **Standard feature work**: Normal review. Verify approach and completeness.
  Check the acceptance criteria are covered.
- **Granular/low-risk tasks**: Light review. Quick sanity check that the
  approach is reasonable. Move fast.

If you are approving every plan in 30 seconds, the gate is not working.
If you are spending an hour on every trivial plan, the gate is a bottleneck.
Calibrate.

## Second Opinion

Do not offer a second-opinion prompt. Run `/spade-review` in Full Review
mode yourself, before the approval decision, when the Plan touches
architecture, security, or a cross-system boundary, or when the human asks
for one. Otherwise go straight to the decision.

When you do run it, invoke `/spade-review` in Full Review mode
(scope + plan together). After the review and cross-model synthesis,
resume here with the approval decision.

The review never blocks or replaces the approval checklist. It
supplements it with a genuinely independent perspective.

## Decision

After presenting the checklist (and the optional second-opinion step),
ask the human for the verdict using **`AskUserQuestion`** (per
`docs/FRAMEWORK.md` § "Asking the Human" — fixed-option decisions are
structured prompts, not free-form prose). The four options are:

1. **Approve** — Plan is good. Proceed to delivery.
2. **Approve with notes** — Plan is acceptable but note specific concerns
   to watch during delivery.
3. **Revise** — Plan needs changes. Specify what needs to change and why.
4. **Reject** — Fundamental approach is wrong. Go back to scoping or
   rethink the approach entirely.

When the chosen option is "Approve with notes" or "Revise", follow up
with a free-form prompt asking for the notes / feedback content — that
part is composition, not a fixed-option choice.

## After Approval

If approved:
- In `linear` or `hybrid` mode, update parent issue status to
  "Delivering" and record the approval decision as a comment on the
  parent issue. In `local` mode, record the approval in the local Scope
  file — set frontmatter `status:` to `delivering` and `updated:` to
  today's date (FRAMEWORK.md § Local Layout).
- Begin delivery of the first task

If revision requested:
- Apply `plan-rejected` label
- Revise the Plan per feedback
- Present revised Plan for approval

If rejected:
- Apply `plan-rejected` label
- Discuss whether the Scope needs revision or whether a completely
  different approach is needed
- Do not attempt to salvage the Plan if the human has rejected the
  fundamental approach
