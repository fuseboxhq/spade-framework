---
name: spade-review
description: Get an independent second opinion on a SPADE Scope, Plan, both, or a delivered diff. Scope and Plan review dynamically casts evidence-backed personas. Delivery Review fixes one base/head range and runs two independent axes for Scope conformance and repository engineering standards before synthesis. Findings are advisory inputs to human-owned decisions. Use when someone says "second opinion", "outside view", "review this", "challenge this", "review the delivery", or when invoked by /spade-approve, Deliver, or Evaluate.
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

# SPADE Review — Dynamic Persona Cast, Second Opinion

## Invocation by /spade

This skill may be invoked standalone or by the `/spade` orchestrator
(`docs/FRAMEWORK.md` § Autonomy Pipeline). When invoked by the orchestrator (at
the Plan or Deliver level), it runs in Scope Review mode on the freshly-locked
Scope; a `blocking` finding — or a `major` finding the orchestrator cannot
resolve by an auto-accepted structural edit — is a tripwire that halts the
pipeline (FRAMEWORK.md § Tripwires). The review remains non-blocking by
contract; it informs the orchestrator's tripwire decision, it does not itself
gate. Behaviour when invoked directly is unchanged.

You are coordinating an independent multi-persona review of SPADE work.
The value of the review comes from **genuine independence across
distinct concerns** — each persona reviews the same structured summary
but is primed to care about a different aspect. A single generalist
reviewer collapses a review into the most obvious concern; an
independent cast of personas surfaces several distinct perspectives and
merges the findings.

You **cast the roster dynamically** for the change in front of you, the
way a workflow author fans out sub-agents to the parts that
matter. Eight **canonical** personas are your default library; you draw
the ones a given change actually needs and **invent ad-hoc personas**
when a real risk dimension has no canonical lane. The eight are a
starting library, not a fixed panel — a typical review casts only three
to five of them.

Casting is power and hazard in one. The reason a panel beats a
generalist is that it **does not let one mind pre-judge what matters** —
and your casting decision is exactly such a pre-judgment, made before
any persona has looked. So casting runs on **evidence, not default**
(see The Cast): a persona earns a seat only when the change carries a
concrete signal for its lane, and you **name that signal** in the cast
record. The cast is **3–5** — never fewer than three (a floor that stops
the review collapsing to the one obvious concern), never more than five
(a signal-ranked soft cap that stops it diluting into duplicate
findings). A lane that had a real signal but lost the cut under the cap
is **live-but-unselected** and is recorded with a reason; `security-lens`
is retained whenever the change touches any security surface. Earning a
seat by evidence is what keeps dynamism honest: it buys relevance, not
licence to skip a lane the change needed — and the casting decision is
itself validated behaviourally (see the casting corpus under
`tests/spade-review-casting/`), not just asserted.

This is a **second opinion**. It never gates approval or delivery — the
report is advisory. The human decides what to act on. Apply the
`/unslop` pass to report prose, never to the JSON envelope.

## When This Skill Is Used

Four modes depending on what context exists:

### 1. Scope Review (before planning)

Only a Scope exists; no Plan yet. The panel challenges premises,
acceptance criteria completeness, and whether the work is well-defined
enough for planning.

### 2. Plan Review (after planning)

A Plan exists and the human wants an independent technical review
before approval. The panel looks for gaps, overcomplexity, feasibility
risks, security concerns, and strategic miscalibration.

### 3. Full Review (Scope + Plan together)

Both artefacts available — the default when invoked during
`/spade-approve`. The panel reviews them as a pair.

### 4. Delivery Review (after code or artefacts exist)

A delivered diff exists.
Two isolated axes inspect the same immutable base/head range before any
synthesis: Scope and acceptance-criteria conformance, then repository
engineering-standard conformance.
This is not the dynamic persona cast used before delivery.
Its findings are inputs to `/spade-evaluate`; they do not select the final
verdict or add a SPADE phase.

## Determining the Mode

1. If the human explicitly names the mode, use it.
2. If invoked by Deliver or Evaluate after a diff exists, use **Delivery Review**.
3. If invoked during `/spade-approve`, default to **Full Review**.
4. If a delivered diff or PR exists and the human asks to review the delivery,
   use **Delivery Review**.
5. If both Scope and Plan exist in context, use
   **Full Review**.
6. If only a Scope exists (Linear issue or conversation), use
   **Scope Review**.
7. If only a Plan exists with no clear Scope, use **Plan Review**.

## Delivery Review branch

When the resolved mode is **Delivery Review**, read
`references/delivery-review.md` completely and follow it instead of the
dynamic-cast sections below.
Do not cast the persona roster, apply its floor/cap, or emit its report
envelope for this branch.

The load-bearing invariants are:

- resolve and record one exact `base_sha` and `head_sha` before review;
- give both axes the identical diff for that range;
- dispatch the axes in independent contexts and never pass one axis's findings
  into the other;
- synthesize only after both axes complete;
- invalidate the report if the delivery head changes;
- persist the full report and bound the inline findings; and
- return findings to Evaluate without selecting the human-owned verdict.

If an exact committed range or isolated-context path cannot be established,
report Delivery Review as incomplete and ineligible to support PASS.
Do not fall through to a same-context generalist review and call it independent.

## Gathering Context

Before spawning the panel, assemble a structured summary. Every persona
subagent gets the same summary — no conversation history.

### For Scope Review, gather:

- **Statement of Intent** — the what and why
- **Acceptance Criteria** — the full list
- **Architectural Constraints** — from the Scope and ARCHITECTURE.md
- **Dependencies** — what must be in place
- **Risks / Unknowns** — what the scoper flagged
- **Out of Scope** — the boundaries
- **Project context** — brief description of the project (from
  ARCHITECTURE.md or repo structure)

### For Plan Review, gather:

- **Plan content** — the full plan (tasks, approach, risks, bundles,
  delivery approach per task)
- **Project context**
- **Architecture constraints** — from ARCHITECTURE.md, PATTERNS.md,
  ANTI-PATTERNS.md (personas read these themselves if needed).

### For Full Review, gather all of the above.

If any of this context comes from Linear, fetch it via MCP. If it is in
the conversation, extract it. If a plan file exists in `.spade/plans/`,
read it.

**Truncation rule:** If the combined context exceeds 30KB, truncate the
Plan content (keeping task titles and approach summaries) rather than
dropping Scope fields. Personas need the full Scope to review
traceability.

## The Cast

You assemble the cast yourself for each review. Start from the eight
**canonical** personas — the vetted default library — then adjust for the
change in front of you, casting only the lenses the change's signals earn.

### Canonical personas — the default library

| Persona file                                    | Kind   | Focus                                                                   |
|-------------------------------------------------|--------|-------------------------------------------------------------------------|
| `spade-review-scope-guardian`                   | domain | Scope completeness, testability, Plan→Scope traceability; gold-plating / proportionality (absorbed remit) |
| `spade-review-architecture-strategist`          | domain | Conflicts with ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md         |
| `spade-review-security-lens`                    | domain | Auth, injection, secrets, supply chain, IAM, data sensitivity           |
| `spade-review-operability`                      | domain | Is the failure detectable & recoverable in production — observability, alerting, safe rollout, kill-switch, runbook |
| `spade-review-migration-reversibility`          | domain | Can a schema/data migration be rolled back without data loss — expand-contract, backfill safety, the down path |
| `spade-review-delivery-semantics`               | domain | Duplicate delivery, retries, ordering, exactly-once — is processing a message twice safe |
| `spade-review-adversarial-reviewer`             | stance | Strongest attack on the Plan — what will fail and why; second-order / compounding cost (absorbed remit) |
| `spade-review-alternatives-analyst`             | stance | Option-space survey — the road not taken. Plan/Full: a better alternative to the chosen approach. Scope: a Scope that pre-committed to a solution (reframe / buy-vs-build) |

The **domain** personas own a disjoint risk *surface* (a change either has
that surface or it does not) — so a larger library of them sharpens
coverage without dilution: each fires only on its surface. The **stance**
personas range over the *whole* change from a posture (attack it; survey
the roads not taken) — these are the personas that would dilute the merge
if multiplied, which is why the library grows only in domain lanes. See
`docs/FRAMEWORK.md` §"Stance vs domain personas".

Read the bundled `spade-review-*` definitions from canonical `src/agents/`
when developing the framework, or from the generated agent or persona-reference
projection supplied by the active host. Each file
defines the persona's focus, the severity rubric, and the output
contract. Ad-hoc personas reuse that same contract via the brief
template below. The `alternatives-analyst` carries a mode-conditional
remit defined in its brief: in Plan/Full it counters the chosen approach;
in Scope Review it fires only on a Scope that has **pre-committed to a
solution** and is silent otherwise.

### Casting the roster

Before spawning anything, run a short **triage** over the assembled
context (Scope and/or Plan). Casting is **positive**: a persona earns a
seat only by evidence, and you record the evidence. You are not deciding
which defaults to drop — you are deciding which lenses this change has
*earned*.

1. **Enumerate the risk dimensions this specific change carries.** Not
   the generic ones — the ones *this* change actually has. A webhook
   handler has a trust-boundary and an idempotency dimension; a schema
   migration has a backfill and a rollback dimension; a copy tweak has
   almost none.
2. **Cast on evidence.** For each dimension that carries a **concrete
   signal** — a touched file, an acceptance criterion, a boundary word in
   the Scope/Plan — cast the lens that owns it and **name that signal**
   in `cast[].concern`. A generic lane name with no signal behind it does
   not earn a seat. If a real dimension has **no canonical lane** — say
   "duplicate-delivery handling in a queue consumer",
   "i18n/pluralisation correctness", or "migration reversibility" — cast
   an **ad-hoc persona** for it (see below).
3. **Apply the floor and the cap (3–5).** If fewer than three lanes carry
   a signal, **fill to three** with the highest-signal canonical lanes
   (`security-lens` first — see its raised bar below). If more than five
   lanes carry a signal, **cut the lowest-signal lanes** to
   *live-but-unselected* until five remain — except `security-lens`,
   whose raised-bar retention always survives the cut.
4. **Record the cast and the notable exclusions** in the report envelope
   (`cast[]` with each seat's signal, `dropped[]` for the notable
   exclusions, `casting_rationale`). The casting decision is itself an
   audited artefact, not a private judgement — but it is **bounded**: see
   the next section for exactly which exclusions are recorded and which
   are left to the rationale.

### Cast-on-evidence, the floor, and the soft cap — the coverage discipline

Casting on evidence is what keeps a dynamic roster from collapsing back
into the generalist blind spot it exists to prevent. Three rules:

- **The floor is three.** A cast of one or two is not a panel — it is a
  generalist with extra steps. If triage genuinely finds fewer than three
  lanes with a signal, fill to three with the highest-signal canonical
  lanes rather than dropping to a rump. The floor is reached by *casting*
  the strongest remaining lanes, not by padding with empty ones.
- **The cap is a signal-ranked soft ceiling of five.** Beyond five
  personas the merge dilutes into duplicate findings, so when more than
  five lanes carry a signal you rank them by signal strength and cut the
  weakest to *live-but-unselected*. The cap is **soft** in exactly one
  way: `security-lens`'s raised-bar retention always survives the cut, so
  a security-relevant change can cast six rather than silently drop the
  security lane.
- **The audit is bounded — record the notable exclusions, not every
  absence.** A canonical lane the change *did* light but that lost the
  signal-ranked cut is **live-but-unselected**: record it in `dropped[]`
  with a one-line `reason`. `security-lens`, whenever it is not cast, is
  **always** recorded in `dropped[]` with its reason — its raised bar
  makes every security exclusion audit-worthy. Every **other** lane the
  change simply does not light is **absent**: it appears in neither
  `cast[]` nor `dropped[]`, and a notable absence may be named in
  `casting_rationale` prose. This is what bounds the envelope as the
  canonical library grows — you list what was cast and what was notably
  excluded, not a `dropped[]` entry for every lane the change never
  touched.

`security-lens` deserves a higher bar: drop it only when the change
touches **no** auth, secrets, untrusted input, network boundary, IAM, or
data sensitivity at all — and even then, record the drop (above). "This
looks like just a docs/UI change" is the exact pre-judgment that misses
an injection vector — when in doubt, keep it.

### Ad-hoc personas

When a change has a real risk dimension no canonical persona owns,
**invent a persona for it**. An ad-hoc persona is spawned through the
generic isolated-agent path (it has no registered host persona), primed by
a brief you write from this template:

```
You are reviewing a SPADE {mode} as the **{persona-name}** on an
independent multi-persona review. Your single concern is:
{one-paragraph concern definition — what this lens cares about, the
failure modes it hunts, and what is out of its lane}.

Stay strictly in this lane. Do not duplicate the scope, architecture,
security, adversarial, or alternatives lanes — another reviewer covers
each of those. Think hard and reason carefully before responding.

Severity rubric (identical to every persona):
- blocking — the change is wrong or unsafe to ship as written, within
  your lane.
- major — a real defect or gap in your lane that should be fixed before
  delivery.
- minor — a smaller concern worth noting; not a blocker.
`confidence` is a coarse `high | low` self-assessment, not a sort key.
Self-cap at three findings.

Output contract (identical to every persona): a short prose summary
first, then a JSON code block labelled `spade-findings` containing an
array of finding objects:
{"persona":"{persona-name}","severity":"blocking|major|minor",
 "confidence":"high|low","category":"<your-lane-tag>",
 "message":"one or two lines","refs":["<file>:<line>","<linear id>"]}
Emit [] if your lane is clean.
```

Give the ad-hoc persona a short, lane-descriptive `name` (kebab-case,
e.g. `idempotency-auditor`, `migration-reversibility`,
`i18n-correctness`) and a `category` tag in its own namespace so the
merge keeps it distinct (convergence is detected by concern, not by
category — see Merging). An ad-hoc persona is a **first-class member of
the cast**: it gets the same context envelope, the same parallel spawn,
and its findings merge identically. Record it in `cast[]` with
`origin: "ad-hoc"`.

Invent personas where they earn their place; do not pad the cast with
decorative ones. Each ad-hoc persona must own a dimension the canonical
eight genuinely miss for this change.


## Progressive references

- Read `references/history.md` only for review-contract history or compatibility questions.
- Read `references/convergence-example.md` only when implementing or debugging convergence merging.
- Read `references/report-contract.md` completely before constructing or persisting a Scope, Plan, or Full Review report.
- Read `references/delivery-review.md` completely for Delivery Review; it owns that branch's range, axes, report, and persistence contract.

## Spawning the Cast

**Spawn every persona in the cast you selected in parallel where the
runtime supports it; otherwise sequentially.** Parallel is a performance
nicety, not a correctness requirement — the merge logic doesn't care.

Spawn each **canonical** persona through spawn_agent with a self-contained prompt and no inherited conversation using the
generated persona definition for the active host. Spawn each **ad-hoc** persona
through the same isolated path, passing the brief you wrote from the ad-hoc
template as its prompt. Every persona, canonical or ad-hoc, gets
the same self-contained context envelope:

```
You are reviewing a SPADE {mode} as the {persona} on a multi-persona
panel. Think hard and reason carefully before responding. Follow the
output contract in your persona file exactly — prose summary first,
then a JSON code block labelled `spade-findings` with strictly
schema-matching finding objects.

PROJECT CONTEXT:
{project_context}

SCOPE:
{scope_content}                 # omit for Plan-only reviews

PLAN:
{plan_content}                  # omit for Scope-only reviews

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}      # ARCHITECTURE / PATTERNS / ANTI-PATTERNS
```

The `Think hard and reason carefully before responding` line is
intentional — each persona should use maximum reasoning effort since
the panel is meant to be the strongest independent view available.

### Scope Review mode — suppress Plan-only findings

In Scope Review the personas you cast review the Scope on its own terms.
If the `alternatives-analyst` is in the cast, it applies its **Scope-mode
remit** (fire only on a Scope that has pre-committed to a solution — see
its brief) and is silent on every other Scope.

When the `{mode}` is **Scope Review**, append this line to every
persona prompt, immediately after the output-contract sentence:

> This is a Scope Review — no Plan exists yet. Do not emit findings
> that assume a Plan: no `Task N` references, no bundle-count or
> task-count findings, no Plan-traceability findings. Review the Scope
> on its own terms — intent clarity, acceptance-criteria testability,
> premises, dependencies, and risks. (alternatives-analyst: apply your
> Scope-mode remit — fire only on a Scope that has pre-committed to a
> solution; `refs` cite Scope acceptance criteria, never a Plan task.)

The persona files are written generically and several lean Plan-oriented
in their rubric examples; this line keeps a Scope-only review from
producing findings that reference a Plan that does not exist, and steers
the analyst onto its Scope-mode remit rather than the Plan-mode "counter
the chosen approach" lens. Do not append it for Plan Review or Full
Review.

If the runtime does not support parallel Task spawns, run the cast
sequentially — canonical personas first in library order (the domain
lenses scope-guardian, architecture-strategist, security-lens,
operability, migration-reversibility, delivery-semantics, then the stance
lenses adversarial-reviewer, alternatives-analyst), then any ad-hoc
personas. Never drop a persona you
cast to save time, never collapse the cast below the floor of three —
a reduced cast slides back toward generalist — and never exceed the
signal-ranked soft cap of five except where `security-lens`'s raised-bar
retention requires a sixth seat.

### Dispatch-mode determination (v1.1.1)

Record the **dispatch mode** during spawning. It is one of exactly three
values; the banner in the report header names it verbatim so a consumer
can distinguish a real panel from a simulated one:

| Value                  | When to record                                                                                                            |
|------------------------|---------------------------------------------------------------------------------------------------------------------------|
| `subagent-dispatch`    | The runtime supports spawning subagents as **independent contexts**, and you spawned every persona in the cast **in parallel** as separate contexts. |
| `sequential-inproc`    | The runtime supports spawning personas in **isolated contexts** but only one at a time. You ran the full cast sequentially, still as separate contexts per persona. |
| `degraded`             | No isolated-context path was available and you simulated the personas by re-prompting a single model context with each persona's priming. This is a fallback, not a panel. |

Decision rules at spawn time:

1. **Try `subagent-dispatch` first.** If the runtime accepts parallel
   Task-tool invocations that land in isolated contexts, use it. This is
   the default and strongest path.
2. **Fall back to `sequential-inproc`** if parallel spawning fails or is
   unsupported but isolated per-persona contexts are still possible.
3. **Fall back to `degraded`** only when no isolated-context path is
   available. Never silently degrade — read the next section.

**Degrading is allowed, concealing that you degraded is not.** Consumers
whose audit trails cite "multi-persona review" need to be able to tell
which invocation mode produced a given report. Record the mode honestly
and emit it in the banner (see Report envelope + Presenting the Report
below). The `degraded` value is load-bearing — it tells a downstream
tool that this specific report was generated from one model wearing
multiple prompt hats (every persona in the cast), not independent
contexts.

## Collecting the Findings

Each persona returns a short prose summary followed by a JSON code
block labelled `spade-findings`. Parse each block and collect all
findings into a single list.

If a persona's JSON block is invalid (rare; LLMs occasionally emit
trailing commas), present its prose summary verbatim and note the
parse failure alongside the report. Do not attempt to auto-repair
malformed JSON — showing the human "persona X returned malformed JSON"
is more useful than risking silent data corruption.

## Merging: Convergence and Sort

The merge turns the cast's separate findings lists into one ranked
report. It has two jobs:
surface **convergence** — where independent personas landed on the same
concern — and rank what remains. The merge is roster-agnostic: canonical
and ad-hoc personas merge identically.

### Convergence: cluster by underlying concern

Read every finding across all the personas' lists and group those that
describe the **same underlying concern** — the same risk, gap, or weakness —
even when the personas filed them under different `category` values or
worded them differently. Each such group collapses to a **single
finding**: keep whichever states the concern most sharply (prefer a
`high`-confidence finding over a `low` one) and add an `also_flagged_by`
array naming the other personas that raised it.
Findings that describe **distinct concerns stay separate**, even if
their `category` or wording happens to coincide.

Convergence is the panel's strongest signal: "three independent personas
flagged this" is worth far more than any lone finding.
Detecting it is a judgement the coordinator makes by reading the
findings — not a mechanical key match.

> **Why this is a judgement, not a dedupe key.** Earlier versions
> deduped on `(category, first 100 characters of message)`. That key
> can never fire across personas: each persona file defines a
> **disjoint** `category` enum — scope-guardian emits `traceability`,
> security-lens emits `auth`, adversarial-reviewer emits
> `hidden-assumption`, alternatives-analyst emits `simpler-path`, and so
> on, with no value shared between any two personas. Two personas therefore can never produce the same key, and
> the `also_flagged_by` array was unreachable. Keep the distinction
> clear: personas using **distinct categories** is *staying in lane* —
> the deliberate design that stops the panel collapsing into four
> restatements of one concern. That is not the same as personas never
> **converging**. Two personas in different lanes routinely see the
> same underlying risk from different angles; convergence detection is
> what makes that visible.

Be conservative when clustering. If two findings are *related* but not
the *same concern* — say, a security-lens worry about an auth boundary
and an adversarial-reviewer worry about a different failure mode on the
same task — keep them separate and let both stand. A false merge hides
a finding; a missed merge only costs a convergence annotation.

### Sort

**Sort** by severity, then by convergence. Severity order:
`blocking` > `major` > `minor`. Within a severity bucket, a finding
with a longer `also_flagged_by` array — more personas independently
converged on it — comes first. `confidence` is **not** a sort key: it
is a display-only `high | low` annotation (see the persona files).
There is no `severity × confidence` arithmetic, and `nit` is no longer
a severity.

### No merge-side filter

There is no confidence filter at merge time. Under v1.1 the merge
dropped findings with `confidence` below `0.3`; `confidence` is now a
coarse `high | low` flag, not a float, and every persona already
self-caps (three primary findings for the core four — plus one
reserved-slot finding for the scope guardian and adversarial reviewer —
and at most two for the alternatives-analyst) — the filtering moved
to generation time. The merge keeps every finding each persona emits;
volume is controlled at presentation time by the tiered report (see
"Presenting the Report"), not by dropping findings here.


The detailed convergence example and report envelope/presentation contract are routed to the references above.

## Cross-Model Synthesis

After presenting the merged panel output, add your synthesis as the
coordinating agent — but keep it to what changes a decision. Show only:

- **Disagreements** — findings you think are wrong, mis-severity, or
  miss context the panel did not have (conversation history, prior
  human decisions). State what you think differently and why.
- **Tension points** — genuine conflicts for the human to resolve,
  stated neutrally rather than picking a side.

Do **not** enumerate the findings you agree with — agreement needs no
airtime. Collapse it to a single line. If there are no disagreements
and no tensions, that one line is the whole synthesis.

```
CROSS-MODEL SYNTHESIS:

Agreement: <one line — e.g. "No disagreements; I second the panel.">
Disagreements: <findings with reasoning — omit this line if none>
Tension points (for the human to resolve — omit if none):

  TENSION: <topic>
  Panel says:    X
  My view:       Y
  Context the panel didn't have: Z
```

This synthesis appears in both the inline report and the persisted
full report.

## User Decision

Invoked by another skill: return the report, no prompt. Standalone: ask via
request_user_input when available, otherwise a concise direct question:

```
The panel review is above. What would you like to do?

A) **Act on specific findings** — name which ones to address (by
   severity, persona, or message).
B) **Continue as-is** — review noted, proceed without changes.
C) **Discuss further** — work through tension points before deciding.
```

**Non-blocking.** The human can acknowledge the review and move on.
The panel never gates approval or delivery — it informs.

## Integration with /spade-approve

When invoked from `/spade-approve`:

1. `/spade-approve` presents the approval checklist with its own
   assessments.
2. Before the approval decision it invokes this skill, without an offer
   prompt, for architecture, security, or cross-system Plans or on request.
3. This skill runs in Full Review mode.
4. After the merged report and synthesis, `/spade-approve` resumes with
   the approval decision.

The panel does NOT replace any part of the approval checklist. It
supplements it.

## Completion

Review is complete only after the selected branch has presented its bounded
report, persisted the full report or surfaced the persistence failure, and
either returned it to Deliver or Evaluate or asked the standalone advisory
action question.

## What This Skill Must Never Do

- **Gate shipping.** The panel is informational. It does not have
  authority to reject a plan or block delivery.
- **Auto-apply findings.** The human decides what to act on. Never
  rewrite the Scope or Plan based on findings without explicit human
  instruction.
- **Claim "panel" or "multi-persona" in degraded output.** When
  `dispatch_mode` is `degraded`, the coordinator MUST NOT use the
  words "panel" or "multi-persona" in the report title, framing
  prose, or synthesis — those words imply independence that a
  single-context simulation did not have. Use
  `SINGLE-CONTEXT SIMULATION (degraded)` as the title and describe
  the run accurately. This is the load-bearing honesty rule the whole
  dispatch-mode machinery exists to enforce; breaking it retroactively
  falsifies every downstream audit trail that cites the report.
- **Omit the dispatch-mode banner or envelope.** Both are required on
  every invocation, even when dispatch is degraded — *especially*
  when dispatch is degraded. A report without the banner is indistinguishable
  from a pre-v1.1.1 report, and downstream tooling will misread it.
- **Suppress a blocking finding, or skip the persisted report.** Every
  `blocking` finding is shown in full in the inline report — blocking is
  never collapsed to a count line. The full report is written to
  `.spade/reviews/` on every run, `degraded` runs included. The inline
  digest tiers `major` and `minor`; it never tiers `blocking`.
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "primary agent thinks X"
  into the persona prompt defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spade-quick`).** Fast-track work is too
  small to warrant a panel review. If someone asks for a review on a
  quick-path item, suggest the full loop instead.
- **Silently collapse the cast.** Cast-on-evidence selects the lenses a
  change needs; it is not licence to shrink the review to the one obvious
  concern. Never cast fewer than three personas; reach the floor by
  casting the highest-signal remaining lanes, not by padding. Record every
  notable exclusion — a live-but-unselected (cap-cut) lane, and any
  `security-lens` drop — with a `reason` in `dropped[]`. Never drop
  `security-lens` on a change that touches auth, secrets, untrusted input,
  a network boundary, IAM, or data sensitivity. A cast below the floor of
  three, a cap-cut lane with no recorded cause, or a silently-dropped
  `security-lens` is the generalist blind spot this skill exists to
  prevent.
- **Spawn an ad-hoc persona without the standard contract.** An invented
  persona must be instantiated from the ad-hoc brief template so it
  carries the same severity rubric and `spade-findings` JSON contract as
  the canonical personas. A freeform reviewer whose output will not parse
  or merge is not a cast member — it is noise.
- **Repair malformed JSON from a persona.** Report the parse failure;
  do not guess.
