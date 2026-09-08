# The SPADE Framework

## A Human-AI Operating Model for Engineering Teams

This is the full reference document for the SPADE Framework. For quick-start
usage, see README.md. For agent enforcement rules, see AGENTS.md.

---

## Why This Exists

The way we build software is shifting. AI agents can now read codebases,
generate plans, write code, run tests, and manage project boards, but they
cannot decide what to build, and they should not ship without human verification.

SPADE is our framework for structuring this. It defines clear boundaries between
what humans own and what AI handles, creating a loop that is fast, auditable,
and safe.

**The core principle:** Humans own the edges (intent and verification). AI owns
the middle (planning and execution).

### Where Scopes Come From

Scopes do not appear from nowhere. They are derived from OKRs and roadmap
priorities through a collaborative process between leadership and the team.
The flow is:

1. OKRs and roadmap set the strategic direction for the quarter.
2. Leadership and the team collaboratively break those down into concrete,
   actionable Scopes.
3. A Scope should be specific enough that someone could start work on it
   without needing a follow-up conversation to clarify intent.

A bad Scope: "We need to do threat intel."
A good Scope: "Ingest Telegram messages on a regular basis into the TI stack."

The first is a strategic direction. The second is something someone can plan
against and deliver.

### What Makes a Good Milestone

A milestone is not a time-boxed container and it is not a task. It is an outcome
derived from an OKR. You look at your OKRs for the quarter and ask: what needs
to be true for this to be on track? Each answer is a milestone.

The shift from traditional project management is subtle but important. A task
describes activity: "Build the ETL pipeline." A milestone describes a verifiable
outcome: "Device telemetry is flowing into the intelligence platform and
available for analysis." The first tells you what to do. The second tells you
what done looks like.

Good milestones share a few properties: they are verifiable (you can demonstrate
whether the outcome has been achieved), they are meaningful (achieving them
materially advances the OKR), and they decompose cleanly into Scopes (you can
look at a milestone and identify the concrete pieces of work needed to get there).

### How Work Gets Picked Up

The default expectation is that team members operate with autonomy: understand
the priorities, pull work, and drive it forward. Not everyone operates the same
way though. Some people thrive with high autonomy and minimal direction. Others
need clearer sequencing, more explicit assignment, and tighter check-in points.
The framework accommodates both.

What matters is that the Scope is clear enough for either type of person to act
on it. Whether someone pulls work independently or receives a more explicitly
assigned Scope with closer check-ins, the expectation is the same: the person
who picks it up owns the outcome, not just the execution. The assignment model
might differ, but the accountability model does not.

The goal is ownership, not task assignment. But ownership requires the work to
be visible and the expectations to be unambiguous.

### Reactive and Unplanned Work

Not all Scopes originate from OKRs. Tickets, incidents, vulnerability reports,
and ad-hoc requests are a normal part of any security team's workload. SPADE
handles these the same way it handles planned work, but the loop runs at a pace
proportional to the size and urgency of the task.

For small reactive items (a bug fix, a configuration change, a quick
investigation), the loop compresses. The ticket itself is the Scope. Planning
might be a single AI-generated comment proposing an approach. Approval is a
quick check. Delivery and evaluation happen in the same session. The structure
is the same; the ceremony is lighter.

For larger reactive work (an incident requiring coordinated response, a
vulnerability investigation spanning multiple systems), the work gets a proper
parent issue in Linear, scoped with acceptance criteria just like any planned
work. It enters the active cycle and runs through the full SPADE loop.

What matters is that all work, planned or reactive, has a clear Scope and a
visible owner. The origin of the work is less important than the clarity of what
needs to happen and how you know it is done.

### Key-Person Risk

If the collaborative scoping process only exists in conversations, it creates a
single point of failure. Scopes should be written down and visible (in Linear,
or wherever the team tracks work) so that priorities are clear even if the
person who defined them is unavailable. This is not about bureaucracy. It is
about making sure the team can keep moving without depending on any one
individual being in the room.

---

## Frontier Discovery

`/spade-frontier` is the governed path for a meaningful destination whose consequential decisions, dependencies, or boundaries prevent a normal Scope from becoming plan-ready in one session.
It sits before Scope authoring and is not a sixth SPADE phase, an autonomy level, or an exception to Scope, Approve, Deliver, or Evaluate ownership.

The human supplies the destination and why it matters.
The skill may structure questions, recommend evidence paths, run read-only research, and conduct bounded disposable prototypes.
It never decides business strategy, produces implementation code, or turns discovery into approved delivery.

### The frontier map

The durable `spade-frontier/v1` map is a bounded index rather than a narrative dossier.
It records:

- the destination;
- decisions already made;
- precise open questions and their dependencies;
- one research, prototype, human-decision, or prerequisite path per question;
- AI or human ownership;
- unresolved fog and explicit out-of-scope boundaries;
- the currently visible frontier; and
- canonical decision, evidence, and graduated Scope pointers.

Each decision and evidence record has one canonical location.
The index links to it instead of copying its body into multiple comments, documents, or Scopes.
Readers load the index first and expand only the active question and its direct dependencies.

One invocation either exits to normal Scope authoring when no meaningful fog exists, creates the initial map without resolving an open question, or resolves at most one currently visible question and updates the frontier.
Graduation is the bounded postcondition of resolving the final material question, not a separate batch invocation.

### Resolution boundary

Research reuses `/spade-research` for one isolated read-only question and records only a human-confirmed concise answer and real source links.
A prototype is allowed only when it is disposable, isolated outside the destination repository, uses no production data or credentials, mutates no shared state, and leaves only evidence.
A human decision is persisted only after explicit human selection and attribution.

Any durable or reusable artefact, repository or external-state mutation, production-data operation, schema or configuration change, or potentially shippable output is a prerequisite rather than discovery.
It is linked or routed through a normal SPADE Scope and blocks the frontier question until authoritative completion evidence exists.

### Persistence and authority

Linear uses one marked Frontier issue as the canonical index and one immutable canonical resolution comment per decided question.
Local mode uses `.spade/frontiers/<slug>/index.md` plus immutable `.spade/frontiers/<slug>/decisions/<question-id>.md` records.
Hybrid mode writes Linear first and mirrors only the index and canonical pointers locally, not decision or evidence bodies.
All modes preserve the same logical states, owners, paths, blockers, one-question limit, and graduation rules.

### Graduation into the loop

Graduation requires every material question resolved or explicitly removed by the human, no unresolved fog, authoritative prerequisite evidence, and one or more Scope candidates that each pass the existing required-field, verifiability, architecture, and sizing checks.
The human confirms every Scope's intent, boundaries, consequential decisions, and filing through `/spade-scope`.
The map then records the canonical Scope links and dependency order, and each Scope links back to the decision index without copying it.

Frontier does not participate in `spade-run-state/v1` because no stable Scope identity exists yet.
The map is its own lightweight resumable discovery record.
After graduation, each Scope begins an independent ordinary `/spade` run with its own stable identity and the unchanged five-phase vocabulary.

The detailed schema, write ordering, failure behavior, and graduation checks live in `/spade-frontier`'s progressively disclosed `references/map-contract.md`.

## The Loop

```
SCOPE --> PLAN --> APPROVE --> DELIVER --> EVALUATE
 (H)       (AI)      (H*)      (AI/H)       (H*)
              ^                    |
              |                    |
              +---- Rework <-------+
```

`*` Approve and Evaluate are human gates on the Plan and Scope autonomy levels.
On the Deliver level with mechanical guards live they are machine-recorded and
human-reviewable at the PR (§ Mechanical guards, § The Deliver level).
Done follows the Evaluate verdict and is recorded by whoever recorded it.
Ship stays human, expressed through `autonomy.deliver.merge`.

### Scope (Human)

The engineer defines what needs to be achieved and why it matters. This is not
a task description. It is a statement of intent with clear acceptance criteria
and constraints.

A good Scope answers:
- What does success look like?
- What are the acceptance criteria?
- What architectural constraints apply? (tech stack, patterns, security requirements)
- What does this connect to upstream and downstream?

A Scope is not an Initiative or an OKR. It should be concrete enough that an AI
agent (or a human) can generate a plan from it in a single session. If you find
yourself writing a Scope that spans multiple systems, multiple teams, or multiple
months, it is probably too big. Break it down.

The Scope is the contract. Everything downstream is measured against it.

### Plan (AI)

The AI agent takes the Scope and produces a structured plan: what to build, how
to build it, what to build it with, and in what order. The Plan is broken into
3-7 discrete tasks, each scoped tightly enough that an AI agent (or human) can
pick it up and deliver it in a focused session.

The Plan also includes:
- Technical approach and rationale
- Dependencies between tasks
- Risk callouts (what might go wrong, what assumptions are being made)
- Which tasks should be AI-delivered vs human-delivered
- Testing and verification approach: for software tasks, what tests are expected
  (unit, integration, E2E) and what passing looks like. For non-software tasks,
  what evidence demonstrates completion.

The Plan is a first-class artefact, not something that happens invisibly. It
gets documented and attached to the parent issue in Linear (as a comment or
Linear doc) so the team can see the reasoning, not just the output. This
behaviour is enforced through AGENTS.md which instructs AI agents to document
their plans and attach them to the relevant issue automatically.

### Approve (Human)

The engineer reviews the AI-generated Plan against reality. This is a gate,
not a rubber stamp.

Approval checks:
- Architecture alignment: Does this conform to our established patterns and
  tech stack?
- Completeness: Are there obvious gaps or missing edge cases?
- Feasibility: Can this actually be built this way with our constraints?
- Risk: Is the AI making assumptions that need to be validated?
- Scope: Is the task breakdown at the right granularity?

If the Plan does not pass Approval, it goes back to the AI with specific
feedback. Rejection is not failure. It is the framework working.

The biggest risk in SPADE is a weak Approval gate. A bad plan that gets rubber-
stamped leads to confidently wrong execution. If you are approving every plan
in 30 seconds, the gate is not working. On the Deliver level the gate relocates
to the PR approach summary, and the same scrutiny belongs there.

### Deliver (AI or Human)

The tasks from the Plan get executed. Some by AI agents, some by humans.

AI-delivered tasks are things like: writing code, building API endpoints,
creating data pipelines, generating configuration, writing tests, producing
documentation, and managing project boards.

Human-delivered tasks are things like: stakeholder conversations, hardware
testing, vendor negotiations, security reviews requiring physical access,
relationship-building, and anything requiring organisational context that AI
cannot access.

The framework does not pretend everything is AI-deliverable. It embraces the
mix and is explicit about who does what.

### Evaluate (Agent-Recorded When Fully Verifiable)

After delivery, the engineer verifies the output against the original Scope.
This is distinct from the Approval stage. It is output validation, not approach
validation.

Evaluate consumes the current fixed-range Delivery Review and records one
acceptance-evidence matrix row for every Scope criterion.
Each row is classified as `diff-verifiable`, `runtime-verifiable`,
`external-state`, or `human-only`.
Runtime and UI evidence is fresh and tied to the final reviewed head.
External and human-only rows remain open until their authoritative evidence is
available.
Any open row forces `pass_eligible: false`, regardless of the agent's recommended verdict.

The agent runs project-native checks, gathers evidence, and derives PASS,
PARTIAL, or FAIL from both independent review axes and the complete matrix.
When every row is diff-verifiable or runtime-verifiable with fresh evidence on
the reviewed head, the agent records that verdict itself.
Any external-state or human-only row, or any open row, hands the verdict to the
human.
Whoever records a PASS also moves the issue to Done; a PARTIAL, a FAIL, or an
open row leaves it in Evaluating.
Ship stays human, expressed through `autonomy.deliver.merge`.
No review or evidence substep adds a SPADE phase.

Evaluation checks:

- Does every acceptance criterion have current criterion-specific evidence?
- Does the output actually work at the highest practical seam?
- Are external or human-only claims still explicitly open?
- Did either Delivery Review axis find a quality, architecture, security, edge,
  or regression defect?
- Would the human be comfortable shipping this exact reviewed head?

If evaluation fails, work goes back, either to Deliver (minor fixes) or to Plan
(fundamental approach was wrong).

### Ship (Human-Owned, Merge By Policy)

The human owns the decision to release verified work and sets the merge policy in `.spade/config`.
`autonomy.deliver.merge: human` (the default) means the human operates the merge; with guards live the agent's merge command is denied outright, and without guards live the human may still ask the agent to merge once required checks are green.
`autonomy.deliver.merge: on-green` lets the agent merge a PR whose recorded verdict is PASS on the current head, whose required checks are green, and whose merge command is pinned to that head; on the Claude host `bin/spade-guard` enforces exactly those conditions (§ Mechanical guards).
A merge instruction or policy authorizes only the merge; deployment and handoff actions require their own explicit authorization.

---

## Autonomy Pipeline

The loop above describes *who owns each phase*. The **autonomy pipeline**
describes *how far a single piece of work travels in one invocation, and how
much it interrupts the human on the way*. It is driven by the `/spade`
orchestrator skill — the recommended entry point for new work. The pipeline
never removes a phase or a human gate; it decides, per invocation, which gates
run unattended and which halt for a person.

The governing principle: **human attention concentrates at the Scope; autonomy
governs only what happens downstream of a locked Scope.** The scope-authoring
interview is deliberately high-interaction — it grills — regardless of the
chosen autonomy level. Everything after a locked Scope flows by default and
stops only on a *tripwire*.

### The autonomy picker

On every `/spade` invocation the orchestrator presents a single-select picker —
one choice, most-autonomous first:

| Level | Travels | Halts |
|-------|---------|-------|
| **Deliver** | Scope → review → plan → code → open PR → optional CodeRabbit → project-native checks → fixed-range two-axis Delivery Review → Evaluate | before merge under the `human` merge policy or when guards are not live; merges on green under `on-green` (§ Ship) |
| **Plan** | Scope → review → plan | before delivery |
| **Scope** | Scope authoring only | after the Scope is written |
| **Stub** | a title + one-line placeholder (todo-style) | immediately |

The order is fixed: **Deliver, Plan, Scope, Stub**. The picker is presented
through the `AskUserQuestion` convention (§ Asking the Human) and must be
answerable in a single selection. Resolution order for which level runs is
**per-invocation flag > `.spade/config` `autonomy:` default > the interactive
picker**: a flag wins; absent a flag, a configured default is used; absent
both, the picker is shown. `/spade-onboard` writes `autonomy.default: deliver`,
so the picker is the fallback, not the norm.

> **Status (v2.0):** all four levels are live. The Deliver level's mechanics —
> machine-attributed auto-approval, the never-merge invariant, the PR approach
> summary, the security-path tripwire, the per-project PR cap, the kill-switch,
> and CodeRabbit handling — are specified in § "The Deliver level" below.

### Tripwires — when autonomy halts and surfaces

Between a locked Scope and the pipeline's halt point the orchestrator proceeds
**without prompting** unless it hits a tripwire. A tripwire halts the run and
surfaces to the human (§ Surfacing channel). The five tripwires:

1. **Strategic fork.** Two or more genuinely viable paths exist whose
   trade-offs differ materially (cost, reversibility, architecture, or
   user-visible behaviour) and the Scope does not already decide between them.
   *Detection criterion:* the orchestrator can name at least two concrete
   options AND cannot pick one from the Scope's stated intent and constraints
   alone. A choice with an obvious default under the Scope is **not** a fork —
   pick it, record the reasoning, and do not halt.
2. **Blocking or high-severity review finding.** `/spade-review` returns any
   `blocking` finding, or a `major` finding the orchestrator cannot resolve by
   an auto-accepted structural edit.
3. **Architecture conflict.** The Scope or Plan conflicts with
   `ARCHITECTURE.md`, `ANTI-PATTERNS.md`, or a constraint the Scope itself
   states.
4. **Non-verifiable acceptance criterion.** Any acceptance criterion cannot be
   checked mechanically or by a named piece of evidence.
5. **Plan exceeds the size ceiling.** The Plan exceeds the named constant
   `autonomy.size_ceiling` in `.spade/config` (default: **7 tasks or 12 changed
   files**, whichever is hit first). A larger plan halts for human eyes even
   when nothing else trips.
6. **Security-sensitive path.** *(Deliver only — the level that writes a diff.)*
   The planned or actual diff touches the enumerable, fail-closed
   **Security-sensitive path surface** defined below.
   With mechanical guards live (§ Mechanical guards), Deliver halts before code
   only for secrets and credentials, production data, and permission widening;
   every other touched category is named under **Protected paths** in the PR
   body so the human reviews it there. When guards are not live, any touched
   category halts before code, as before.

Tripwires are prose the orchestrator reasons over — **not** an enforcement
script (PATTERNS "Prose over code"). When in doubt whether something is a fork
or a conflict, halt: a false halt costs one interaction; a missed one costs an
unattended wrong turn.

### Auto-accept: structure yes, intent never

Downstream of a locked Scope the orchestrator **auto-accepts its own
suggestions to scope *structure*** and never rewrites human-authored *intent*.
The line is operational, not a vibe:

- **Structure** (auto-accept): acceptance-criteria wording, additional edge
  cases, constraints, the test outline, task breakdown, risk phrasing —
  anything that changes *how the work is expressed or organised* without
  changing *what outcome is pursued or why*.
- **Intent** (never auto-rewrite): the statement of intent — the problem being
  solved and why it matters. A suggestion that changes the outcome, the
  problem, the target user, or the "why" is an **intent change**, and is itself
  a strategic-fork tripwire: halt and surface it for the human to author.

Worked examples:

| Suggestion | Class | Action |
|------------|-------|--------|
| "Tighten AC 3 from 'works reliably' to 'p99 < 200ms, zero dropped records'." | structure | auto-accept |
| "Add an edge case for the empty-input path." | structure | auto-accept |
| "Split task 2 into ingest + validate." | structure | auto-accept |
| "This would be more valuable as a streaming pipeline than a batch one." | intent | halt — surfaces as a fork |
| "Drop the offline-support requirement to ship faster." | intent | halt — changes the outcome |

This honours the rule INTENT.md states for the project's durable intent: the
human composes intent; the skill structures and probes but never authors it.

### "Nailed" — when scope authoring is done

The scope-authoring interview grills until the Scope is **nailed**, defined
operationally as: every required Scope field (§ Scope) is populated, and **every
acceptance criterion is individually verifiable** (mechanically checkable or
backed by a named piece of evidence). A high autonomy level never lowers this
bar — Deliver grills exactly as hard as Scope. **Stub is the sole exemption:**
it deliberately captures only a title and a one-line placeholder and runs no
interview.

The interview is **draft-first**. When the human's brief already carries the
intent, draft the complete Scope, show it, and ask one confirm (lock or edit)
rather than interviewing field by field. Probe only the fields the brief left
genuinely open. The bar is the same; only the number of turns changes.

### Trivial-routing triage

Before authoring a full Scope the orchestrator runs the **fast-track gate**
(AGENTS.md → "Fast-Track Path (Small Work)"). If every criterion passes, the
work is trivial: route it to `/spade-quick` instead of the full loop —
regardless of the autonomy level selected — and the PR description is the audit
artefact (no Scope, no sub-issues). If any criterion fails, continue with the
chosen autonomy level. The picker chooses *how far* non-trivial work travels;
the triage chooses *whether the work is non-trivial at all*. When in doubt, do
not fast-track — use the full loop.

### Run trace and auto-decision log

Because the pipeline runs unattended it must leave a trail a human can
reconstruct. The orchestrator records, on the work's canonical artefact (the
Linear issue in `linear`/`hybrid` mode; the local `.spade/` artefact in
`local` mode):

- **Run trace** — an incremental, timestamped line as each stage is entered and
  exited (`scope:start`, `scope:done`, `review:start`, …). A stage entered but
  never exited is a stall; without the trace, an unattended run that hangs looks
  identical to one still working.
- **Auto-decision log** — for every decision made without asking (an
  auto-accepted structural edit, a fork resolved by an obvious default, a
  tripwire that did *not* fire), a one-line record with its reasoning. An
  **auto-approval** entry additionally records: the review findings count, the
  acceptance-criteria coverage, and the architecture-conflict check result.

The log is the orchestrator's account of its own decisions — an aid to human
reconstruction, not a substitute for the human gate the chosen autonomy level
preserves.

**A known blind spot.** The log records decisions *made*, not recognitions
*missed*. An orchestrator that never recognised a tripwire cannot log its
non-firing, so a clean log is evidence of the decisions taken — **not** proof
the run was safe. This is exactly why the self-graded tripwires carry two
*independent* checks: the PR approach-summary gate (§ "The Deliver level"),
where a human signs off on the approach and not just the diff; and the
**live-halt recall test** (`tests/spade-autonomy/`), which scores whether a full
unattended run *actually halts* on seeded must-fire cases rather than whether a
primed reader would classify them.

### Run continuity state

Every new run checkpoint also records one complete versioned state summary using the logical schema `spade-run-state/v1`.
The summary exists so an interrupted invocation can be reconstructed without replaying completed stages or relying on conversation history.
It complements the timestamped run trace and auto-decision log and does not replace either one.

Every summary records a unique state id, its prior-state link, one stable run id, the Scope identity and authoritative revision, autonomy level, current phase, ordered completed checkpoints, current bundle or task, repository and branch, full base and head commits when applicable, PR reference and recorded state, last verification evidence and freshness, halt reason, next allowed action, and UTC recording time.
Every field is present even when its value is `none`.
The detailed field order, value rules, persistence shapes, and structural checks live in `/spade`'s progressively disclosed `references/continuity.md` contract.

The summary is a claim about what the orchestrator recorded, not proof that the Scope, approval, repository, branch, commit, worktree, PR, check, or external action still exists.
`/spade` must validate those claims against authoritative live systems before it offers continuation.
Unknown schema versions, missing fields, broken prior-state chains, sibling successors, unsafe content, or contradictions fail loudly.

Persistence is logically equivalent across modes:

- In `linear` mode, each checkpoint appends one immutable complete snapshot comment and retains older comments as history.
- In `local` mode, `.spade/runs/<scope-key>.md` contains one replaceable delimited current-summary block plus idempotent append-only event records.
- In `hybrid` mode, the tracker write is canonical and happens first, then the same logical state is mirrored locally best-effort.

For one Linear checkpoint, its state id and event id are stable idempotency keys across retries.
Identical duplicate snapshot comments are benign under newest-well-formed-wins selection, while reused identifiers with different content fail as a contradiction.
After a timed-out write, read the tracker for those identifiers before retrying; retry only when they are absent, and reuse the same identifiers rather than creating a competing successor.

Local summary replacement follows the project's idempotent marker pattern.
Missing, mismatched, nested, or duplicate markers cause a no-write failure.
An event id is appended at most once.

Historical traces without `spade-run-state/v1` remain readable audit history but are never upgraded or resumed by inference.
The bounded options are restart under the installed contract or cancel.
SPADE stores no transcript, credential, cookie, token, authentication state, or full learning draft in the continuity summary.

#### Resume validation and safe boundary

On invocation for a Scope with unfinished continuity state, `/spade` suspends new-run dispatch and validates reality before it offers continuation.
It reads the installed capability, tracker status, exact Scope revision, canonical Plan and tasks, approval and halt resolution, repository and full commit range, complete worktree state, current bundle or task, authoritative PR state and checks, and verification freshness.
Recorded names, URLs, statuses, summaries, and prior command results are references only.

When every prerequisite agrees, `/spade` shows the validation evidence and offers the human exactly `Continue from <boundary>` or `Cancel`.
The chosen autonomy level and remaining tripwires continue unchanged.
An incomplete `*:start` stage is rerun rather than declared complete.
Already-completed stages and external actions are never replayed.

When live state proves the selected level already reached its halt point, `/spade` reports the next human-owned gate.
When live state proves the whole run complete, it reports completion without a continuation prompt or mutation.
Any contradiction enters the bounded recovery contract and cannot be waived by the trace itself.

#### Fail-closed recovery

A failed resume check is classified as missing, malformed, unsupported, stale, contradictory, or dirty-worktree state and names the exact recorded value, live observation, and authoritative source.
The bounded choices are evidence-proven repair when eligible, restart from the last still-valid boundary, or cancel.

Repair is eligible only when one authoritative live read proves one exact correction to non-authoritative metadata.
The human sees and confirms the old value, new value, source, and required revalidation before a superseding snapshot is written.
Scope intent or criteria, Plan content or tasks, approval, branch contents, commit range, verification results, and ambiguous external references are never repaired in place.

A changed Scope restarts Scope or Plan and invalidates downstream approval.
A changed Plan or task set restarts approval.
Missing or stale approval returns to the Approve gate.
A missing branch or invalid range restarts the affected delivery boundary without inventing or deleting a branch.
A changed head invalidates required checks and both Delivery Review axes.

Dirty worktrees are read completely and preserved.
Continuation is offered only when every changed path and behavior agrees with the recorded branch, base, bundle, and task, and the human explicitly confirms ownership.
Otherwise `/spade` offers inspect, restart without deleting changes, or cancel.
It never stashes, resets, cleans, deletes, overwrites, switches branches, discards conflicts, or guesses ownership.

### Surfacing channel

A halt — from a tripwire or an intent change — must reach a human who, by the
pipeline's own premise, is not watching the terminal. The orchestrator surfaces
a halt through **both**:

1. the in-session prompt (`AskUserQuestion`), for a human who *is* present; and
2. a durable record on the canonical artefact — in `linear`/`hybrid` mode, a
   comment on the issue (and, where the workflow uses it, a state change the
   human is notified on); in `local` mode, the run-trace file plus a clearly
   marked `HALTED:` entry.

A halt that exists only as an unanswered terminal prompt is a **silent halt**
and is not acceptable: if the in-session prompt cannot be answered, the durable
record is what carries the halt to the human.

### Security-sensitive path surface

This is the single canonical path and purpose taxonomy for every SPADE workflow
that must identify security-sensitive work.
Classify the complete current and proposed path inventory together with each
path's declared purpose against all categories below.
The surface is enumerable and fails closed: any path that cannot be confidently
classified as outside every category is protected.
There is no override, allowlist escape, or workflow-specific relaxation.

1. **Authentication and identity.**
   Auth, authentication, authorisation, session, identity, and login boundaries.
2. **Secrets and credentials.**
   Secrets, credentials, tokens, environment-secret material, private keys,
   certificates, and key stores.
3. **Cryptography.**
   Encryption, decryption, signing, verification, hashing used as a security
   control, and key management.
4. **Permissions and IAM.**
   Access control, roles, policies, RBAC, permission grants,
   `.claude/settings.local.json`, and any permission widening.
5. **Schemas.**
   Application, database, event, API, and infrastructure schemas whose change
   affects persisted or trusted structure.
6. **Migrations and backfills.**
   Schema migrations, data migrations, backfills, and lifecycle migration
   definitions.
7. **Production data.**
   Paths or commands that read, write, transform, export, delete, or repair
   production data.
8. **CI.**
   Workflow definitions, CI scripts, runner permissions, and CI credential or
   execution configuration.
9. **Release.**
   Version authority, release manifests, changelogs used by release tooling,
   release provenance, and publication configuration.
10. **Deploy.**
    Deployment scripts, deployment configuration, rollout controls, and
    production environment definitions.
11. **Infrastructure.**
    Infrastructure-as-code, cloud resource definitions, network and platform
    policy, and privileged operational configuration.
12. **Kubernetes.**
    Manifests, operators, admission policy, RBAC, namespaces, and cluster
    configuration.
13. **Helm.**
    Charts, templates, values that affect deployed resources, and release hooks.
14. **Framework governance, execution, and fetch surfaces.**
    Consumer framework-marker regions; `docs/FRAMEWORK.md`; root governing
    files including `AGENTS.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`, and
    `INTENT.md`; canonical and generated skill contracts; `src/CAPABILITIES.md`;
    `setup`; `setup.ps1`; `bin/**`; lifecycle and release manifests; anything
    changing what `spade-update-check` fetches; and the `.spade/config`
    `handoff` block plus `.spade/handoff.local`.

The first four categories and the explicit framework surfaces preserve the
v3.2.1 Deliver set for auth, secrets, crypto, permissions, permission widening,
consumer markers, setup and fetch execution, governing docs and skills, and
handoff autonomy configuration.
The remaining categories extend that set without narrowing it.

### Unhinged experiments

`/spade-unhinged` is an explicitly invoked release valve for one concrete,
confirmed, disposable experiment that is not approved to land or ship.
It is appropriate for a proof of concept, spike, learning experiment, or
throwaway script whose output is expected to be discarded or rewritten.

It is not an autonomy level, SPADE phase, quick-path substitute, delivery
route, merge path, or permission bypass.
The `/spade` picker remains exactly Deliver, Plan, Scope, Stub and never selects
Unhinged automatically.

The routing boundary is intent:

- if the user intends to keep the change and it passes every quick criterion,
  use `/spade-quick`;
- if the user intends to keep non-trivial work, use a normal Scope and full
  loop;
- if the destination is meaningful but consequentially foggy, use
  `/spade-frontier`; and
- use Unhinged only for one explicitly confirmed throwaway experiment.

Entry uses bounded read-only Git commands to show the branch and complete
tracked, staged, unstaged, untracked, and proposed path inventory.
Every current and proposed path is classified by path and declared purpose
against § Security-sensitive path surface.
A protected or unclassifiable path refuses before mutation with no override.
A safe primary branch or safe dirty worktree requires an explicit Continue or
Cancel decision after all evidence is shown, and every existing byte is
preserved.

The complete gate reruns immediately before the first mutation, before the
first write to every newly proposed path, before commit, and before Draft PR
creation.
The experiment stops before any new protected or unknown path.
Ordinary destructive confirmations, sandbox and permission limits, worktree
ownership, and Git discipline remain active throughout.

Unhinged creates no Scope, Plan, approval, tracker item, run-state record, or
learning.
Uncommitted and unshared throwaway work may exit without an audit PR after its
verification is reported.
Committed, retained, or shared work requires a dedicated
`spade-unhinged/<slug>` branch and a Draft PR titled
`[unhinged] <confirmed intent>`.

The Draft body records the intent, non-shipping boundary, entry briefing,
initial branch and worktree state, every path check, complete changed-path
inventory, destructive confirmations, verification, exit state, and the exact
statement `not approved for merge`.
Unhinged leaves it Draft and provides no ready or merge operation.
It is experimentation evidence, not Scope, Plan, Approval, Evaluate, merge
authorisation, Done, or Ship.

To preserve work for landing, close the Draft PR, verify its authoritative
closed state, prove the retained work is unchanged, and re-enter
`/spade-quick` or the full loop under their ordinary gates.
The human continues to own Ship, and Evaluate and Done follow the recorded verdict.

### Mechanical guards

Most of SPADE is prose the agent reasons over.
A few invariants do not need reasoning, only checking, and for those the Claude host runs command hooks driven by one bash helper, `bin/spade-guard`.
A guard is a deterministic check over the tool call's input plus explicitly named local state: a marker file, a key in `.spade/config`, or the PR's own check status read from `gh`.
It never classifies purpose, weighs a trade-off, or reads the conversation; anything that needs judgement stays in skill prose.

| Guard | Fires on | Denies when |
|---|---|---|
| Protected path | `Edit`, `Write`, `MultiEdit`, `NotebookEdit` | `.spade/guard/<session_id>/mode` exists. In `quick` or `unhinged` mode any path matching the fourteen categories denies. In `deliver` mode only secrets and credentials, production data, and permission widening deny, where permission widening covers `.spade/config`, `.spade/handoff.local`, `.claude/settings*.json`, `hooks/hooks.json`, `bin/spade-guard`, and any path whose declared purpose grants or widens a permission. |
| Merge policy | `Bash` running `gh pr merge`, `glab mr merge`, or a `gh api` merge | `autonomy.deliver.merge` is `human` or absent (the human operates the merge). Under `on-green`, denies unless the PR is not a draft, is mergeable, has at least one check with every check SUCCESS or SKIPPED, `.spade/guard/reviewed-head-<pr>` reads `<head sha> PASS` for the current head, and the command pins that head with `--match-head-commit` and a literal SHA. `glab` is not verified and denies under `on-green`. |
| Stage all | `Bash` running `git add -A`, `--all`, or `.` | `guards.deny_stage_all: true`. Off by default. |

Every guard is inert unless the project root holds `.spade/config`, so a plugin install changes nothing in repositories that do not use SPADE.
`jq` is the only dependency; when it is missing inside a SPADE repository the guard blocks the call and names the missing tool.

**Markers.** `SessionStart` writes `.spade/guard/<session_id>/live`; `SessionEnd` removes the session directory.
`/spade` Deliver, `/spade-quick`, and `/spade-unhinged` write `.spade/guard/<session_id>/mode` at start and remove it at close, using `CLAUDE_CODE_SESSION_ID` from the shell environment.
Evaluate writes `.spade/guard/reviewed-head-<pr>` as `<head sha> <verdict>` only when it records a verdict itself on the exact head both axes reviewed; a newer head or a non-PASS verdict rewrites it and the merge guard denies until a fresh PASS exists.
Guards protect path edits and the merge; they do not stop a shell command from deleting a marker, which is why a missing marker means "guards inert", never "allowed".
A guard cannot know what a command substitution will expand to, so a check that needs a literal value, such as the merge head pin, fails rather than trusting one.
`.spade/guard/` is gitignored.

**Guards live or not.** A skill treats guards as live when `.spade/guard/<session_id>/live` exists for its session.
Only then does the lighter approval model apply: the narrowed tripwire #6, the agent-recorded Evaluate verdict, and merge under `on-green`.
Without the marker (Codex, a Claude session without the hooks registered, or a repository without `.spade/config`) the previous model applies unchanged: fourteen-category pre-code halt and human merge.

**A deny is a halt.** When a guard denies, the agent surfaces the reason to the human through the ordinary surfacing channel and waits.
It does not remove a marker, edit the guard, edit the config, or reach the same effect through another tool.
A human may disarm a guard for one run; the run trace records that as a human-authorised bypass.

**What the guards are not.** They are not a sandbox.
An agent that ignores the deny reason can still reach a file through a shell command; the guards catch the ordinary tool path and turn a forgotten rule into a deterministic stop.
Path patterns approximate the fourteen categories; purpose classification stays in prose, and quick and unhinged fail closed on a match.

**How a path is matched.** The guard splits a path into words at every non-alphanumeric character and matches whole words, not substrings.
`access-token.ts` matches the term `token`; `tokenizer.ts` does not, and neither does `processor.ts` match `sso` nor `oracle.ts` match `acl`.
A few terms match as a word prefix, so `migrat` covers migration and migrations, and a name is split at each camelCase boundary and where an acronym runs into a word, so `accessToken.ts` and `SSHKeyLoader.ts` both classify.
`key` on its own is an ordinary database and storage word, so it reads as a credential only beside a credential-specific one such as `api`, `private`, or `ssh`; `primaryKey.ts`, `rootKeys.ts`, and a `service` layer holding `translationKeys.ts` are left alone, while `apiKey.ts` is not and a service-account file is named directly.
Well-known credential files that carry no category word at all, such as `id_rsa`, `authorized_keys`, `.npmrc`, `.netrc`, and `kubeconfig`, are named directly.
The trade is deliberate: a term glued into one lowercase word, such as `mytoken.ts`, is missed, and prose still governs what the guard cannot see.

**The framework's own layout is not a consumer's.** `src/`, `skills/`, `agents/`, `plugins/`, `fragments/`, `hooks/`, `bin/`, `setup`, and the generated host trees are framework governance surfaces only inside this repository, detected by `src/CAPABILITIES.md` and `src/skills/` both existing.
In a consumer repository `src/` is application code, so that category covers only `AGENTS.md`, `CLAUDE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`, `INTENT.md`, `docs/FRAMEWORK.md`, and the `.spade/` control files.
Without that split the fast paths would refuse to touch ordinary application code.

**Where they ship.** The Claude plugin carries `hooks/hooks.json` and `scripts/spade-guard`.
This repository registers the same hooks in `.claude/settings.json`.
A clone install gets `~/.spade/bin/spade-guard` but registers no hooks; to opt in, copy the three entries from `src/hooks/hooks.json` into `~/.claude/settings.json` with the command `~/.spade/bin/spade-guard`.
Codex has no hook surface and keeps prose-only enforcement; `src/CAPABILITIES.md` records the asymmetry.

**Two homes, one lint.** Changing a guarded rule means changing the prose here and the check in `bin/spade-guard`.
`tests/hooks/guards.sh` fixes the check's behaviour and `tests/spade-autonomy/approval-model-contract.sh` fixes the prose, so a change to one without the other fails CI.

### The Deliver level

Deliver is the one level that writes code and opens a PR. It extends Plan:
after `/spade-plan` produces the Plan, Deliver continues through a fixed delivery
base, code, an open PR, one optional CodeRabbit cycle, project-native checks,
and a two-axis Delivery Review before it **halts before merge unless explicitly
authorized**. Everything
the lower levels do (grill the Scope until nailed, the tripwires, the
auto-accept line, the run trace and surfacing) applies unchanged; the rules
below are what Deliver *adds*. Every one of them is **prose the orchestrator
reasons over** (PATTERNS "Prose over code"); a numeric cap or a diff bound is a
judgement the orchestrator makes, not a counter it runs. The one exception is
the small set of deterministic invariants that § Mechanical guards moves into
`bin/spade-guard`; those are checks, not judgement.

**Machine-attributed auto-approval.** Deliver does not stop at the human Approve
gate. It records a **machine-attributed auto-approval** in the auto-decision log
and continues. The approval is attributed to the orchestrator, not a human, and
is scoped **strictly to the Plan-approval tap** — it does not authorize the merge.
The gate is not deleted; it **relocates to the PR** (below).
The governing docs (AGENTS.md, ANTI-PATTERNS.md) are amended in the same change
so this is a sanctioned step, not a silent contradiction of "Approval is a STOP
gate".

**Merge by policy.** Deliver **opens** a PR, runs project-native checks and the two-axis Delivery Review, and records the Evaluate verdict when every criterion is machine-verifiable (§ Evaluate).
What happens next follows `autonomy.deliver.merge` (§ Ship): under `human` Deliver halts and the human operates the merge; under `on-green`, with guards live, Deliver merges once Evaluate recorded PASS on the current head, required checks are green, and the merge command is pinned to that head. Any later commit invalidates the recorded verdict as well as the review, so Evaluate reruns before merge.
The Plan auto-approval on its own is not merge authorization; the policy, the recorded verdict, and the guard together are.
Changing the policy is itself a permission-widening edit that the deliver-mode guard blocks, so only a human can loosen it.

**The PR carries a human-signed approach summary.** Because the gate moved from
a pre-code "is this the right approach?" to a post-code PR, the PR body must
lead with an **approach summary**: the intent it serves, the forks it
**considered and rejected** (with the reason each lost), and the auto-decisions
it made. The human signs off on the *approach*, not only the diff — this is what
keeps the relocated gate able to catch a strategic-fork or intent-change miss
that a finished diff would hide.

**Delivery uses one fixed review range.** Before the bundle changes, Deliver
resolves and records one exact `base_sha` plus its source.
After code, project-native checks, and every permitted review fix are committed,
it resolves one final `head_sha`.
The core Delivery Review compares exactly `base_sha..head_sha`.
Hosted PRs use their resolved base and head commits; recorded bundles use their
recorded base; committed local branches use the intended target's merge base.
Branch names and cached summaries are never range evidence.
An uncommitted working tree produces only provisional review and cannot support
PASS.

**Delivery Review runs two independent axes.** `/spade-review` Delivery Review
mode dispatches Scope and acceptance-criteria conformance independently from
repository engineering-standard conformance.
Both axes receive the same range and diff but never receive each other's
findings before synthesis.
The first axis catches missing or unusable Scope behavior.
The second catches architecture, pattern, quality, security, dependency, and
native-check defects even when every acceptance criterion passes.
The bounded report is persisted and its findings feed Evaluate.
This is review inside Deliver and Evaluate, not a new SPADE phase.

**A changed head invalidates review and command evidence.** Deliver records the
reviewed head in the run trace.
Any later commit marks the Delivery Review and head-bound command results stale.
Both review axes and every required command must rerun against the new head
before PASS or merge can be supported.

**Tripwire #6 - the security-sensitive path surface.**
Without guards live, Deliver halts and surfaces before code when its planned or actual diff
touches any category in § Security-sensitive path surface.
With guards live (§ Mechanical guards), it halts before code only for secrets and credentials, production data, and permission widening, and lists every other touched category under **Protected paths** in the PR body.
It evaluates paths and declared purpose against the complete canonical surface
and fails closed on an unclassifiable path.
The halt has no agent-side override; a human answers it.

**Bounded CodeRabbit auto-apply — fail closed.** Deliver runs exactly **one**
CodeRabbit cycle and auto-applies only **mechanical** findings, by allowlist: a
small, local edit to existing code that changes the behaviour the finding names,
with no scope expansion. It **must not** auto-apply a finding that adds a new
file, edits a dependency manifest or a permission file, or edits **any
security-sensitive path (above) or an existing execution-surface /
agent-behaviour file** (`setup`, `bin/**`, a SKILL/AGENTS file). Anything
outside the allowlist **fails closed** — the finding is left for the human on the
PR, not applied. Classification uses § Security-sensitive path surface and is
the orchestrator's prose judgement; when
unsure, do not apply.

**Per-project open-PR cap.** Deliver refuses to open a new auto-PR when the
project already has `autonomy.deliver.max_open_prs` (default **3**) open
Deliver-authored PRs. The cap is **per project**, read from that project's
`.spade/config`. Over-limit behaviour is **halt-and-surface**, never a silent
skip: Deliver stops and tells the human to clear the backlog. The count comes
from the tracker where available; in `local`/no-tracker mode, from the run
trace's record of opened-and-not-yet-merged PRs. A fleet-wide budget *across*
projects is out of scope here (a Wingman concern).

**Kill-switch.** An in-flight Deliver run is abortable. The orchestrator polls a
**kill signal** — the presence of a `.spade/abort` file, or
`autonomy.deliver.abort: true` in `.spade/config` — at **every run-trace stage
boundary** (`*:start` / `*:done`). On seeing it, Deliver stops before the next
stage, records `run:aborted`, and leaves the work in place. For a run **hung
mid-stage** (a boundary never reached — e.g. a wedged CodeRabbit wait), the
recourse is to kill the agent process; the run trace's last `*:start` with no
matching `*:done` names the wedged stage, and the operator then reconstructs or
cleans up the half-done run by hand (a branch written but no PR; a PR opened but
the cycle incomplete) — the trace states exactly how far it got.

**CodeRabbit is optional and degrades.** CodeRabbit is a third-party service, not
a hard dependency; Deliver in a repo without it still functions. Degradation is
defined for both failure shapes: **absent** (not configured / not installed)
means skip that cycle and record `review:coderabbit:absent`;
**present-but-unresponsive** means stop after a maximum total wait of **10 minutes** and record
`review:coderabbit:timeout`.
Either path still runs project-native checks and the core fixed-range Delivery
Review before halting for human review.
A consumer is never forced to adopt CodeRabbit, and CodeRabbit never substitutes
for either core review axis.

---

## Plan Schema

Every Plan produced by `/spade-plan` must conform to a documented schema so
downstream skills (delivery, review, evaluation) can consume it
deterministically. Consumers read Plans; drift in the schema breaks them.

### Required fields

Per Plan:

- Scope reference (issue ID or link)
- Technical approach summary (2-3 sentences)
- Risks and assumptions
- Delivery sequence
- Delivery bundles (default: one; see `/spade-plan` for split rules)

Per task, one strict **card** — fixed field set, fixed order, every field
present on every task, each field one sentence (two at most when the task
genuinely needs it):

- **What** — the change, named concretely: the files, components, or
  behaviour touched. A deliberately preparatory task says so here
  ("groundwork - enables Task N").
- **Done when** — the observable result that proves the task works.
- **How** — the approach in plain words, opening with the delivery
  approach (vocabulary below). Named techniques, skills, patterns, or
  languages are pointers to where they are defined, never inline essays.
- **Verify** — the tests, command, or evidence that confirms "Done when".
- **Needs / Blocks** — the task numbers this waits on, and the task
  numbers or external/human hand-offs waiting on this (`none` when empty).
- **Who** — `AI` or `human`, plus effort: brief, moderate, or significant.

Scopes are written for humans; Plans are written for the agent that
delivers them. The card is the whole task — a delivering agent should
never need a follow-up conversation to know what to build, how to
approach it, or when it is done.

### Observable outcomes and vertical slices

Plans default to vertical slices.
Each task crosses the layers needed to make one behavior observable to a user,
operator, caller, or downstream system.
A task organised only around a layer, file type, schema, scaffold, or specialist
hand-off is incomplete unless that horizontal shape is genuinely required.

The card enforces this through three fields:

1. **Done when** names the observable result rather than the
   implementation activity.
2. **Verify** names the broadest reliable place the result is checked,
   such as a public API, integration boundary, browser workflow, or
   operational probe.
3. **Needs / Blocks** names what the task depends on, what later task or
   usable outcome waits on it, and any external or human hand-off.
   Write `none` only when there is genuinely nothing.

An intentionally horizontal or preparatory task is marked as
**groundwork** in its What field, naming the later vertical task it
enables, and still carries a real "Done when" so completion is
observable.
Typical justified cases are a destructive migration prerequisite, shared test
oracle, or final release projection that must move atomically.
Groundwork is an exception record, not a label added to every task.

### Delivery approaches

The delivery approach opens a card's **How** field: it declares how the
task will be tackled, not what it builds. The approach propagates from
Plan to delivery: `/spade-plan` emits it, and delivery skills (or
humans) honour it when picking up the task.

Vocabulary (locked; extensions require a new Scope):

| Approach                | When to choose                                                                                                     | Typical signal                                                                                          |
|-------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `test-first`            | The desired behaviour is well-specified and you want failing tests to drive implementation.                        | New features with clear acceptance criteria; protocol/contract work.                                    |
| `characterization-first`| You are fixing a bug or refactoring existing code and need to pin down current behaviour *before* changing it.     | Bug fixes on code without adequate tests; pre-refactor safety nets.                                     |
| `refactor-first`        | Touching the area is only viable after a preparatory refactor; the new behaviour follows the cleanup.              | Code you cannot cleanly extend without first reshaping it.                                              |
| `spike`                 | The correct approach is genuinely unknown; the task's output is learning, not shippable code.                      | New technology evaluation; hard-to-estimate architectural choices.                                      |
| `straight-through`      | The change is mechanical enough that test-first / characterization-first ceremony adds no value.                   | Typo fixes, config bumps, docs edits, one-liners covered by existing tests.                             |

There is no silent default. Every card's How opens with an approach. If
`straight-through` is chosen, the How must state *why* — typically "covered
by existing tests" or "mechanical change". This avoids the failure mode
where the approach becomes a rubber-stamp word.

A task may combine approaches when the work naturally splits (for
example, `characterization-first` on the existing module; `test-first` on
the new behaviour). Write it in one line inside How.

### Storage (v1.2.0+)

The canonical store for an approved Plan is the **tracker** (today:
Linear) — posted as a comment on the parent issue, with sub-issues
created for each Plan task. When the tracker is unavailable, the Scope
has no parent issue, or the Linear write fails, `/spade-plan` falls
back to a local file in the consumer repo and marks it with a fallback
banner. The filename is `.spade/plans/<issue-id>-plan.md` when the
Scope has a tracker identifier (e.g. `M-420-plan.md`), and
`.spade/plans/<scope-slug>-plan.md` when there is no parent issue at
all — the slug is a short kebab-case derivation from the Scope title
(e.g. `ingest-telegram-messages-plan.md`). Either way the file uses
the same frontmatter schema, so historical archives and v1.2+
fallbacks are interchangeable on the read path.

The same `.spade/plans/` path also preserves **historical archives**
written under v1.0–v1.1, when the framework defaulted to a dual-write.
v1.2.0 is non-destructive: existing archives are never deleted, moved,
or rewritten. Read-path skills (`/spade-evaluate` in particular) read
the tracker first and fall back to `.spade/plans/` if the tracker
cannot supply the Plan, so historical archives remain reachable
indefinitely.

The behaviour gate is "did the tracker accept the Plan", not merely
"is MCP present" — see `/spade-plan` § "Saving the Plan" for the
precise rule.

---

## Why SPADE Works

### It matches how AI agents actually perform

AI is excellent at planning (exploring solution spaces, breaking down problems,
identifying approaches) and delivery (writing code, following patterns, producing
output). AI is poor at deciding what matters to the business and verifying that
output works in the real world. SPADE puts AI where it is strong and humans where
AI is weak.

### It creates an audit trail

Every piece of work has: a human-written Scope (the "what"), an AI-generated
Plan (the "how"), an Approval decision (the "approved by"), delivery records
(the "done"), and an Evaluation (the "verified"). You can trace any delivered
work back through the full chain.

This matters for two specific reasons. First, AI-delivered work can easily become
opaque. Without a recorded plan, developers end up unable to explain what
frameworks, patterns, or architectural decisions went into the output. The audit
trail ensures that every piece of delivered work has a visible reasoning chain,
not just a result. Second, when something breaks in production, you need to trace
back through scope, plan, approval, and delivery to understand what went wrong
and where. Without that chain, debugging AI-delivered work is guesswork.

This is not overhead because it is automated. AGENTS.md instructs AI agents to
document plans and attach them to issues as part of the standard workflow.
Nobody is writing audit logs manually.

### It scales fractally (within limits)

The same SPADE loop works at every level of tactical and implementation scope:

- Tactical: "Build the ETL pipeline" -> AI plans the sub-tasks -> Human
  approves -> AI writes code -> Human evaluates
- Granular: "Implement schema validation" -> AI plans the approach -> Quick
  approval -> AI writes the function -> Human checks

The Approval gate gets lighter as scope gets smaller and risk gets lower.

At the strategic level, SPADE does not apply in the same way. Strategy requires
free-form thinking about business problems, customer needs, and market context.
AI can assist with research, analysis, and structuring options, but it should not
be planning your strategy for you. The output of strategic thinking feeds into
SPADE as Scopes and Milestones, but the thinking itself is human-owned.

### It prevents the two failure modes of AI-assisted work

Failure mode 1: Humans doing everything manually. Without a framework, teams use
AI as a fancy autocomplete, asking it to write individual functions but still
doing all the planning, structuring, and project management manually. SPADE
pushes planning and delivery to AI, freeing humans for judgement.

Failure mode 2: AI doing everything unsupervised. Without a framework, teams hand
AI an open-ended goal and hope for the best. The output might be technically
functional but architecturally wrong, insecure, or solving the wrong problem.
SPADE's Approve and Evaluate gates prevent this.

---

## Tooling: How It Works in Practice

SPADE is a pattern, not a product integration. The framework works regardless of
which tools you use to implement it. What follows describes our current tooling
choices, but if the tools change, the pattern holds. What matters is the human-AI
handoff loop, not the specific products.

### Linear as the System of Record

We use Linear to manage the full SPADE lifecycle. The hierarchy maps naturally:

```
Milestone (outcome derived from OKRs)
  +-- Parent Issue (SCOPE, human-written)
        |-- Sub-issue 1 (AI-planned task, AI-delivered)
        |-- Sub-issue 2 (AI-planned task, human-delivered)
        |-- Sub-issue 3 (AI-planned task, AI-delivered)
        +-- Plan Document (attached as comment or Linear doc)
```

The parent issue is the Scope. Written by a human. It contains the acceptance
criteria, constraints, and architectural context. This is the contract.

The sub-issues are the AI-generated Plan, broken into deliverable tasks. Each
sub-issue is small enough that an AI agent can complete it in a focused session.

The workflow tracks SPADE phases on the parent issue:

| Status      | Phase | Who is Active                                    |
|-------------|-------|--------------------------------------------------|
| Scoped      | S     | Human has defined the scope and acceptance criteria |
| Planning    | P     | AI is generating plan and sub-issues               |
| Approval    | A     | Human is reviewing the approach                    |
| Delivering  | D     | Sub-issues being worked (AI or human)              |
| Evaluating  | E     | Human validating against acceptance criteria       |
| Done        | ✓     | Shipped and verified                               |

Sub-issues use a simpler workflow: Todo -> In Progress -> Done

Labels indicate execution mode:

| Label              | Meaning                                    |
|--------------------|--------------------------------------------|
| ai-planned         | Plan was generated by AI                   |
| ai-delivered       | Task was completed by an AI agent          |
| human-delivery     | Task requires human hands                  |
| plan-rejected      | Plan was reviewed and sent back            |
| needs-arch-review  | Touches architecture, needs senior review  |

### Horizon Roadmap Binding

Some projects' Linear instance is fronted by **Horizon** — an internal
roadmap board that shows work as **Now / Next / Later** lines grouped into
**Themes**. Horizon is a planning lens over Linear: it reads Linear one-way
and never writes back. The join between the two is the **Milestone**.

A **Horizon board Item maps 1:1 to a Linear Milestone.** That makes the
Milestone the roadmap anchor, and it fixes how Scopes attach to the roadmap:

```
Horizon board Item  ──1:1──▶  Linear Milestone
                                   +-- Scope (parent issue)   ← milestoned
                                   +-- Scope (parent issue)   ← milestoned
                                         |-- Sub-issue (Plan task)  ← NOT milestoned
                                         +-- Sub-issue (Plan task)  ← NOT milestoned
```

The contract has two halves, and both matter:

1. **Every Scope maps to exactly one Milestone.** A Scope without a
   Milestone is a piece of work with no place on the roadmap — invisible to
   the leaders Horizon serves.
2. **Plan task sub-issues are left unmilestoned.** A Milestone's progress
   bar must roll up **roadmap Scopes, not implementation tasks**. If
   sub-issues were milestoned, a Scope broken into seven tasks would
   dominate the rollup and the Horizon board would report task churn as
   roadmap progress. Membership is **parent-Scopes-only**, by design.

**AI never creates a Milestone.** A Milestone is a Horizon roadmap line, and
roadmap lines are a human-owned planning decision, the same principle that
keeps Ship human. If no existing Milestone fits a
Scope, that is a signal the roadmap Item is missing from Horizon; the skill
surfaces it and the human adds the Item, rather than the AI inventing one.

**Enforcement is warn, not block.** When a repo is Horizon-bound,
`/spade-scope` strongly prompts for a Milestone and recommends the best-fit
one, but a human may still file a Scope unmilestoned after an explicit
confirmation (the rollup then under-counts until it is attached). The bind
is opt-in per repo, declared with a `horizon:` block in `.spade/config`:

```yaml
# Horizon roadmap binding (opt-in). Present only when this repo's Linear
# project is fronted by a Horizon roadmap board. Absent this block, SPADE is
# Horizon-unaware and nothing below applies.
horizon:
  board_url: https://horizon.example.com/t/<team>/p/<project>  # optional, for deep links
  enforce_scope_milestone: warn   # warn (default) | off — omit to mean warn
```

A Horizon binding only has meaning where Linear Milestones exist, so it
applies in `linear` and `hybrid` mode. In `local` mode there are no Linear
Milestones to attach to and the binding is inert.

### Claude Code + Linear MCP

Claude Code (Anthropic's command-line AI agent) natively integrates with Linear
via MCP (Model Context Protocol). This means Claude Code can:

- Read issues: pull the Scope, acceptance criteria, and context directly from Linear
- Generate plans: create sub-issues on a parent issue with descriptions, priorities,
  labels, and assignments
- Deliver tasks: write code, build features, run tests, all with the Linear issue
  context loaded
- Update status: move issues through the SPADE workflow as work progresses
- Create documentation: attach plan documents, architecture notes, and decision
  records to projects

### Other AI Agents

SPADE is not locked to Anthropic tooling. The framework works with any AI agent
that can:

- Read a structured Scope (from Linear, Notion, or any project tool)
- Generate a structured Plan (sub-tasks with context)
- Deliver discrete tasks (code, documentation, configuration)
- Report completion status

Cursor, GitHub Copilot Workspace, Codex, or any future agent that supports MCP
can slot into the Deliver phase. The framework is tool-agnostic. It is about the
human-AI handoff pattern, not specific products.

### Canonical skills and host projections

From v2.1, `src/` is the only human-editable skill and agent source.
`src/CAPABILITIES.md` is the flat capability and version manifest, while
`src/hosts/` contains the fixed operation mappings for Claude and Codex.
The generated `.claude/`, `.codex/`, top-level `skills/`, and top-level
`agents/` trees are delivery payloads, not normative sources.

Run `./scripts/project-hosts.sh` after changing canonical skills, agents,
references, adapters, hooks, or the capability manifest.
`src/hooks/hooks.json` is the canonical hook source; the generator copies it to
the Claude payload's `hooks/` root (§ Mechanical guards). Codex receives none.
Run `./scripts/project-hosts.sh --check` in review and CI to regenerate into a
temporary root and fail on any byte drift, unresolved token, inventory drift,
or install-manifest drift.

The adapters translate only four host operations: user decisions, shell
execution, isolated reviewer dispatch, and read-only researcher dispatch.
They cannot carry workflow bodies, widen permissions, or change Scope,
Approve, Evaluate, halt, or merge gates.
Shared behavior is copied byte-identically wherever host semantics match.

Claude registers generated agent definitions with explicit tool allowlists.
Codex loads generated persona references into isolated subagents.
Codex research uses an ephemeral host-native invocation with a read-only
sandbox and user MCP/config disabled; its release fixture proves write denial,
connector isolation, and retained built-in web research.

The authoring and progressive-disclosure contract lives in
`docs/SKILL-AUTHORING.md`.
Always-loaded skills retain routing, invariants, safety gates, and completion
criteria; triggered history, examples, migrations, and branch-specific detail
live in canonical `references/` files with explicit load conditions.

---

## Operating Modes

SPADE keeps per-project state - frontier maps, Scopes, Plans, learnings - in one of two
places: a **tracker** (today, Linear) or **local files** under `.spade/`.
Which side is canonical is a per-repo choice, declared as `mode:` in
`.spade/config`:

| Mode     | Canonical store   | Local files               | When to use                                                                                  |
|----------|-------------------|----------------------------|-----------------------------------------------------------------------------------------------|
| `linear` | Linear tracker    | not written                | Team has Linear MCP; the tracker is the system of record.                                     |
| `local`  | `.spade/` files   | canonical                  | No tracker access — air-gapped repos, solo work, or projects that deliberately keep work-tracking in-repo. |
| `hybrid` | Linear tracker    | non-authoritative mirror   | Tracker is canonical, but a local mirror is kept for fallback reads when the tracker is unreachable. |

`linear` mode is the historical default and matches the "Linear as the
System of Record" model above. `local` and `hybrid` were added in v1.7
(M-879) so that the canonical side becomes configuration, not a framework
default. A repo running under a hand-written CLAUDE.md override to force
local behaviour should drop that override and set `mode: local` instead.

### Mode Resolver

Every skill resolves the operating mode **once, at the top of its run**,
before any tracker call or local-file access. The resolution is a fixed
sequence — skills reference this section by a single line ("resolve mode
per FRAMEWORK.md § Mode Resolver") and never embed a copy of the
algorithm.

1. **Explicit wins.** If `.spade/config` contains a `mode:` line, that
   value is the mode. No probe runs — explicit configuration is never
   second-guessed.
2. **Auto-detect when absent.** If `.spade/config` has no `mode:` line,
   the resolver runs a **probe**: a single no-op `list_teams` MCP call,
   wrapped in a try/skip with a **5-second timeout**.
3. **Auto-detect outcome.** The probe resolves `linear` if it returns at
   least one team **and** the `linear.team_id` in `.spade/config` is
   among the returned teams; otherwise it resolves `local`.

**Failure policy** — what happens when the probe cannot reach Linear:

| Situation                                                          | Behaviour                                                                                                                                              |
|--------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mode:` is explicit, `linear.team_id` is set, and the probe fails  | **Fail loud.** Emit a single-line error and abort the skill. A configured tracker that is unreachable is an error the human must see, not route around. |
| `mode:` is absent (auto-detect path) and the probe fails           | **Degrade quietly.** Resolve `local` and emit one warning per session. A repo that never configured a tracker should keep working offline.             |

The asymmetry is deliberate: an explicit `mode: linear` is a promise the
repo made, and breaking it silently would hide an outage. An
unconfigured repo made no such promise.

### Local Layout

In `local` and `hybrid` modes, SPADE artefacts are files under `.spade/`.
The canonical paths are:

| Artefact | Path                                          |
|----------|-----------------------------------------------|
| Frontier | `.spade/frontiers/<slug>/index.md` plus immutable `decisions/<question-id>.md` records |
| Scope    | `.spade/scopes/<slug>.md` — one file per Scope |
| Plan     | `.spade/plans/<scope-slug>-plan.md` — one flat file per Plan |
| Run      | `.spade/runs/<scope-key>.md` - one resumable continuity file per Scope |
| Learning | `.spade/learnings/<YYYY-MM-DD>-<slug>.md`     |

The flat `.spade/plans/<scope-slug>-plan.md` layout matches the M-420
contract (see § Plan Schema → Storage). This section is the single
source of truth for **canonical paths and Scope frontmatter**; Plan
frontmatter is documented in § Plan Schema and learning frontmatter in
§ Learnings → Storage. Skills reference these sections and never
re-specify a schema inline.

**Slug grammar.** A slug matches `^[a-z0-9][a-z0-9-]{0,63}$` — 1 to 64
characters, lowercase letters, digits, and hyphens only, with no
leading hyphen. The character class excludes `.`, so `..` can never
appear. Any skill that derives a slug from a Linear title or human
input applies this grammar.
An input that cannot produce a valid slug causes the skill to **abort
with a clear error** rather than write a path outside `.spade/`. The
grammar is a path-safety boundary, not a cosmetic rule: `..` and
absolute path components must never reach the filesystem.

**Scope frontmatter.** A Scope file carries flat YAML frontmatter (no
nested structures — the framework's linter supports only flat keys):

```yaml
---
name: <slug>                 # slug identifier; matches the filename
id: sp-harden-local-ids-k3f9q
title: <human-readable title>
status: scoped | planning | approval | delivering | evaluating | done
type: feature | bug | chore | docs | refactor | investigation
phase: scope | plan | delivery | evaluation   # legacy mirror of status
created: YYYY-MM-DD
updated: YYYY-MM-DD
# Optional Scope extras:
origin: milestone | reactive | ad-hoc
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
delivery: ai-delivered | human-delivery | mostly-ai-delivered | mixed
linear_issue: M-123          # present when the repo also has a tracker
linear_url: https://linear.app/...
panel_review: <date + summary>   # set by /spade-review when a panel ran
---
```

The `status`, `type`, and `priority` value sets above are the
**canonical enum lists** — the schema lint (`lint-local-frontmatter.sh`)
enforces exactly these, so extending an enum means editing this block.

**Stable identifier.** Every Scope created at v1.8 or later carries an
`id` — a stable identifier that reads as what the work is. Its form is
`sp-<stem>-<suffix>`:

- `<stem>` is derived from the Scope title (below), at most 40
  characters.
- `<suffix>` is exactly five lowercase alphanumeric characters
  (`[a-z0-9]`), minted at random once, at creation.

The complete `id` matches `^sp-[a-z0-9][a-z0-9-]{0,39}-[a-z0-9]{5}$`
(a 1-to-40-character stem, then the suffix) and must not contain two
consecutive hyphens — a constraint the character class cannot express, so
it is checked separately. At most 49 characters overall, so an `id`
always satisfies the § Slug grammar above. That is what makes it safe to
use directly as a path component, for example the run key in
`.spade/runs/<scope-key>.md`.

The value is read literally. The schema lint's flat-frontmatter parser
strips neither trailing `#` comments nor quotes, so an `id` line must
carry the identifier and nothing else — annotate the field in prose,
never inline.

`/spade-scope` mints the `id` once at creation; there is no central
allocator, so uniqueness is probabilistic rather than enforced. It comes
from both halves together: the stem separates unrelated work, and the
36⁵ suffix space (~60 million) makes a collision within one stem
negligible.

**The collision domain is the stem, not the title.** Because the stem is
truncated at 40 characters, two *different* titles can derive the same
stem — `Make SPADE stable identifiers readable and fast` and `Make SPADE
stable identifiers readable and safe` both derive
`make-spade-stable-identifiers-readable`, because truncation drops the
word that distinguished them. Any two Scopes sharing a stem
collide only if they also draw the same five-character suffix. Where it
actually matters — a filename — the collision is caught rather than left
to chance: `/spade-scope` performs a mandatory slug-collision check
before writing `.spade/scopes/<slug>.md` and **aborts** on a clash.

**Deriving the stem.** The derivation is fixed, so the same title always
produces the same stem:

1. **Fold to ASCII, exactly this way:** normalise the title to Unicode
   **NFKD**, drop every combining mark (general category `Mn`), then
   discard every remaining non-ASCII character. Do **not** transliterate
   — there is no `ß`→`ss` or `Æ`→`ae` step, because transliteration is
   language-dependent and would make the stem ambiguous.
2. Lowercase the result.
3. Replace every run of characters outside `[a-z0-9]` with a single
   hyphen.
4. Strip leading and trailing hyphens.
5. Truncate to at most 40 characters at a hyphen boundary — keep whole
   words. When the first word alone already exceeds 40 characters,
   hard-truncate at 40.
6. Strip any hyphen left at the truncation point.

Step 1 is specified to the algorithm rather than the intent because
"fold to ASCII" has several plausible readings that disagree. Worked
examples, which are the contract:

| Title | Stem | Why |
|---|---|---|
| `Café API` | `cafe-api` | NFKD splits `é` into `e` + combining acute; the mark is dropped, the `e` survives |
| `Straße API` | `strae-api` | `ß` has no NFKD decomposition and is not ASCII, so it is discarded outright — no `ss` transliteration, and no separator is left behind, so `stra` and `e` join up |
| `Æther API` | `ther-api` | `Æ` is discarded for the same reason, in step 1 — so no separator and no leading hyphen is ever produced, and `ther` simply starts the stem |
| `東京 API` | `api` | CJK characters are discarded, leaving ` API`; the space becomes a hyphen and *that* leading hyphen is stripped in step 4 |
| `👩🏽‍💻 API` | `api` | emoji and joiners are discarded |
| `東京` | *(abort)* | nothing ASCII survives, so the stem is empty and the skill aborts |

The last row is the important one: a title in a non-Latin script can
derive an empty stem, and that **aborts** rather than silently producing
a stemless identifier.

A title that derives an **empty** stem causes the skill to **abort with
a clear error** rather than write a path, exactly as the § Slug grammar
requires. There is no fallback to a stemless or random-only `id`: the
grammar is a path-safety boundary and it fails closed.

**The stem is meaningful at creation, not forever.** The `id` never
changes, so a later title reword leaves the stem describing what the
work was called when it started. That is expected. `name` — the slug and
the filename — is the current truth; the `id` is the stable join key
tooling should rely on. Because the stem is permanent and propagates
further than the filename does (run-trace filenames, run-state
`scope_id`, Plan join keys), **avoid putting sensitive detail in a Scope
title**: unlike the filename, the `id` cannot be renamed later.

Correcting a **malformed** `id` — one matching neither this grammar nor
the legacy form below — is a permitted repair, not a re-mint. The
never-re-mint rule protects valid identifiers; it does not require
preserving a broken one.

The `id` is a **correctness-only identifier** and explicitly **not** an
authorisation or trust primitive: nothing may grant access or privilege
from knowing or guessing an `id`. Making the stem predictable from the
title changes nothing here, precisely because guessing an `id` was never
worth anything.

**Legacy form.** Scopes minted between v1.8 and v3.4 carry the original
random form: `sp-` followed by six lowercase alphanumeric characters,
e.g. `sp-7k2m9q`. That form stays **valid indefinitely** and is never
rewritten or migrated. The schema lint accepts both forms permanently,
because `.spade/version` records the *installed* version rather than the
version that wrote each artefact — a repo on the current release
legitimately contains Scopes written years earlier.

**Schema version.** The layout grammar is tied to `.spade/version`. A
reader MUST consult `spade_version` and apply the grammar for that
version. Files written before v1.7 (the M-323, M-343, and M-420 era)
predate this contract: they are **explicitly grandfathered** — skills
read them tolerantly, accept unknown or missing fields, and never
silently rewrite them. A skill that does rewrite a legacy file (for
example `/spade-evaluate` updating `status:`) MUST preserve every field
it does not recognise.

The `id` field (introduced at v1.8) follows the same spirit: it is
**required on Scopes created at v1.8 or later** but **warn-only on any
earlier file** — the schema lint flags a missing `id` as a warning,
never a hard failure, and skills never back-fill it into a pre-v1.8
file. An `id` that is **present but malformed** is a different case and
is a **hard failure**: an absent identifier is history, a broken one is
a defect.

**A consumer's `.spade/docs/` copy is a snapshot, not the contract.**
`/spade-onboard` copies this document into a consumer repo at
onboarding, and no migration action refreshes it afterwards. That copy
is therefore point-in-time reference material only. The **installed
skill contracts are operative** — when the two disagree, the installed
skills win, and this document at the framework's canonical revision is
the normative text.

### Hybrid Mode

`hybrid` mode keeps the **tracker canonical** — exactly as `linear` mode
does, and consistent with the M-420 rule that the tracker is the system
of record — while also maintaining a local mirror under `.spade/` for
resilience.

- **Reads** consult the tracker first. The local mirror is read only as
  a fallback when the tracker is unreachable.
- **Writes** go to the tracker first. On a successful tracker write, the
  corresponding local mirror file is written **best-effort**. If the
  mirror write fails, the tracker write still stands and a single-line
  warning surfaces.
- On a **tracker-write failure**, the skill aborts and surfaces the
  error to the human. There is no local-only fallback in `hybrid` —
  writing the Plan to `.spade/plans/` would silently fork the canonical
  record. (`linear` mode *may* fall back to a local Plan file on a
  write failure, per § Plan Schema → Storage; `hybrid` deliberately
  does not, precisely because it also keeps a mirror.)

The local mirror in `hybrid` mode is **explicitly non-authoritative**.
Downstream tooling, audits, and humans MUST treat the tracker as ground
truth; the mirror is a convenience for status and history reads only, never a
basis for resume, checkpoint, repair, or inferred approval and never a source
of record. A repo that wants local files to *be* canonical wants `local`
mode, not `hybrid`.

---

## Cycle Rhythm

SPADE does not prescribe a rigid daily schedule. The rhythm is driven by two
concrete touchpoints per cycle, with everything else happening asynchronously.

Start of cycle: Scoping and Planning. The team reviews active Milestones and
agrees on the Scopes for this cycle. Each engineer owns their parent issues and
is responsible for ensuring the Scope is clear enough for AI to plan against.

End of cycle: Evaluation. Parent issue owners verify completed work against the
original Scope. Does it meet the acceptance criteria? Does it work end-to-end?
Issues that pass move to Done. Issues that fail go back with specific feedback.

Between those two points, delivery is continuous and asynchronous. Sub-issues get
worked by AI agents and humans as they become unblocked. New Scopes can be added
mid-cycle as priorities shift. The backlog is a living thing, not a quarterly
contract.

---

## Principles

1. Humans own the edges. Humans define what to build (Scope) and confirm it was
   built correctly (Evaluate). AI never decides what to build, and AI output is
   never shipped without human verification.
   Once verified, an AI agent may perform the merge when explicitly asked.
2. Plans are artefacts, not ephemeral. Every AI-generated plan is documented and
   attached to the work item.
3. Approval is a gate, not a rubber stamp. If you are approving every plan in
   30 seconds, the gate is not working.
4. Delivery mode is explicit. Every task is labelled as AI-delivered or
   human-delivery.
5. Feedback loops are first-class. A rejected plan goes back to Planning. A
   failed evaluation goes back to Delivery. The loop is expected to iterate.
6. Architecture constraints are codified, not memorised. Maintain living
   documents (ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md) that AI reads
   during planning.
7. Scope determines approval depth. Strategic decisions get deep review.
   Granular implementation tasks get light review.

---

## Multi-persona Review

The `/spade-review` skill is a second-opinion gate. Since v1.1 it
operates as **independent persona subagents** rather than a single
generalist reviewer. Since v1.13.0 the roster is **cast dynamically**:
a triage step reads the change and casts the personas its risk
dimensions actually need, the way a Claude Code workflow author fans out
sub-agents to the parts that matter. Eight **canonical** personas are the
default library; the coordinator draws the relevant ones (a typical
review casts three to five) and **invents ad-hoc personas** for
dimensions no canonical lane covers. Casting runs
on **evidence** (below): a persona earns a seat only when the change
carries a concrete signal for its lane, the cast is bounded by a floor of
three and a signal-ranked soft cap of five, and the notable exclusions
(a live-but-unselected lane cut under the cap, or any `security-lens`
drop) are recorded with a reason. Each canonical persona is defined under
`.claude/agents/`, is one of six **domain** lenses (owns a disjoint risk
surface) or two **stance** lenses (ranges over the whole change from a
posture — see §"Stance vs domain personas"), and is primed to care about
one specific concern:

| Persona                         | Kind   | Focus                                                                       | Modes      |
|---------------------------------|--------|------------------------------------------------------------------------------|------------|
| `scope-guardian`                | domain | Scope completeness, testability, Plan→Scope traceability; gold-plating / proportionality (absorbed remit). | all        |
| `architecture-strategist`       | domain | Conflicts with `ARCHITECTURE.md` / `PATTERNS.md` / `ANTI-PATTERNS.md`.      | all        |
| `security-lens`                 | domain | Auth, injection, secrets, supply chain, IAM, data sensitivity.               | all        |
| `operability`                   | domain | Is the failure detectable & recoverable in production — observability, alerting, safe rollout, kill-switch, runbook. | all        |
| `migration-reversibility`       | domain | Can a schema/data migration be rolled back without data loss — expand-contract, backfill safety, the down path. | all        |
| `delivery-semantics`            | domain | Duplicate delivery, retries, ordering, exactly-once — is processing a message twice safe. | all        |
| `adversarial-reviewer`          | stance | The strongest attack on the Plan — what will fail, and why; second-order / compounding cost (absorbed remit). | all        |
| `alternatives-analyst`          | stance | Option-space survey — the road not taken; silent unless a better road exists. Plan/Full: a better alternative to the chosen approach. Scope: a Scope that pre-committed to a solution (reframe / buy-vs-build). | all        |

M-994 folded the former `yagni-simplicity` persona's remit into the
scope guardian (gold-plating and proportionality) and the adversarial
reviewer (second-order and compounding cost), taking the panel to four.
M-1248 then added the `alternatives-analyst` as net-new coverage,
initially Plan/Full-only; M-1293 gave it a narrow Scope-mode remit and
put it on every roster, so the panel became a uniform five — the
context-conditionality living in the persona's brief, not the roster.
v1.13.0 then replaced the fixed panel with **dynamic casting**: those
five became the canonical default library a triage step draws from, plus
ad-hoc personas for dimensions no canonical lane covers. PS-1692 then
replaced the original drop-with-cause selector — which, by defaulting to
*keeping* every canonical persona, still cast almost the whole library
every review — with **cast-on-evidence**: each seat is earned by a named
signal, the cast is bounded (floor three, signal-ranked soft cap five),
and `dropped[]` records only the notable exclusions. PS-1692 also grew the
library from five to **eight**, adding three **domain** lenses
(`operability`, `migration-reversibility`, `delivery-semantics`) —
promotions of recurring ad-hoc personas, each clearing the M-1248
orthogonality bar — which the bounded, evidence-driven selector can carry
without diluting any single cast (see §"Stance vs domain personas"). The
personas and their briefs are otherwise unchanged — only how the roster is
selected and recorded
became evidence-driven. See §"Why a cast and not a generalist" below.

The rationale is captured in `.spade/learnings/2026-04-22-single-reviewer-is-weaker-than-panel.md`:
a generalist reviewer tends to collapse a review into the single most
obvious concern; a persona panel forces several independent angles and
surfaces findings the generalist would miss.

### How the cast runs

`/spade-review` assembles a structured summary of the Scope and/or Plan
(the same summary for every persona), runs a triage step to **cast the
roster** (canonical personas for the change's risk dimensions, plus
ad-hoc personas for dimensions no canonical lane covers, on
cast-on-evidence under a floor of three and a signal-ranked soft cap of
five), then spawns every persona in the cast in parallel where
the runtime supports it. Each persona returns a short prose summary
followed by a JSON block of findings:

```json
{
  "persona": "scope-guardian",
  "severity": "blocking | major | minor",
  "confidence": "high | low",
  "category": "scope-completeness | ...",
  "message": "One or two lines describing the finding.",
  "refs": ["<file path>:<line>", "<linear id>", ...]
}
```

The coordinating skill then:

1. Parses every persona's JSON block.
2. **Detects convergence** by clustering findings that describe the
   same underlying concern — even across personas that filed them
   under different `category` values — into one finding, recording the
   other personas in `also_flagged_by`. This is a coordinator
   judgement, not a mechanical key match; see `/spade-review` SKILL.md
   § Merging.
3. **Sorts** by severity, then by convergence (the size of the
   `also_flagged_by` set). `confidence` is a display-only `high | low`
   flag, not a sort key — there is no `severity × confidence`
   arithmetic.
4. Presents a **tiered report** — convergence findings and every
   `blocking` finding inline, `major` up to an inline budget with the
   rest plus all `minor` collapsed to count lines — and persists the
   full untiered report to `.spade/reviews/`. Each persona's prose
   summary is shown **verbatim**, never summarised, plus a cross-model
   synthesis of disagreements and tensions for the human to resolve.

### Dispatch mode and the report envelope (v3.1.0)

Every `/spade-review` run emits two machine-parseable signals at the
top of its report so consumers can tell a real panel from a simulation:

1. **Dispatch-mode banner.** The first line of output is always
   `Dispatch mode: <value>` where `<value>` is one of:

   | Value                  | Meaning                                                                 |
   |------------------------|--------------------------------------------------------------------------|
   | `subagent-dispatch`    | Each persona ran as an independent Claude Code subagent context, in parallel. The strongest path — true multi-context review. |
   | `sequential-inproc`    | Each persona ran in an isolated context, but sequentially (runtime didn't support parallel spawns). Still genuinely multi-context; slower. |
   | `degraded`             | No isolated-context path was available; the coordinator simulated personas by re-prompting a single model context with each persona's priming. **Not a panel.** |

2. **Report envelope (JSON).** Immediately after the banner, a JSON
   code block carries structured metadata:

   ```json
   {
     "schema_version": "3.1.0",
     "dispatch_mode": "subagent-dispatch",
     "cast": [
       {"name": "scope-guardian", "origin": "canonical", "concern": "acceptance-criteria testability for 'events are handled'"},
       {"name": "architecture-strategist", "origin": "canonical", "concern": "handler bypasses the PATTERNS request-validation middleware"},
       {"name": "security-lens", "origin": "canonical", "concern": "caller signature verified at the trust boundary"},
       {"name": "adversarial-reviewer", "origin": "canonical", "concern": "forged-event / replay failure mode"},
       {"name": "idempotency-auditor", "origin": "ad-hoc", "concern": "duplicate-delivery handling"}
     ],
     "dropped": [
       {"name": "alternatives-analyst", "reason": "option latitude exists but ranked below the five cast lanes under the cap — live-but-unselected"}
     ],
     "casting_rationale": "Webhook+queue change carried six live lanes; cast the five highest-signal and cut the alternatives analyst to live-but-unselected under the cap.",
     "personas_completed": 5,
     "findings_total": 0
   }
   ```

   - `schema_version` — report-envelope contract version. v1.1.1 added
     the envelope; v2.0.0 (M-994) was the four-persona redesign — `nit`
     dropped from `severity`, `confidence` recast to `high | low`, and
     the merge-side confidence filter removed. v2.1.0 (M-1248/M-1293) was
     the five-persona fixed panel. v3.0.0 (v1.13.0) was the
     dynamic-casting redesign (the fixed `personas_spawned` integer
     replaced by `cast[]` / `dropped[]` / `casting_rationale`).
     **v3.1.0 (PS-1692)** is the cast-on-evidence redesign: an **additive,
     minor** bump — all field *shapes* are unchanged from v3.0.0, so a
     v3.0.0 consumer still parses every field — that **relaxes one
     accounting rule**. v3.0.0 required every canonical persona to appear
     in exactly one of `cast` or `dropped`; v3.1.0 replaces that totality
     invariant with "every persona that is cast OR live-but-unselected
     (plus any dropped `security-lens`) appears; an absent lane appears in
     neither", so the envelope stays bounded as the library grows. A
     consumer that validated `cast + dropped == full roster` must drop that
     assertion (none does; the report is read by a human and a gitignored
     `.spade/reviews/` file). The **finding shape is unchanged** from 2.x.
     It is independent of the framework's `.spade/version` and
     fragment-marker mechanism.
   - `dispatch_mode` — matches the banner value.
   - `cast` — the personas actually spawned, in spawn order; each entry
     carries `name`, `origin` (`canonical` | `ad-hoc`), and a `concern`
     phrase naming the **signal** that earned the seat. The cast length is
     the panel size: never fewer than three, never more than five except
     where `security-lens`'s raised-bar retention requires a sixth seat.
   - `dropped` — the **notable exclusions**, not every uncast persona: a
     lane that was live but lost the signal-ranked cut under the cap
     (live-but-unselected), or any `security-lens` drop (its raised bar
     makes every security exclusion audit-worthy), each with a one-line
     `reason`. A lane the change never lit is **absent** and appears in
     neither array (named in `casting_rationale` if notable). Empty when
     no lane was cap-cut and `security-lens` was cast.
   - `casting_rationale` — one human-readable line summarising the cast
     decision.
   - `personas_completed` — counts only cast personas whose JSON parsed
     successfully. If a persona's output was unparseable, its prose is
     still shown but this counter does not increment.

### Degraded-mode honesty

When `dispatch_mode == "degraded"`, two honesty rules take effect:

- The report's section title is **`SINGLE-CONTEXT SIMULATION (degraded)`**,
  not `PANEL SECOND OPINION`.
- The coordinator is explicitly forbidden from using the words
  "panel" or "multi-persona" in the report title, framing prose, or
  synthesis. A single-context simulation is not a panel; claiming it
  is would retroactively falsify every audit trail citing the report.

These rules are load-bearing: the whole dispatch-mode machinery exists
to let consumers tell a real panel from a simulation. If the
coordinator launders a degraded run as a panel, the machinery is
useless.

### Non-blocking by contract

The panel is informational. It never gates approval or delivery. The
approval checklist in `/spade-approve` is the gate; the panel
supplements that checklist, it does not replace it.

### Why a cast and not a generalist

Two reasons. **Coverage**: each persona is primed to care about one
angle, so a security concern and an architecture conflict don't compete
for the same attention budget. **Calibration**: structured output with
explicit severity and confidence lets the human defer low-confidence
findings without losing them — a generalist's prose review is
all-or-nothing.

Dynamic casting does not weaken either property — it protects them, but
it introduces one hazard: the coordinator's casting decision is itself a
generalist pre-judgment, made before any persona has looked, and left
unchecked it could quietly shrink a review back to the one obvious
concern. The original v1.13.0 guard, **drop-with-cause**, tried to hold
that line by making canonical personas defaults you justify *dropping* —
but a default-to-keeping rule, under an LLM coordinator, simply cast
almost the whole library every review, so the guard quietly produced the
collapse it was meant to prevent (the same-4-or-5 problem PS-1692 was
filed to fix). **Cast-on-evidence** is the replacement guard, and it
inverts the burden of proof: a seat is earned only by a named signal in
`cast[].concern`, so an unjustified cast is visibly hollow; the cast is
bounded by a floor of three and a signal-ranked soft cap of five; the
notable exclusions (cap-cuts, and any `security-lens` drop) are recorded
in `dropped[]`; and `security-lens` is dropped only when a change touches
no auth, secrets, untrusted input, network boundary, IAM, or data
sensitivity at all. Crucially, the selector is **validated behaviourally,
not just asserted**: a fixed corpus of representative changes (under
`tests/spade-review-casting/`) is cast by a *separate, blind* context that
never sees the triage spec, and its roster is compared against the
corpus's expected cast — the differential is what proves the signals are
legible from the change alone rather than that the coordinator agrees with
itself. The `cast[]` / `dropped[]` / `casting_rationale` trio makes each
casting decision reviewable rather than private.

The **canonical library** evolved by deliberate moves: five personas
through v1.1–v1.x; M-994 folded the `yagni-simplicity` persona's remit
into the scope guardian (gold-plating, proportionality) and the
adversarial reviewer (second-order, compounding cost) — a *redundant*
lane removed; M-1248 added the `alternatives-analyst` — a *missing*
option-space lane; M-1293 widened where that lane fires. v1.13.0 then
made roster selection per-review dynamic without changing the library.
PS-1692 grew it from five to eight, adding three **domain** lenses and
inverting the selector to cast-on-evidence (above).

Changing the **canonical library** — adding or removing a default
persona — still requires a new Scope that explains the coverage
rationale. The bar for an *addition* is that the new persona's remit is
genuinely orthogonal to every existing one (the test M-1248 had to pass).
Per-review **casting**, by contrast, is the coordinator's runtime
decision under cast-on-evidence — it needs no Scope, only the signal
recorded in `cast[].concern`; inventing an **ad-hoc** persona for a
single review is expected and unscoped. Promoting an ad-hoc persona into
the canonical library is the move that needs a Scope. The rationale is
captured in
`.spade/learnings/2026-04-22-single-reviewer-is-weaker-than-panel.md`.

### Stance vs domain personas

The canonical library is **eight** personas, but a typical review casts
only three to five. That a larger library does not mean a larger cast
rests on a distinction the earlier framework prose missed when it said
flatly that "more canonical personas dilute every cast" — a claim that is
only half right.

- **Domain personas** own a *disjoint risk surface*: scope, architecture,
  security, operability, migration-reversibility, delivery-semantics. A
  change either has that surface or it does not, so a domain persona fires
  **only** on changes that carry its signal. Adding a domain lens widens
  *coverage* (a previously-missed surface now gets a reviewer) without
  widening any individual *cast* — a change with no migration still casts
  no migration lens. Disjoint domain lenses do not dilute; they discriminate.
- **Stance personas** — adversarial-reviewer and alternatives-analyst —
  range over the *whole* change from a posture (attack it; survey the
  roads not taken) rather than owning a surface. Two stance personas can
  both find something on almost any change, so *multiplying stance
  personas* is what produces the duplicate-finding dilution the original
  claim feared. The library therefore grows only in **domain** lanes, and
  the stance lanes stay at two.

This is why PS-1692 could grow the library from five to eight while a
typical cast stayed at three-to-five: the three additions are domain
lenses gated by evidence, and the signal-ranked cap of five bounds the
rare change that lights many lanes at once. The "more personas dilute"
intuition holds for stance personas and fails for disjoint domain ones —
the cast-on-evidence selector is what makes the distinction pay off,
because a domain lens with no signal is simply never cast.

---

## Asking the Human

SPADE skills routinely ask the human to make a decision: approve a
Plan, pick a verdict, confirm a destructive action, choose a label.
From v1.3.0 onward, the framework's convention for *fixed-option*
decision prompts is **Claude Code's `AskUserQuestion` tool** rather
than free-form prose. The structured prompt renders as a numbered
choice list — the human picks one, and the skill receives a clean,
unambiguous answer instead of having to parse a free-text reply.

This section defines the convention. Skill prose **references** it
rather than re-stating the rule in every skill.

### Fewer prompts by default

From v5.0.0 the framework asks the human to decide far less often.
Prompts that only offered ceremony are gone: the second-opinion offer in `/spade-scope` and `/spade-approve`, file-now-versus-draft in `/spade-scope`, the quick-path type and eligibility prompts, the per-handoff autonomy confirm, and the review action question inside an orchestrated run.
The agent makes those calls itself and records each in the run trace.
What still prompts: locking a draft-first Scope, a tripwire halt, a guard deny, the Approve verdict on the Plan level, an Evaluate verdict with a human-only or open row, `/spade-learn` classification when public-safety is unclear, `/spade-update` SHA approval, `/spade-unhinged` entry, and every destructive confirmation.

### When to use `AskUserQuestion`

Use `AskUserQuestion` whenever **all** of the following hold:

- The set of valid answers is **closed** — there are 2–5 distinct
  choices and you can name each one.
- The human is being asked to **decide**, not to compose. ("Approve /
  Revise / Reject" is a decision; "Describe why this should ship" is
  composition.)
- The skill's next action **branches on which choice** the human
  picked. (If the choice doesn't change behaviour, why ask?)

Examples that fit:

- `/spade-approve`: *Approve / Approve with notes / Revise / Reject*.
- `/spade-evaluate`: *PASS / PARTIAL / FAIL*.
- `/spade-learn`: *Public-safe / Private / Skip*.
- `/spade-update`: *Pull updates / Skip*; destructive recovery
  *Confirm — wipe and reinstall / Cancel*.
- `/spade-scope`: *File in Linear now / Save as draft locally*.
- `/spade-research`: consent before Linear write *Post / Show only /
  Edit then post / Cancel*.

### When **not** to use `AskUserQuestion`

Stay free-form when:

- The human is composing content (writing a Scope's intent, drafting
  acceptance criteria, describing what failed in evaluation).
- The set of valid answers is open or unbounded (resolving an
  architecture conflict, naming a new pattern).
- The reply is naturally multi-line (a code-review comment, a
  rationale paragraph).

The convention is fixed-option-only. Forcing an open-ended question
into a 5-option list erases information the skill genuinely needs.

### Option-label style

Keep options scannable:

- **Verb-first.** *Approve*, *Revise*, *Pull updates*, *Confirm and
  wipe*. Not *Approval* or *Yes I would like to pull updates*.
- **Sentence case.** *Approve with notes*, not *APPROVE WITH NOTES*
  or *approve_with_notes*.
- **≤8 words per option.** Longer means split the prompt or rethink
  the question.
- **Distinguishable at a glance.** Two options that read nearly the
  same are a sign you should collapse them.

### Limits

- **≤5 options per prompt.** If a decision genuinely needs more,
  break it into two sequential prompts (e.g. "first pick a category,
  then pick a sub-option") or rethink whether some of those options
  are really the same choice.
- **One question at a time.** Don't bundle independent decisions into
  one prompt — they belong in separate prompts so the human can
  reverse one without re-doing the other.

### Why prose-only enforcement

The convention lives in skill prose, not in code or lint. SPADE skills
are Markdown — the agent reads the prose and follows it. We **don't**
have a runtime that intercepts free-form prompts and rewrites them.
Mechanical guards (§ Mechanical guards) are the deliberate exception:
they enforce a handful of checkable invariants, never the prompt convention.
That means the convention is a **review surface**: `/spade-review`'s
scope-guardian persona can flag prose prompts that should have been
`AskUserQuestion`. New skills are expected to
follow the convention from day one.

---

## Research

The `/spade-research` skill (v1.3.0+) spawns an isolated subagent
(`spade-researcher`, defined under `.claude/agents/`) on Opus 4.7 with
a read-only tool allowlist (`Read`, `Grep`, `Glob`, `WebSearch`,
`WebFetch`) to perform **landscape research** on a question the human
asks: prior art, library/SOTA evaluation, comparison shape, external
documentation reads. The subagent returns a single condensed report;
the parent skill displays it inline and (optionally, with explicit
human consent) posts it as a comment on a Linear parent issue.

The skill is **callable any time** — it is not tied to a SPADE phase.
Auto-trigger phrases include *"properly research this"*, *"look into
X"*, *"check the prior art"*, *"second opinion on the landscape"*, plus
the explicit slash-command form.

### Findings schema (locked)

Every report from the researcher subagent conforms to this shape, in
this order, with no preamble:

```markdown
## Question

<the asker's question, verbatim or near-verbatim>

## Findings

- <bullet 1, with inline footnote citation [^1]>
- <bullet 2, [^2]>
- <bullet 3, (no source — model knowledge)>
- ...

## Recommendation

<one paragraph, opinionated, ≤8 lines>

## Sources

[^1]: <Title> — <URL> (fetched YYYY-MM-DD)
[^2]: <Title> — <URL> (fetched YYYY-MM-DD)
```

The shape is locked. Consumers (`/spade-research`, future
`/spade-evaluate` integrations) parse it positionally.

### Read-only contract

The researcher subagent's tool allowlist is exactly `Read, Grep,
Glob, WebSearch, WebFetch`. It **may not** edit files, run shell
commands, create Linear issues, or chain to other subagents. The
parent `/spade-research` skill — running in the main session, not the
subagent — is responsible for any state mutation, gated by explicit
human consent.

### No fabricated citations

The single rule that distinguishes a research subagent from a
plausible-sounding bullshitter:

- Every URL in **Sources** must come from a real `WebSearch` /
  `WebFetch` result actually retrieved during the run.
- Facts from training data are marked `(no source — model
  knowledge)` inline in the bullet — never given a fake URL.
- Failed fetches are reported as failures, not papered over.

This rule is reinforced in the subagent's prose contract because the
failure mode (a fabricated citation that looks real) erodes trust
faster than any other.

### Consent before Linear write

When `/spade-research` is invoked with a Scope context (`--scope
<linear-id>` or implicitly from a phase that already has a parent
issue), it asks the human via `AskUserQuestion` (per the "Asking the
Human" convention above) whether to post the report:

- *Post this comment to <issue-id>*
- *Just show me — don't post*
- *Let me edit it first, then post*
- *Cancel*

Never silent, never free-form. The Linear comment, when posted,
carries a `research:` prefix in the body so it is visually distinct
from Plan comments.

### Ephemeral by default

Research outputs are not persisted under `.spade/`. There is no
`.spade/research/` directory and no read-back from past research. If
the human wants the report retained, they choose to attach it to a
Linear issue at consent-prompt time. Otherwise the report exists only
in the conversation transcript.

This is a deliberate constraint. A persistent research store would
introduce a second source-of-truth alongside Linear, the same drift
risk that v1.2.0 eliminated for Plans. If a real need for persistent
research surfaces, it gets a separate Scope.

### One question per invocation

The skill is one-shot per call. Iterative deep-dives, batched
multi-question runs, and follow-up "now research X' from those
findings" are out of scope and are expected to be separate
invocations.

---

## Learnings

Each pass of the SPADE loop should produce knowledge that strengthens the
next pass. Without a place to capture it, that knowledge vanishes into PR
descriptions and Evaluate comments. SPADE addresses this with a small
learnings store and a plan-time integration.

### Storage

Learnings live under `.spade/learnings/` in the consumer repo, one file
per learning, with the filename pattern
`YYYY-MM-DD-<short-slug>.md`:

- `.spade/learnings/*.md` — **public-safe** learnings. Committed with
  the rest of the repo.
- `.spade/learnings/private/*.md` — **not public-safe**. Gitignored.
  Use for entries that reference internal systems, credentials paths,
  security details, or anything else that must not leak into public
  forks.

Each file carries the following flat YAML frontmatter (no nested
structures — the framework's linter only supports flat keys):

```yaml
---
title: One-line summary of what was learned
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active               # or "archived"
public_safe: true            # or false
scope_ref: LIN-123           # optional; link to originating Scope
---
```

Body conventionally has two sections: *What we learned* (specific
observation, not a platitude) and *Why it matters for future work* (the
concrete implication). See `.spade/learnings/` in this repo for two
worked examples distilled from the M-323 recon.

### Capture

Use `/spade-learn` to capture a learning (see
`.claude/skills/spade-learn/SKILL.md`). The skill drafts a complete
entry from context, asks whether it is public-safe, and routes to the
correct directory on write. Capture is cheap and meant to be used
freely — aim for a few learnings per Scope, not one per quarter.

### Leads vs `/spade-learn`

`/leads` captures an actionable discovery that is out of scope for the current task so it can be triaged later without derailing delivery.
`/spade-learn` captures reusable knowledge that should change how future Scopes or Plans are understood.
A Lead may later produce a Scope, while a learning informs future planning; the two records are complementary and neither substitutes for the other.

### Automatic candidates from Deliver and Evaluate

Deliver checks bounded task, bundle, and Delivery Review evidence at verification boundaries.
Evaluate checks the two review axes, acceptance-evidence matrix, required checks, and human verdict.
Both invoke `/spade-learn` only when that evidence demonstrates a failed assumption, recurring pitfall, new project constraint, reusable pattern, or correction to an active learning.

Every candidate names a specific observation, retained evidence, future planning implication, originating Scope, area, and tags.
Ordinary completion, generic advice, and unrestricted transcript mining produce no candidate and no prompt.

Before display, `/spade-learn` compares the draft with active public and private project learnings using normalized-title equality or tag-set Jaccard similarity of at least 0.5, then reads possible matches to distinguish duplicate, update, correction, or coincidental overlap.
Private match content remains local and is never copied into tracker state or public output.

The human sees at most one deduplicated draft and chooses Public-safe, Private, or Skip before any learning file is written.
Duplicates create no second file.
Updates and corrections reuse `/spade-learn --refresh`'s explicit human gate: update the active entry, archive and replace it, or skip.
No daemon, external memory, automatic commit, or separate context-save skill is involved.

### Refresh

Learnings decay. `/spade-learn --refresh` is a periodic (quarterly at
most), human-gated pass that:

- Lists active entries older than 180 days for triage (keep active /
  archive / delete).
- Flags pairs of active entries whose tags overlap ≥50% and whose titles
  appear to contradict, so the human can resolve before surfacing them
  to future Plans.
- Never silently modifies anything — every action requires explicit
  human approval, just like the Approve gate in the main loop.

The lint at `scripts/lint/lint-learnings.sh` surfaces stale entries as
warnings on every PR so staleness can't accumulate silently.

### Plan-time integration

Before producing a Plan, `/spade-plan` greps `.spade/learnings/*.md` for
entries that match the current Scope:

- A learning matches if its `scope_ref` equals the current Scope's
  Linear identifier, OR
- At least **`T`** of its `tags` appear in the Scope title or the tech
  stack row of `ARCHITECTURE.md`, where `T` is determined by the
  cold-start threshold below.

#### Cold-start threshold (v1.1.1)

`T` varies with store size to avoid two opposite failure modes:

- **Empty / small store (cold start):** `N < 20` active non-archived
  entries → `T = 1`. A single shared tag surfaces a learning. Without
  this, a consumer's first several Scopes never match anything and the
  loop looks dead on day one — the store stays empty because capture
  feels pointless.
- **Established store:** `N ≥ 20` active non-archived entries → `T = 2`.
  Single-tag coincidence becomes noise at this volume; two shared tags
  is the signal.

`N` counts entries with `status: active` under `.spade/learnings/`.
Archived entries are always excluded. The `private/` subdirectory is
excluded **by default** and included only when the operator explicitly
opts in via `/spade-plan` — matching the same opt-in rule the skill
uses when globbing for matches. The cutover is deterministic —
`/spade-plan` reads the count at match time.

The `scope_ref` path is unaffected by `T`. An entry whose `scope_ref`
equals the current Scope's identifier always surfaces, at any store
size.

The `20` threshold is a **deliberate, named number**. Changing it
requires a new Scope. Rationale: 20 is large enough that single-tag
matches produce noticeable noise, but small enough that most repos
cross the cutover within the first few cycles.

#### Matched-learnings log (v1.1.1)

When `/spade-plan` surfaces learnings, each entry in the `Prior
Learnings Considered` section carries a match-reason line showing why
it fired:

- `Match reason: scope_ref=<ID>` — the scope_ref path matched.
- `Match reason: tags matched [<tag1>, <tag2>, ...]` — the tag path
  matched; lists only the tags that actually matched the Scope, not
  the entry's full tag set.

This gives a human scanning the Plan a way to see when matching is
off — the prose framework has no telemetry, so the match reason is
the minimum viable observability for "which knob is the learnings
loop turning."

Matched entries surface in a `Prior Learnings Considered` section near
the top of the Plan. Archived entries are skipped. No matches = no
section; silence is cheaper than padding.

### Why this matters

The biggest failure mode of AI-assisted delivery is treating each task
as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. A 60-second
capture during or after Evaluate closes that loop for free.

Without a refresh mechanism, the store would rot. The pair of capture
+ refresh is what keeps the store high-signal over years, not weeks.

## HTML Rendering

From v1.6, every locally-stored Scope and Plan gets a sibling HTML
rendering produced by `bin/spade-render` (a POSIX-shell wrapper around
`pandoc`). Markdown remains canonical — HTML is a **read-only rendered
view**, regeneratable and `.gitignore`-able. Skills never read HTML
back; they read `.md`.

### Installing pandoc

| OS      | Command                                          |
|---------|--------------------------------------------------|
| macOS   | `brew install pandoc`                            |
| Linux   | `sudo apt install pandoc` (or distro equivalent) |
| Windows | `winget install pandoc`                          |

Pandoc 3.0+ is required (`--embed-resources` was added in 3.0,
replacing the removed `--self-contained`). When pandoc is absent,
`spade-render` exits 2 and the calling skill surfaces an install hint
on every write until pandoc is installed — the `.md` is the canonical
artefact and is always written.

### Renderer interface

```bash
spade-render <input.md>                   # writes sibling <input>.html
spade-render <input.md> --output <file>   # writes to <file>
spade-render <input.md> --stdout          # prints HTML to stdout
```

Exit codes: 0 success (prints absolute output path to stdout); 1 usage
or input-not-found; 2 pandoc not installed; 3 pandoc render error.

### Status pill palette

The renderer maps frontmatter `status:` to a coloured pill. These six
hex values are the single source of truth — mirrored verbatim in
`render/spade.css` as `--spade-status-<phase>` custom properties:

| Phase        | Colour    |
|--------------|-----------|
| `scoped`     | `#4f6cb5` |
| `planning`   | `#c69022` |
| `approval`   | `#d96e2a` |
| `delivering` | `#7b4ec3` |
| `evaluating` | `#2a8a8a` |
| `done`       | `#2f8b46` |

### Security stance

Renderer pins these Pandoc flags: `--from markdown-raw_html` (strips
inline HTML, blocking `<script>` and event-handler attribute
injection), `--standalone --embed-resources` (self-contained HTML, no
external references). The template emits a restrictive Content
Security Policy meta on every render:

```text
default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'
```

CI enforces this via `scripts/lint/lint-render-security.sh` (greps
rendered fixtures for `<script`, `on*=`, `javascript:`, leaked
filesystem paths, and the exact CSP literal). The fixture suite lives
at `tests/fixtures/render/`.

### Recommended `.gitignore` line

By default, HTML siblings are regeneratable and need not be committed.
Add this line to the consumer's `.gitignore` to keep them out of PR
diffs:

```gitignore
.spade/**/*.html
```

This is **not** auto-injected by `/spade-onboard`; consumers add it
explicitly. Teams that prefer to commit HTML (offline reading,
PR-comment screenshots, GitHub Pages hosting) can leave it out.

### Terminal `file://` links

`/spade-scope` and `/spade-plan` append a closing line on every local
write:

```text
View in browser: file://<absolute-path>.html
```

Modern terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify
the URL for cmd-click. SSH, tmux, screen and CI runners may not — the
plain-text URL still works as a copy-paste fallback. macOS/Linux paths
map directly (`file:///Users/...`, `file:///home/...`); Windows under
Git-Bash/WSL produces `file:///C:/...` via `realpath`.

### Determinism

Identical `.md` produces identical `.html` **within the same Pandoc
minor version**. Across minor versions, output may differ slightly
(typically whitespace and id slug changes). Consumers who commit HTML
should expect small diffs on Pandoc upgrades; this is documented
behaviour, not a defect.

---

## The unslop pass

SPADE writes a lot of prose a person has to read.
The `/unslop` skill is the framework's standing edit pass for that prose: it removes AI tells (puffery, AI vocabulary, em dashes, inline-header lists, filler, abstract metaphor jargon) and adds human voice.
It ships as a canonical skill in every install, so a skill can rely on it being present.

The pass applies to every human-facing output a SPADE skill presents or persists:

- Scope and Plan prose (the artefact text, including card field values)
- PR titles and bodies, including the Deliver approach summary and fast-track PR descriptions
- Terminal TL;DRs
- Review and Evaluate report prose
- Learnings, research findings, and any comment posted to the tracker

It does not apply to machine-read artefacts: code, configuration, JSON envelopes, schemas, manifests, and lint output stay exactly as their contracts specify.
Structured formats and the pass compose: a Plan card keeps its strict fields while the words inside each field stay plain and human.

Skills reference this pass with one line at their present-or-persist step ("apply the `/unslop` pass to the prose") and never restate the pattern list - the skill is the single source.

## Terminal TL;DR

From v1.14, `/spade-scope` and `/spade-plan` close every run with a
plain-English **Terminal TL;DR** block printed to the terminal — built
to be read in five seconds by a human who never opened the full
artefact. It answers three standing questions — what this does, what
will ship, and what could bite — and ends with the one decision the
human has to make next.

This section is the **single source of truth** for the TL;DR's shape and
rules. Skills reference it by one line ("print the Terminal TL;DR per
FRAMEWORK.md § Terminal TL;DR") and **never re-specify the format
inline, so there is no second copy to drift.**

### What it is (and is not)

The TL;DR is a **terminal-only, ephemeral** view: printed to stdout,
never persisted, never read back by any skill (skills read `.md`),
regeneratable on the next run. It is **not** a new field on the Scope or
Plan — it summarises content those artefacts already hold (§ The Loop,
§ Plan Schema) and introduces nothing new. In particular it does **not**
restate the Plan's "Technical approach summary" field verbatim; it
paraphrases that field in plainer terms. This keeps it consistent with
"Markdown remains canonical … HTML is a read-only rendered view" — the
TL;DR is never a source of truth.

### Voice

Plain English, scannable in five seconds. Sentence case, verb-first, no
shouting, British spelling. **No SPADE jargon, no internal IDs, no
branch noise the reader cannot act on.** Each label is followed by one
short sentence (the `Ships` and `Watch` lines may wrap, but stay tight).
Risks are capped at **two** — surface only what would change the human's
call; everything else stays in the artefact.

### Shape

A fixed four-row block, each row a labelled value, separated by hairline
rules so a wrapped value never bleeds into the next. The labels never
move, so the eye lands on the same row every time:

```text
─── TL;DR ──────────────────────────────────────────────────
 What   <one plain sentence: the outcome this is going after>
 ────────────────────────────────────────────────────────────
 Ships  <what "done" means — see the per-artefact rule below>
 ────────────────────────────────────────────────────────────
 Watch  <the 1-2 things most likely to bite; "Nothing flagged." if clean>
 ────────────────────────────────────────────────────────────
 Next   <the decision in a few words>. Run <next command>.
─────────────────────────────────────────────────────────────
```

Rendering rules (so it stays consistent run to run):

- Wrap the whole block in a ```` ```text ```` fence so it renders
  monospaced and the rules align.
- **Top rule** carries the title, left-anchored: `─── TL;DR ` then
  `─` filling to the block width (~60 cols is a good default).
- **Label column.** Each content row is one leading space, then the
  label left-justified in a 7-character field, then the value — so
  every value starts at the same column. Labels are the four fixed
  words `What`, `Ships`, `Watch`, `Next`. Continuation lines of a
  wrapped value indent to that same value column (8 spaces).
- **Hairline rules** between blocks are inset by one leading space
  (` ────…`) — lighter than the frame, so the four values read as
  distinct cells.
- **Bottom rule** is flush-left and full width (no leading space), one
  character wider than the inset rules, to close the frame.

`Next` replaces the older `Your call` label: it keeps the action column
narrow enough to align with the other three, and the decision framing
("Approve, or push back …") lives in the value, not the label.

### The labels

| Label | Holds | Sourced from |
|-------|-------|--------------|
| **What** | The outcome in one plain sentence — no jargon. | Scope: Statement of Intent. Plan: Technical Approach Summary, rephrased plainly. |
| **Ships** | What "done" looks like — differs by artefact (see below). | Scope: Acceptance Criteria (+ Delivery Preference). Plan: Delivery Bundles + Tasks + Effort. |
| **Watch** | The 1-2 things most likely to go wrong: risks, unknowns, conflicts. `Nothing flagged.` if there are none. | Scope: Risk / Unknowns (+ Out of Scope / Dependencies boundary). Plan: Risks and Assumptions, incl. any ANTI-PATTERNS.md conflict. |
| **Next** | The decision the human makes next, then the single command to act. | Scope: approve / push back → `/spade-plan`. Plan: approve / send back → `/spade-approve`. |

### "Ships" differs by artefact

One contract, two tailored fills — they diverge only at the `Ships` line:

- **Scope** — outcome-level. A Scope has no PR yet, so its unit of
  shipping is the **criteria contract**, never a branch. Write:
  "Done when <the done-state>, measured against N acceptance criteria."
  Optionally append the delivery preference (Mostly AI / Mostly human /
  Mixed).
- **Plan** — artefact-level. A Plan's unit of shipping is the **delivery
  bundle = one branch, one PR** (§ Plan Schema → Storage, and the
  `/spade-plan` Delivery Bundles section). Write: "M PR(s) across N
  tasks (<effort>)." then name each bundle as `<title> (<branch>)`.

Source every fact from § The Loop, § Plan Schema and the skill Output
Formats — the TL;DR summarises existing fields and introduces none.

### When it prints

Printed on **every run**, in **every mode** (`linear`, `local`,
`hybrid`) — it is stdout, not a stored file, so it is **never gated on a
local write**. Runtime order is:

```text
structured artefact  →  Terminal TL;DR  →  render-and-link footer
```

When a local file was written, the `View in browser: file://…` line
(§ HTML Rendering → Terminal `file://` links) still trails the TL;DR and
remains the **last** line — so each skill's "render-and-link line is the
last step" invariant holds wherever a file was rendered. In `linear`
mode nothing renders, so the TL;DR is naturally the last thing printed,
which is what makes it the always-on closer that mode previously lacked.

### Status

Terminal-only and ephemeral: not persisted, not read back, regenerated
on the next run. A view of the artefact, never a source of truth —
consistent with "Skills never read HTML back; they read .md."

---

## Handoff

`/spade-handoff` hands an approved Plan off to a fresh CLI agent — Claude
Code or Amp — running in its own macOS terminal window. The planning
session stays free; delivery runs in a separate, watchable context.

Handoff is **opt-in**: the `/spade-handoff` skill ships installed but is
**dormant** until a `handoff:` block exists in `.spade/config`. A project
that never opts in is unaffected. `/spade-onboard` offers to write the
block.

### What it is — and is not

The framework **spawns and detaches** the delivery agent. It does not
supervise, restart, or track it — SPADE owns no long-lived process, so
the "no runtime" architecture constraint holds. Delivery re-enters the
loop the ordinary way: the spawned agent opens a PR (one bundle, one
branch, one PR) and the human runs `/spade-evaluate` against it. The
handoff opens no separate audit channel.

`/spade-handoff` is macOS-only — it spawns terminals via `osascript`. On
other platforms it reports that and does nothing.

### Configuration

The committed half lives in `.spade/config` under `handoff:`:

```yaml
handoff:
  agent: claude            # which agent to spawn: claude | amp
  autonomous: false        # false = interactive; true = bypass perms (+ confirm)
```

The launcher owns the fixed invocation contract for each supported agent.
Committed configuration selects only the allowlisted agent and the default autonomy posture.
It cannot provide an executable, arguments, prompt transport, or an autonomy flag.

The machine-specific half — the terminal emulator — lives in the
**gitignored** `.spade/handoff.local` (`terminal: iterm` or
`terminal: terminal`), because one developer's iTerm2 is another's
Terminal.app.

### How a handoff runs

1. `/spade-handoff <ISSUE>` reads `.spade/config`, resolves the agent and
   terminal, and confirms the issue has an approved Plan.
2. It builds a handoff prompt that points the spawned agent at the repo's
   own `AGENTS.md` and architecture docs — SPADE constraint prose is
   **never inlined**, so there is no second copy to drift.
3. It invokes `bin/spade-handoff-launch`, the spawn mechanism, passing
   the allowlisted agent name and terminal as explicit arguments.
   The launcher never parses YAML and rejects arbitrary commands or flags.
4. The launcher opens a new terminal window and runs the agent there.

### Security posture

| Concern          | Stance                                                                 |
|------------------|-------------------------------------------------------------------------|
| Prompt injection | The handoff prompt is opaque data end to end — stdin to a temp file, read back via command substitution, only ever expanded as a double-quoted variable. It is never word-split or re-evaluated, by the launcher or by the generated run script. |
| Autonomy         | `autonomous: true` adds the agent's skip-permission flag, but only after an explicit per-invocation confirmation. The config value is a default, not standing consent. |
| Worktree safety  | The launcher refuses a handoff whose working directory is the same git worktree as the invoking session (two agents, one branch) unless the human confirms, which adds `--force-same-worktree`. |
| Secrets          | No credentials are written into the prompt, the launcher arguments, or `.spade/config`. The spawned agent uses the machine's existing tool configuration. |

Launcher exit codes: 0 success; 1 usage error; 2 not macOS; 3 terminal
app or agent binary missing, or spawn failed; 4 worktree collision
without `--force-same-worktree`. CI exercises the launcher headlessly via
`--dry-run` (`scripts/lint/lint-handoff.sh`).

---

## Trusted lifecycle

`src/CAPABILITIES.md` is the release and installed-capability authority.
Its flat frontmatter declares the canonical remote, immutable commit policy, supported version floor, published version chain, skills, agents, researcher, and helpers.
Plugin manifests, install manifests, the repository pin, and documentation claims are derived from or checked against it.
Global setup records exact SHA-256 projection receipts in machine-local state.
Host-managed plugin revisions embed exact SHA-256 payload claims.
The global receipt is trusted only when it records the exact canonical commit approved before setup.
Plugin self-claims prove content integrity only and diagnostics fail unsupported when the host manager does not expose separate immutable revision evidence.

`bin/spade-lifecycle diagnose` is read-only and emits stable redacted findings for installation identity, exact revision, host inventory, helpers, tracker mode, consumer version, fragments, and renderer availability.
Exit 0 means healthy, exit 1 means drift, and exit 2 means unsupported input.

`migrations/manifest.tsv` stores one explicit transition for every published starting state from the supported floor.
The lifecycle helper treats rows as data and maps only allowlisted action names to bounded Bash implementations.
Each unit is staged and verified before mutation, rolled back on commit failure, and completed by writing the consumer version pin last.

Clone updates fetch only the exact canonical remote and require human approval of one exact fetched commit SHA.
The candidate is fetched and resolved again immediately before a fast-forward merge, and any change requires new approval.
Host-managed plugins are updated only through their host manager.
Diagnostics reject a global or plugin payload when any installed file differs from its receipt or embedded claim.

---

*The SPADE Framework v5.1.0, September 2026, Fusebox HQ*
