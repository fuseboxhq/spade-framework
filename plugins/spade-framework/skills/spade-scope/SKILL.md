---
name: spade-scope
description: Create or edit a well-formed SPADE Scope with acceptance criteria, constraints, and architectural context. Use when starting new work, when someone says "I need to scope X", "create a scope", "edit this scope", "write a scope", or when work needs to begin on a new feature, fix, or investigation. Also use when someone describes work they want done but has not yet formalised it into a Scope.
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

# SPADE Scope

## Invocation by /spade

This skill may be invoked standalone or by the `/spade` orchestrator
(`docs/FRAMEWORK.md` § Autonomy Pipeline). It is a **pure authoring step**: the
autonomy picker and the trivial-routing triage live only in `/spade`. When
invoked by the orchestrator, the fast-track triage has already run — do **not**
re-present the picker or re-suggest `/spade-quick` — and any halt (a tripwire,
or an intent-changing suggestion) must surface per FRAMEWORK.md § Surfacing
channel so the orchestrator can record it in the run trace. Behaviour when
invoked directly is unchanged: the fast-track gate check below still applies.

You are helping a human create or edit a well-formed Scope for the SPADE
framework. A Scope is the contract that everything downstream is measured
against. Every field matters — a weak Scope produces a weak Plan.

> **Mandatory closing steps — do not skip.** Every run of this skill
> MUST finish with the **Terminal TL;DR** (all modes, including
> `linear`) defined in "Closing Step — Terminal TL;DR" near the end of
> this skill. When a local Scope file was written, the run MUST
> additionally finish with the render-and-link step defined in "Closing
> Step — Render and Link" — that line, when emitted, sits **below** the
> TL;DR and is the last line. The human always gets the TL;DR, plus (on
> a local write) a closing link line: either `View in browser: file://…`
> when the render succeeds, or the pandoc-not-installed hint when it does
> not. Filing the Linear issue is **not** the last step. Do not end your
> turn without the Terminal TL;DR (and, when a file was written, the
> render-and-link line beneath it).

## Check the Fast-Track Gate First

**Before you begin scoping, ask yourself: does this work genuinely need
the full loop?** If the change is a typo, a one-line tweak, a small
config nudge, a docs update, or a trivial bug fix, it may belong on the
fast-track path instead.

Walk the gate (full criteria in `AGENTS.md` → "Fast-Track Path"):

1. Single concern, ≤ 50 LoC, one file/module
2. No new dependencies, no schema changes, no architectural changes
3. No auth/crypto/permission code, no public API breakage
4. Reversible as one commit, existing tests cover the area

If every criterion passes, **stop here and suggest `/spade-quick`
instead**. Say something like: "This looks like a fast-track candidate —
it meets every gate criterion. Want me to run `/spade-quick` and skip
the full scoping flow?" Only continue with `/spade-scope` if the human
confirms or if any gate criterion fails.

When in doubt, continue with the full loop. The cost of over-scoping a
trivial change is a few minutes; the cost of fast-tracking something
that needed a real Scope is a broken audit trail.

## Conversational Style

This is an interactive, guided conversation — NOT a form to fill in.
You are a collaborative thinking partner, not a template engine.

**How to run this conversation:**

0. **Draft first.** When the human's brief already carries the intent,
   draft the complete Scope, present it, and ask one confirm through
   `request_user_input when available, otherwise a concise direct question`: *Lock this Scope* / *Edit it*. Interview only
   the fields the brief left genuinely open (FRAMEWORK.md § "Nailed").
1. **One open topic at a time.** When a field does need the human, ask
   about that one field, wait, then move on. Never dump all 10 at once.
2. **Probe when answers are vague.** If someone says "it needs to work
   reliably", push back: "What does reliable mean here — 99.9% uptime?
   Sub-second latency? No data loss? Help me make this testable."
3. **Suggest improvements.** If an acceptance criterion is weak, propose
   a stronger version: "Instead of 'data is ingested', what about
   'data appears in Elasticsearch within 5 minutes of source availability
   with zero dropped records'?"
4. **Offer options when someone is stuck.** "For out-of-scope, common
   choices here would be: X, Y, or Z. Which resonates, or is it
   something else?"
5. **Summarise and confirm before moving on.** After each field, briefly
   reflect back what you heard so the human can correct course early.
6. **Be opinionated.** If something seems too big, say so. If constraints
   are missing, flag it. You're not a stenographer — you're a sparring
   partner helping them think clearly.
7. **Read the room on ceremony.** For a quick bug fix, compress the
   conversation. For a multi-week scope, take your time. Match the
   depth of questioning to the size of the work.

**Start the conversation** by understanding what the human wants to achieve
at a high level. Ask them to describe the work in their own words first.
Then guide them through the structure.

## Modes

This skill operates in two modes:

### Create Mode (default)
When the human wants to scope new work. Start by understanding their
intent, then guide them through each required field conversationally.
Create the issue in Linear when the scope is complete and approved.

### Edit Mode
When the human references an existing issue or says "edit", "update", or
"refine" a scope. Pull the existing issue from Linear, show which required
fields are missing or weak, and walk through filling the gaps. Update the
issue when done.

To determine the mode: if the human provides a Linear issue identifier or
URL, start in Edit mode. Otherwise, start in Create mode.


## Required Fields

Before authoring or validating Scope content, read `references/required-fields.md` completely.

## Quality Checks

Before finalising, verify ALL of the following:

- [ ] Could someone start planning this without a follow-up conversation?
- [ ] Are the acceptance criteria specific and testable?
- [ ] Is this small enough to plan in a single session? (If it spans multiple
      systems, multiple teams, or multiple months, it needs breaking down.)
- [ ] Are the architectural constraints explicit (or explicitly "none")?
- [ ] Is out-of-scope clearly defined?
- [ ] Are dependencies listed (or explicitly "none")?
- [ ] Are risks acknowledged (or explicitly "none identified")?
- [ ] Does every field obey the plain-language rules in
      `references/output-format.md` (sentence caps, no jargon, outcome-first)?

If any check fails, flag it to the human and help them fix it before
creating/updating the issue.

## Scope Sizing

A Scope should be concrete enough that an AI agent can generate a plan
from it in a single session. If the Scope feels too large, help the
human break it down:

- Does it span multiple systems? Split by system boundary.
- Does it span multiple teams? Split by team responsibility.
- Does it span multiple months? Split by milestone or deliverable.
- Can you identify 3-7 discrete tasks? That is roughly the right size.

## Frontier handoff for major uncertainty

During the required-field, quality, and sizing checks, distinguish a large but splittable Scope from a destination whose consequential decisions or boundaries are still unknown.
When a meaningful human-authored destination cannot become plan-ready in this session because required fields, verifiable criteria, architecture or ownership boundaries, dependencies, feasibility, or the Scope split would require guessing, recommend `/spade-frontier`.
Do not force the fog into vague acceptance criteria, invent strategy, or file an oversized placeholder Scope.
Implementation details that a normal Plan can safely decide do not justify frontier ceremony.

Explain the exact questions that prevent Scope readiness and ask through `request_user_input when available, otherwise a concise direct question` with:

- *Start /spade-frontier*;
- *Keep refining this Scope*;
- *Cancel*.

On Start in a standalone `/spade-scope` invocation, invoke `/spade-frontier` with the human-authored destination and known context, then stop Scope authoring without creating or updating a Scope.
When invoked by `/spade`, return `frontier-handoff` instead of directly invoking `/spade-frontier`; the orchestrator performs the single frontier invocation and ends the provisional pre-Scope attempt.
On Keep refining, continue this skill but do not finalise until every normal quality check passes.
On Cancel, write nothing.

When no meaningful fog exists, continue ordinary Scope authoring and create no frontier artefact.


## Output Format

When presenting or persisting the completed Scope, read `references/output-format.md` completely.
Apply the `/unslop` pass to the Scope prose before presenting or persisting it (`docs/FRAMEWORK.md` § The unslop pass names the covered outputs).

## Decision Prompts (request_user_input when available, otherwise a concise direct question)

Scope **content** (intent, acceptance criteria, constraints, etc.) is
open-ended composition and stays free-form. But the **decisions**
this skill asks the human along the way are fixed-option choices and
must use **`request_user_input when available, otherwise a concise direct question`** (per `docs/FRAMEWORK.md` § "Asking the
Human"), not free-form prose. The decision points are:

- **Milestone selection (Horizon-bound repos only)** — the candidate
  Milestones plus *File without a Milestone (not recommended)* (see
  "Horizon Milestone Mapping" below).
- **Lock or edit (draft-first)** — *Lock this Scope* / *Edit it*.
  Locking files the Scope immediately in the resolved mode; a local
  draft is written only when the human asks for one.
- **Mode confirmation when ambiguous** — if the human's intent is
  unclear between Create and Edit modes, prompt
  *Create new Scope* / *Edit existing Scope (paste ID)*.

These are the closed-set decisions. Every other prompt — drafting
intent, acceptance criteria, constraints, out-of-scope content — is
composition and stays free-form.

## Second Opinion

Do not offer a second-opinion prompt. When `/spade` invokes this skill
the orchestrator runs `/spade-review` on the locked Scope itself.
Standalone, the human can invoke `/spade-review` directly; if they ask
for one here, run it in Scope Review mode and fold structural findings
into the Scope before filing.


## Horizon, tracker, and local storage

Before milestone selection, tracker persistence, or local file creation, read `references/storage-and-tracker.md` completely.

## Reactive Work

For small reactive items (bug fixes, config changes), the loop compresses:
- The ticket itself can serve as the Scope
- Acceptance criteria may be as simple as "the bug is fixed and verified"
- Out of Scope, Dependencies, and Risk can be brief or "N/A"
- Still require Intent and Constraints, even if brief

Do not over-engineer the Scope ceremony for small items. But do not skip
required fields entirely either. For reactive work, you may pre-fill
obvious fields and just ask the human to confirm.

## Closing Step — Terminal TL;DR (ALWAYS)

Every `/spade-scope` run ends with a plain-English Terminal TL;DR
printed to the human — in **all** modes (`linear`, `local`, `hybrid`),
because it is stdout and is never gated on a local write. Print it
**after** the structured Scope is presented and any Linear/local write
is done, and **before** the render-and-link step below. For a Scope, the
`Ships` line is the acceptance-criteria contract (no PR exists yet), and
the `Next` line points at `/spade-plan`.

The TL;DR's format, labels, voice, ordering and per-artefact rules are
defined once in `docs/FRAMEWORK.md` § Terminal TL;DR. Print the Terminal
TL;DR per that section. Do not re-specify it here.


## Local rendering

Only after writing a local Scope file, read `references/rendering.md` completely and perform its final render/link step.
