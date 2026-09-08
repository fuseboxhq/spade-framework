---
name: spade
description: Entry point for SPADE work — presents the autonomy picker (Deliver / Plan / Scope / Stub) and drives the loop from one locked Scope as far as the chosen level allows. Deliver records a fixed diff range and two-axis Delivery Review before its open-PR halt. Use when someone says "spade this", "let's scope and plan X", "take this through SPADE", "new work", or invokes `/spade`. Orchestrates existing skills rather than duplicating them and routes genuinely trivial work to /spade-quick.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using {{SPADE_SHELL}}.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies the
Linear team, project, default assignee, and the `autonomy:` block. Use these
values for all operations. If the file doesn't exist, ask the human which team
and project to use, or suggest running `/spade-onboard` first.

## Mode Resolution

Resolve the operating mode **once**, immediately after reading `.spade/config`
above — that file holds `mode:`, so reading it is part of resolution, not the
"local-file access" the contract gates — and before any *other* tracker call or
local-file access, per `docs/FRAMEWORK.md` § Mode Resolver. Do not embed the
algorithm.
The resolved mode (`linear`, `local`, `hybrid`) governs every tracker-vs-local
branch below — in particular where the run trace, auto-decision log, and halt
records are written (§ Run trace, below, and FRAMEWORK.md § Autonomy Pipeline).

## Resume validation

Read `references/continuity.md` completely before opening, writing, validating, resuming, repairing, or closing a run trace.
Before starting the ordinary picker and dispatch path for an existing Scope, locate and structurally validate its newest continuity summary.
When it names unfinished work or a human gate, suspend new-run dispatch and reconstruct it from live systems.
Validate the installed capability, current tracker status, exact Scope revision, canonical Plan and task set, approval record, halt resolution, repository identity, branch and base commit, full worktree state, current bundle or task, authoritative open or closed PR state, required checks, and verification freshness.
Run `spade-lifecycle diagnose` when it is installed.
Never trust a cached session summary, branch name, version string, or prior PR URL on its own.
If every prerequisite agrees, show the validation matrix and offer `Continue from <boundary>` or `Cancel` through `{{SPADE_ASK_USER}}`.
Persist the choice before the next mutation and preserve the recorded autonomy level and remaining tripwires.
If the selected autonomy level already reached its halt point, report the next human-owned gate without replaying completed work.
If the whole run is complete, report completion without prompting or mutation.
If live state conflicts with the run trace, classify the exact missing, malformed, unsupported, stale, contradictory, or dirty-worktree condition and use the fail-closed recovery contract before planning or delivery.
Offer repair only for one evidence-proven metadata correction and require human confirmation of its preview.
Changed Scope, Plan, approval, branch contents, or delivery range always restarts from the last valid human-owned boundary.
Never stash, reset, clean, delete, overwrite, switch branches, or infer ownership of dirty changes.

# SPADE Orchestrator

You are the entry point for a piece of SPADE work. Your job is to take the
human from a raw intent to the furthest point the chosen **autonomy level**
allows — concentrating their attention at the Scope and automating everything
downstream — while halting the moment a genuine decision (a *tripwire*)
appears.

The autonomy model — the four levels, the tripwires, the structure-vs-intent
line, the "nailed" done-condition, the trivial-routing triage, the run-trace
and auto-decision log, and the surfacing channel — is single-sourced in
`docs/FRAMEWORK.md` § Autonomy Pipeline. **Read that section before running.**
This skill is the operator of that spec; it does not restate it.

## What this skill subsumes (and what it does not)

`/spade` is an **orchestrator**, not a new phase. It calls the existing skills
and owns only the picker, the tripwire evaluation, and the run/decision log:

- It **subsumes the entry decision** that used to be a bare `/spade-scope`
  call: instead of always authoring a full Scope, it first runs the
  trivial-routing triage and then dispatches by autonomy level.
- It **orchestrates, never duplicates** `/spade-scope`, `/spade-review`,
  `/spade-plan`, and `/spade-quick`. Each of those still works when invoked
  directly; `/spade` simply calls them in sequence.
- It is **orthogonal to `/spade-approve`**: at the Plan level `/spade` halts
  *before* delivery, exactly where the human Approve gate sits.
  `/spade` auto-approves only at the live Deliver level and does not replace `/spade-approve` elsewhere.
- It is **orthogonal to `/spade-quick`**: `/spade` routes trivial work *to*
  `/spade-quick`; it never does fast-track work itself.

## Checkpoint persistence

At every run-trace stage boundary and every change to the current bundle, task, branch, PR, verification, halt, or next action, write and verify one complete `spade-run-state/v1` successor per `references/continuity.md`.
Do not advance to the next stage until the checkpoint is durably readable through the resolved mode's canonical path.
For new work that has no stable Scope identity yet, keep the provisional run id in-session and flush `run:start` with the first complete summary immediately after the Scope artefact is created.
For existing work, structurally load the current summary before writing any successor.

## Step 1 — Resolve the autonomy level

Resolve which level runs, in this precedence (FRAMEWORK.md § The autonomy
picker):

1. **Per-invocation flag.** If the human passed a level as an argument
   (`--deliver`, `--plan`, `--scope`, `--stub`, or a bare `deliver|plan|scope|stub`),
   use it.
2. **Config default.** Else, if `.spade/config` has `autonomy.default` set to a
   valid level, use it.
3. **The picker.** Else, present the single-select picker via
   `{{SPADE_ASK_USER}}` — exactly four options, in this fixed order, one
   selection:
   - **Deliver** — scope → review → plan → code → PR → optional CodeRabbit → fixed-range Delivery Review → Evaluate → halt under the `human` merge policy, or merge on green under `on-green`
   - **Plan** — scope → review → plan → halt before delivery
   - **Scope** — write the Scope → halt
   - **Stub** — title + one-line placeholder → halt

**Deliver is live.** When Deliver is resolved, run the Deliver dispatch in
Step 3 — it writes code, opens a PR, runs optional CodeRabbit plus core
fixed-range Delivery Review, records Evaluate when every criterion is
machine-verifiable, and then halts or merges by `autonomy.deliver.merge`, per
FRAMEWORK.md § "The Deliver level" and § Ship. Most repos set
`autonomy.default: deliver`; the picker is the fallback.

Open the **run trace** now: record `level:<chosen>` and `run:start` on the
work's canonical artefact with the first complete continuity summary when the
Scope identity exists (FRAMEWORK.md § Run trace and auto-decision log).

## Step 2 — Trivial-routing triage (skip for Stub)

Before authoring anything, walk the fast-track gate in AGENTS.md →
"Fast-Track Path (Small Work)". If **every** criterion passes, the work is
trivial: record `triage:fast-track` in the run trace, hand off to
`/spade-quick`, and stop — `/spade` is done. If any criterion fails, record
`triage:full-loop` and continue. When in doubt, do not fast-track.

(Stub skips the triage — it is an explicit "capture for later" and authors no
Scope.)

## Step 3 — Dispatch by level

In all non-Stub levels, scope authoring grills until the Scope is **nailed**
(FRAMEWORK.md § "Nailed") — independent of the level. Auto-accept structural
suggestions; never rewrite intent (FRAMEWORK.md § Auto-accept). Log each
auto-decision with its reasoning.

If `/spade-scope` returns `frontier-handoff`, invoke `/spade-frontier` and stop the selected autonomy pipeline after that one frontier invocation.
The handoff occurs before a stable Scope exists, so keep only the provisional in-session run id and do not persist `spade-run-state/v1`, a phase event, or an auto-approval.
Frontier is not an autonomy level or SPADE phase, and the original provisional attempt is not resumed after graduation.
Each graduated Scope starts a separate future `/spade` invocation with its own stable identity and selected autonomy level.

- **Stub.** Create the work item with a title and a one-line placeholder
  description only (todo-style). In `linear`/`hybrid` mode this is a Linear
  issue in the project; in `local` mode a stub Scope file. No interview, no
  acceptance criteria, no review, no plan. Record `stub:done` and stop.

- **Scope.** Invoke `/spade-scope` to author a full, nailed Scope, then halt.
  Record `scope:start` / `scope:done`.

- **Plan.** Invoke `/spade-scope` (record `scope:*`), then `/spade-review` on
  the Scope (record `review:*`), then — if no tripwire fired — `/spade-plan`
  (record `plan:*`). Halt at the Approve gate; do **not** create sub-issues or
  deliver beyond what `/spade-plan` does. The human approves the Plan.

- **Deliver.** Run Plan's chain first — `/spade-scope` (record `scope:*`),
  `/spade-review` (record `review:*`), and, if no tripwire fired, `/spade-plan`
  (record `plan:*`). Then, instead of halting at the Approve gate,
  **auto-approve and continue** per FRAMEWORK.md § "The Deliver level":
  0. **Arm the guard.** Through `{{SPADE_SHELL}}`, check whether
     `.spade/guard/$CLAUDE_CODE_SESSION_ID/live` exists and record
     `guards:live` or `guards:absent` in the run trace. Write `deliver` to
     `.spade/guard/$CLAUDE_CODE_SESSION_ID/mode`; remove that file at every
     exit of this run (halt, abort, or merge). Without the live marker the
     previous model applies: full tripwire #6 and human merge
     (FRAMEWORK.md § Mechanical guards). A guard deny at any later step is a
     halt: record it, surface the reason, and stop. Do not retry the denied
     write through another tool or mode. The marker comes off only in the
     single close step that follows the halt record.
  1. Record a **machine-attributed auto-approval** in the auto-decision log
     (findings count, AC coverage, architecture-conflict result). It covers the
     Plan tap only and is not, on its own, merge authorization.
  2. **Fix the delivery base.** Before changing the bundle, resolve one exact
     full `base_sha` from the hosted PR base, the recorded bundle base, or the
     intended target branch merge base. Record the SHA and resolution source in
     the run trace as `delivery:base`.
  3. **Write the code** for the current delivery bundle. As the diff takes shape,
     evaluate **tripwire #6** against FRAMEWORK.md § Security-sensitive path
     surface. With guards live, halt and surface only for secrets and
     credentials, production data, or permission widening, and record every
     other touched category for the PR body's **Protected paths** section.
     Without guards live, halt and surface on any touched category.
  4. Check the **per-project PR cap** (`autonomy.deliver.max_open_prs`, default
     3): if the project is already at the cap, halt-and-surface; do not open
     another auto-PR.
  5. **Open a PR** whose body leads with the **approach summary** (intent; forks
     considered-and-rejected, with the reason each lost; the auto-decisions)
     followed by a **Protected paths** section naming every security-sensitive
     category the diff touches, or `none`, so the human signs off on the
     approach, not just the diff. Apply the `/unslop` pass to the PR title and
     body first. Record `pr:opened`.
  6. Run **one CodeRabbit cycle** (§ "CodeRabbit is optional and degrades").
     Absent means record `review:coderabbit:absent`.
     Unresponsive past the bounded wait means stop waiting and record
     `review:coderabbit:timeout`.
     Either degradation continues only through the core Delivery Review before
     the ordinary human-review halt; it never skips core review.
     Auto-apply only **mechanical** allowlist findings; anything outside it **fails closed** (leave it on the PR). Record `review:*`.
  7. **Run project-native checks and core Delivery Review.** After every
     permitted fix is committed, resolve the final full `head_sha`, run the
     required repository checks, and invoke `/spade-review` in Delivery Review
     mode. Both independent axes use the recorded `base_sha` and the same final
     `head_sha`. Record `delivery:review:start`, the report path, range, axis
     completion, pass eligibility, and `delivery:review:done` in the run trace.
     A degraded or incomplete review remains visible and cannot support PASS.
     At each completed task or bundle verification boundary and after Delivery
     Review synthesis, apply `/spade-learn`'s candidate gate to the bounded
     delivery evidence. Record `candidate:none` without prompting when no
     failed assumption, recurring pitfall, new project constraint, reusable
     pattern, or correction exists. When one exists, invoke `/spade-learn`'s
     candidate branch and require Public-safe, Private, or Skip before any
     learning write. Persist only the content-free outcome in continuity state.
  8. **Record Evaluate.** Invoke `/spade-evaluate` against the reviewed head.
     When every criterion row is diff-verifiable or runtime-verifiable with
     fresh evidence and both review axes completed, record the verdict in the
     run trace (`evaluate:pass`, `evaluate:partial`, or `evaluate:fail`) and on
     the issue; `/spade-evaluate` writes `.spade/guard/reviewed-head-<pr>` as
     `<head_sha> <verdict>` only for an agent-recorded verdict. If any row is
     external-state, human-only, or open, record `evaluate:human` and halt for
     the human's verdict.
  9. **Halt or merge by policy.** Read `autonomy.deliver.merge` from
     `.spade/config`. Under `human`, when the key is absent, or when guards are
     not live: Record `run:halt:deliver` and stop by default. The human
     operates the merge (without guards live they may explicitly ask the agent
     to, once required checks are green).
     Under `on-green` with guards live and a recorded `evaluate:pass`:
     re-resolve the head; if it differs from the reviewed `head_sha`, mark the
     review, the verdict, and head-bound evidence stale, then rerun both review
     axes, required commands, and `/spade-evaluate` on the new head first. Then
     verify required checks are green, run
     `gh pr merge <pr> --match-head-commit <head_sha>`, and record `pr:merged`.
     The guard checks the same facts and a deny is a halt: record it, surface
     its reason, and record `run:halt:deliver`.
     The close step removes the `mode` marker on every exit, after the halt or
     merge is recorded.
  Poll the **kill signal** (`.spade/abort` or `autonomy.deliver.abort`) at every
  stage boundary; on abort, record `run:aborted` and stop.

## Step 4 — Tripwires

At each stage, evaluate the tripwires in FRAMEWORK.md § Tripwires (strategic
fork; blocking/high review finding; architecture conflict; non-verifiable AC;
plan exceeds `autonomy.size_ceiling`; and — in Deliver only — a
**security-sensitive path** in the diff). An **intent-changing suggestion**
counts as a strategic-fork tripwire.
The security-path classification uses the complete canonical surface in
FRAMEWORK.md § Security-sensitive path surface and fails closed on an
unclassifiable path. With guards live only secrets and credentials, production
data, and permission widening halt before code; the rest go in the PR's
Protected paths section. The halt has no agent-side override.

On a tripwire: **halt and surface** through both channels (FRAMEWORK.md
§ Surfacing channel) — the in-session `{{SPADE_ASK_USER}}` prompt AND a durable
`HALTED:` record on the canonical artefact (a Linear comment in
`linear`/`hybrid`; the run-trace file in `local`). Record which tripwire fired
and why. Then wait for the human; do not proceed past a halt on your own.

Absent a tripwire, proceed without prompting. This is the point of the
pipeline: many questions to *understand* the Scope up front, few *decisions*
pushed at the human downstream.

## Step 5 — Close

When the chosen level reaches its halt point, record `run:halt:<level>` in the
run trace and print a Terminal TL;DR per `docs/FRAMEWORK.md` § Terminal TL;DR:
what was done, what the artefact's contract is, and the next step (`/spade-plan`
after Scope; `/spade-approve` / delivery after Plan). The sub-skills emit their
own TL;DRs; add one orchestrator-level line naming the autonomy level and the
halt point so the human knows exactly where the pipeline stopped and why.

## What this skill must never do

- **Merge outside the policy.** Under `autonomy.deliver.merge: human` the
  human operates the merge; under `on-green` Evaluate recorded PASS on the
  current head, required checks are green, and the merge command is pinned to
  that head before `gh pr merge` runs. The Plan auto-approval alone is not
  merge authorization.
- **Disarm or route around a mechanical guard.** A deny is a halt to surface
  (FRAMEWORK.md § Mechanical guards). Only a human may disarm one, and the run
  trace records it.
- **Auto-approve outside Deliver.** Only the Deliver level auto-approves, and
  only the Plan-approval tap (machine-attributed, not merge authorization). The Scope
  and Plan levels halt at the human Approve gate.
- **Rewrite human-authored intent.** An intent change halts and surfaces; it is
  never auto-accepted.
- **Proceed past a tripwire silently**, or surface a halt only as an
  in-session prompt (a silent halt). Always also write the durable record.
- **Duplicate a sub-skill's logic** or re-specify the autonomy mechanisms —
  reference `docs/FRAMEWORK.md` § Autonomy Pipeline.
- **Lower the "nailed" bar for a high autonomy level.** Deliver grills as hard
  as Scope.
- **Treat frontier discovery as a phase or splice it into run-state history.**
  A frontier handoff ends the provisional pre-Scope attempt, and normal runs begin only from graduated Scope identities.
