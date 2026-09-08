# Frontier Map Contract

Read this reference completely before creating, reading, advancing, blocking, or graduating a frontier map.
This contract defines the durable discovery artefact for `/spade-frontier`.
It is a pre-Scope workflow record and is not a `spade-run-state/v1` record or a SPADE phase.

## Purpose and ownership

A frontier map exists only when a human has supplied a meaningful destination but consequential decisions or boundaries prevent a normal Scope from becoming plan-ready in one session.
The human owns the destination, the reason it matters, every consequential human decision, and every graduated Scope's intent.
The agent may structure questions, recommend resolution paths, gather evidence, run bounded disposable prototypes, and draft Scope structure.
The agent must never invent portfolio priorities, business strategy, or the reason the destination matters.

The map is a bounded index.
It names decisions and evidence by canonical pointer instead of copying their bodies into the index, other issues, or graduated Scopes.
Readers load the index first and expand only the selected frontier question, its direct dependencies, and its canonical resolution or evidence pointers.

## Invocation invariant

One invocation performs exactly one of these branches:

1. **No-fog exit.** Determine that no meaningful fog exists, create no frontier artefact, and route directly to `/spade-scope`.
2. **Initial mapping.** Create one frontier index and any resolution records for decisions already made before the invocation, but resolve no open frontier question.
3. **Frontier progression.** Resolve at most one currently visible frontier question, write exactly one canonical resolution record, and update the newly visible frontier.

Graduation is a bounded postcondition of the invocation that resolves the final material question.
It is not a fourth branch or a separate batch-processing invocation.
When an external prerequisite becomes complete, validating its authoritative completion evidence resolves that one blocked question and may trigger graduation as the same invocation's postcondition.

The skill must not batch questions, silently resolve a human-owned question, or make progress from a question whose dependencies are incomplete.

## Meaningful-fog gate

Meaningful fog is an unresolved consequential question that prevents the destination from satisfying at least one existing `/spade-scope` quality condition:

- a required Scope field cannot be stated without guessing;
- an acceptance criterion cannot yet be made individually verifiable;
- an architectural, system, team, security, or ownership boundary is unknown;
- a dependency or feasibility assumption materially changes the Scope;
- the destination cannot yet be split into Scopes that each fit the single-session sizing gate; or
- two or more viable destination boundaries remain and the human has not selected one.

Implementation details that an ordinary Plan can safely decide are not meaningful fog.
When every consequential boundary and decision is clear enough for normal Scope authoring, the no-fog branch must leave no issue, directory, file, comment, mirror, or label behind.

If the destination or business reason is missing, the skill asks the human to author it and writes nothing.
It does not turn an open-ended strategy request into a frontier map.
A candidate open question that names no precise missing decision or fact must be refined before initial map creation.
Do not persist that candidate as a vague question or move it into Unresolved fog as a substitute for refinement.
Unresolved fog is reserved for consequential uncertainty that cannot yet be expressed as a candidate question at all.

## Index schema

Every index has logical schema `spade-frontier/v1`.
Linear stores the same logical fields inside the marked issue body rather than YAML frontmatter.
Local and hybrid index files use this flat field order:

```text
schema: spade-frontier/v1
id: <stable fr- identifier>
name: <safe slug>
title: <human-readable destination title>
status: active | blocked | graduated
revision: <unique opaque revision identifier>
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
linear_issue: none | <tracker issue identifier>
linear_url: none | <canonical tracker URL>
```

Every field is required, including `none` values.
The `id` is `fr-` followed by six lowercase letters or digits and is generated once.
The `name` follows the Local Layout slug grammar and is checked for collision before any local write.
The `revision` changes on every successful index mutation and supports stale-reader detection.
Identifiers are correctness joins, not authorization or trust primitives.

The body contains these sections in this order:

1. `## Destination`
2. `## Decisions already made`
3. `## Question index`
4. `## Unresolved fog`
5. `## Out of scope`
6. `## Current frontier`
7. `## Graduated Scopes`

The destination is the human-authored outcome and reason, not an implementation description.
The decisions section is a table whose rows contain a stable decision id, concise title, owner, status, and canonical resolution pointer.
The question index is a table whose rows contain a stable question id, precise question, dependency ids, resolution path, owner, state, canonical resolution pointer, and unblock condition.
The unresolved-fog section contains only fog that has not yet been expressed as a precise question and must be empty before graduation.
The out-of-scope section states explicit exclusions that discovery must not pull into the destination.
The current-frontier section lists only unresolved questions whose dependencies are resolved and whose blocker is absent.
The graduated-Scopes section is empty until graduation, then contains canonical Scope links and their dependency order.

## Stable identifiers and states

Decision ids use `d-` plus three decimal digits, starting at `d-001`.
Question ids use `q-` plus three decimal digits, starting at `q-001`.
Ids never change or get reused after creation.

Resolution paths use exactly:

- `research`
- `prototype`
- `human-decision`
- `prerequisite`

Ownership uses exactly `ai` or `human`.
Question state uses exactly:

- `open` when dependencies or selection have not yet made the question actionable;
- `frontier` when every dependency is resolved and no blocker remains;
- `blocked` when a named human or prerequisite condition is incomplete;
- `resolved` when one canonical resolution record exists and the index points to it; or
- `out-of-scope` when the human explicitly removes the question from the destination.

An out-of-scope decision is human-owned when it changes the destination boundary.
Removing an indexed question from the destination always uses its own immutable `human-decision` resolution record with human ownership, confirmation, and attribution.
Keep the question row in the index with state `out-of-scope` and the exact canonical record pointer; the `## Out of scope` section may repeat only the question id, concise exclusion, and same pointer, never the decision body.
The question row and resolution record must agree on the question id, pointer, and owner; the record's frontier id must match the index id, and its attribution must match the confirmed human decision.
The out-of-scope entry must agree with the question row and resolution record only on the question id and pointer before the removal is complete.
The index must never report `graduated` while any question is `open`, `frontier`, or `blocked`, or while unresolved fog remains.

## Canonical resolution record

Every resolved decision or question has exactly one active canonical resolution record.
The index contains only a concise label and pointer to that record.
The precise open question remains single-sourced in the index and is not copied into the resolution body.

Each local resolution record uses schema `spade-frontier-resolution/v1` and this flat field order:

```text
schema: spade-frontier-resolution/v1
frontier_id: <fr- identifier>
question_id: <d-NNN or q-NNN>
path: research | prototype | human-decision | prerequisite
owner: ai | human
status: resolved
attribution: <human identifier or machine-attributed>
resolved_at: <UTC ISO 8601 timestamp>
```

The body contains `## Answer`, `## Evidence`, `## Consequences`, and `## Scope impact` in that order.
Evidence is a concise result plus canonical source links, not a copied complete report or retained prototype implementation.
Human-owned records require explicit human confirmation and human attribution.
AI-owned records use machine attribution and must distinguish recommendation from fact.

Resolution records are immutable once active.
If later evidence invalidates a resolution, create a new frontier question that names the contradiction and depends on the earlier decision.
Do not silently rewrite history or repoint a resolved question without a new human-visible question.

## Resolution paths

### Research

Use `/spade-research` for exactly one research question.
Preserve its isolated read-only researcher, source, and one-question contracts.
The complete report remains ephemeral under the research contract unless the human separately chooses its supported tracker persistence.
Before frontier persistence, show the concise proposed answer and cited sources and require the human to confirm that they accurately capture the finding.
Write only the confirmed concise answer, sources, consequences, and Scope impact to the frontier resolution record.

### Prototype

A frontier prototype exists only to produce evidence.
It must be bounded, disposable, and isolated in a temporary location outside the destination repository.
It must not use production data or credentials, mutate production or shared external state, change a repository file, add a dependency, create a schema or migration, deploy, commit, open a PR, or become an imported or retained implementation foundation.
Record the method, bounded input, observation, conclusion, and limitations.
Do not retain the prototype implementation in the frontier artefact or destination repository.

If useful output must be retained, reused, integrated, deployed, or reviewed as code, the work is not a prototype path.
Reclassify it as a prerequisite and route it through a normal SPADE Scope.

### Human decision

Present the precise question, relevant evidence, viable options, trade-offs, and one recommended answer.
Do not preselect the answer.
Persist only the explicit human selection and attribution.
If the human defers, mark the question blocked with the named decision owner and unblock condition.

### Prerequisite

A prerequisite is required work or external state that discovery cannot safely perform.
Any durable or reusable artefact, destination-repository or external-state change, production-data operation, schema or configuration change, or potentially shippable output is a prerequisite rather than discovery.

Link an existing authoritative task or route a sufficiently understood unit through normal `/spade-scope` authoring.
Do not create a Plan task beneath the frontier map and do not deliver the prerequisite inside `/spade-frontier`.
Mark the question blocked until authoritative completion evidence exists.
When that evidence appears, resolving the question records the evidence and resulting answer as one frontier progression invocation.

## Frontier derivation and bounded loading

After an initial map or a successful resolution, recompute question states from the index.
A question is on the current frontier only when every referenced dependency is `resolved` or `out-of-scope`, its own state is unresolved, and its unblock condition is satisfied.
Questions with an unresolved dependency remain `open`.
Questions waiting on a named human or prerequisite condition remain `blocked`.

Load the index first.
For one selected frontier question, load only its canonical dependency records and evidence pointers needed to answer it.
Do not load every historical resolution into context merely because the map is large.

Immediately before any mutation, re-read the canonical index and compare its `revision`, selected question state, dependency states, and resolution pointer with the values used to prepare the answer.
If any value changed, write nothing and ask the human to reload the current frontier.
This is a check-then-act safeguard, not compare-and-swap; Linear comments provide no atomic CAS between the reread, resolution-comment append, and index update.
After a write, read the canonical index and resolution record back and verify the new revision, unique pointer, and derived frontier.
If read-back exposes a concurrent or duplicate answer, halt and surface the contradiction without deleting either artefact.

## Persistence by mode

All modes expose the same logical index, resolution paths, ownership, one-question limit, blockers, frontier derivation, and graduation behavior.
Only storage transport differs.

### Linear

Create one dedicated issue titled `Frontier: <destination>` with an exact `SPADE-FRONTIER v1` marker at the start of the body.
The issue is a discovery map, not a Scope, Plan, phase parent, or Plan-task container.
Do not apply SPADE phase statuses, create Plan sub-issues, or imply that the issue is approved delivery work.

The marked issue body is the canonical index.
Each canonical resolution is one immutable comment headed `SPADE-FRONTIER-RESOLUTION v1 <question-id>`.
The index points to the exact comment URL or authoritative comment identifier.
Do not copy the resolution body into the index or another issue.

Update the index only after the resolution comment succeeds.
If the comment succeeds but the index update fails, report the orphaned comment identifier and stop.
Do not retry by creating a second comment and do not delete shared tracker state automatically.
On every later invocation, compare the map's resolution comments with all index pointers before selecting a question or writing anything.
An unpointed resolution comment for that frontier is an orphaned record: surface its identifier and fail closed without mutation.
Never silently adopt it, repoint the index to it, or delete it; human-directed recovery must resolve the contradiction.

### Local

Write one directory at `.spade/frontiers/<slug>/`.
The index path is `.spade/frontiers/<slug>/index.md`.
Resolution paths are `.spade/frontiers/<slug>/decisions/<question-id>.md`.

Reject an unsafe slug, symlinked path component, duplicate map, duplicate decision path, or mismatched frontier identity without mutation.
Build each complete replacement in a same-directory temporary file, verify its schema and one expected identity, then rename it over the prior index.
Delete only an uncommitted temporary file after a failed verification.
Never delete or overwrite a canonical resolution record.

### Hybrid

The tracker index and resolution comments are canonical and are written and verified first.
After tracker success, mirror the index best-effort to `.spade/frontiers/<slug>/index.md`.
The mirror contains the logical index and canonical tracker pointers but no copied resolution or evidence bodies and no local `decisions/` files.

A mirror failure produces one warning and does not weaken the successful tracker write.
A tracker write failure aborts and must not create a local-only successor.
When the tracker is unavailable, a mirror may show recorded progress but cannot authorize a mutation, resolve a question, or substitute for the canonical answer.

## Graduation

Graduation is eligible only when:

- every question is `resolved` or explicitly `out-of-scope`;
- unresolved fog is empty;
- every prerequisite has authoritative completion evidence;
- every consequential human decision has explicit human attribution;
- the destination can be partitioned into one or more Scopes that each pass `/spade-scope` required-field, verifiability, architectural, and sizing checks; and
- no proposed Scope depends on frontier evidence that lacks a canonical pointer.

Draft the smallest set of vertical Scope candidates that preserves independently valuable outcomes and system or team boundaries.
When several Scopes are required, state their dependency order.
Route each candidate through the existing `/spade-scope` human authoring and persistence contract.
The human confirms each Scope's intent, boundaries, acceptance criteria, consequential decisions, and filing.

After every intended Scope is canonical and readable, add its link and dependency order to the index and set the map status to `graduated`.
Each Scope contains one backlink to the frontier index and concise relevant decision pointers.
Do not copy the complete map or resolution bodies into the Scope.

Graduation must not create a Plan, Plan task, branch, commit, PR, deployment, or implementation code.
It must not approve a Plan, mark a Scope Done, or bypass Scope ownership.
Frontier resolves questions; it never reaches the Evaluate record that a Done rests on.

## Run-state boundary

Frontier invocations do not participate in `spade-run-state/v1`.
That schema requires a stable Scope identity and uses only the existing five-phase vocabulary.
The frontier index is the lightweight resumable discovery record.

When `/spade` encounters meaningful fog before a Scope exists, it may route to `/spade-frontier` and end its provisional pre-Scope attempt without persisting a normal run state.
After graduation, each canonical Scope starts an independent ordinary `/spade` run with its own stable Scope identity.
The Scope backlink is provenance only and does not splice frontier history into run-state history.

Do not add a frontier phase, change `spade-run-state/v1`, or interpret frontier status as permission to plan or deliver.

## Failure and completion

Fail without mutation when the mode cannot be resolved, the canonical store is unavailable, the index is malformed or stale, a pointer is ambiguous, a selected question is not on the frontier, a human answer is missing, a prototype crosses the disposal boundary, or graduation readiness fails.
Name the exact failed check, observed value, expected value, and safe next action.

Every invocation finishes by reporting:

- the canonical map location or the no-fog Scope route;
- whether zero or one frontier question was resolved;
- the current frontier or blocker;
- whether graduation occurred and the canonical Scope links; and
- the next bounded human action.

Completion means the canonical artefact was read back successfully and no implementation output was produced.
