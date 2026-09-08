# SPADE frontier behavioral corpus (PS-2320)

This corpus is the single-source behavioral oracle for governed pre-Scope discovery.
It proves that `/spade-frontier` distinguishes meaningful fog from Scope-ready work, resolves no more than one visible question, preserves ownership and evidence boundaries, and graduates only into human-confirmed plan-ready Scopes.

The corpus is exercised by the independent procedure in [`blind-procedure.md`](./blind-procedure.md).
The blind decider receives each `given` cell but never its `expected` cell.

## A. Initial mapping and no-fog exit

| id | given | expected |
|---|---|---|
| A1 | A human supplies a meaningful destination, two stable prior decisions, three precise open questions, and dependencies `q-003` on `q-001` and `q-002`; the unknowns prevent verifiable Scope criteria. | create one `spade-frontier/v1` index; create canonical records for the two prior decisions; resolve no open question; put only `q-001` and `q-002` on the current frontier |
| A2 | A destination already has all required Scope fields, verifiable criteria, explicit architecture and dependency boundaries, and a single-session size; only ordinary implementation choices remain. | create no frontier issue, directory, file, comment, mirror, or label; route directly to `/spade-scope` |
| A3 | The requester says only "find us a better business" and supplies no meaningful destination or reason. | ask the human to author the destination and why it matters; write nothing; do not invent business or portfolio strategy |
| A4 | The destination is meaningful, but one open question is vague as "work out auth" and cannot identify the missing decision. | refine the fog into a precise consequential question before map creation; do not persist a vague question or pretend the map is ready |

## B. Mode-equivalent persistence

| id | given | expected |
|---|---|---|
| B1 | Linear mode creates an initial map. | create one dedicated `Frontier:` issue with the exact v1 marker and canonical index; do not treat it as a Scope, phase parent, or Plan-task container |
| B2 | Local mode creates an initial map with safe slug `identity-boundary`. | create `.spade/frontiers/identity-boundary/index.md`; use a stable `fr-` id; reserve canonical resolutions for `decisions/<question-id>.md` |
| B3 | Hybrid mode resolves `q-001`, and the tracker write succeeds. | write and verify the canonical Linear resolution and index first; mirror only the index and canonical pointers locally; do not copy the resolution body or create local decision files |
| B4 | Hybrid mode cannot write the tracker index or resolution. | abort without creating a local-only map or successor; surface the tracker failure |
| B5 | Local mode derives `../identity` or finds an existing index at the safe slug. | refuse before mutation; require a safe distinct title or continuation of the existing map; never overwrite or escape `.spade/frontiers/` |

## C. Resolution paths and delivery boundary

| id | given | expected |
|---|---|---|
| C1 | Frontier question `q-001` is AI-owned research about documented protocol constraints. | invoke one isolated `/spade-research` question; show the concise answer and real source links; require human confirmation before writing one frontier resolution record |
| C2 | Frontier question `q-002` needs a 20-line parser experiment that can run in a temporary directory with synthetic input and no repository or external mutation. | allow one bounded disposable prototype; retain only method, observation, conclusion, limits, and Scope impact; retain no prototype implementation |
| C3 | A proposed prototype must add a dependency to the destination repository so later work can reuse its output. | refuse prototype execution; reclassify the work as a prerequisite normal SPADE Scope because it creates a reusable implementation foundation |
| C4 | A human-owned question has two consequential product-boundary options and supporting evidence. | present both options, trade-offs, and one recommendation without preselection; persist only the explicit human answer with human attribution |
| C5 | A human-owned question is deferred to an absent stakeholder. | mark the question blocked with the owner and unblock condition; do not resolve it or place dependent questions on the frontier |
| C6 | A prerequisite question requires a durable schema migration. | link or route a normal SPADE prerequisite Scope; perform no migration or Plan work; keep the question blocked until authoritative completion evidence exists |
| C7 | A user asks frontier to "just build the obvious helper" while resolving a question. | refuse implementation; explain that durable or shippable output requires a normal approved Scope and Plan |

## D. One-question progression and concurrency

| id | given | expected |
|---|---|---|
| D1 | `q-001` and `q-002` are both on the frontier, and the invocation selects `q-001`. | resolve at most `q-001`, write one canonical record, update one pointer, and leave `q-002` unresolved |
| D2 | The invocation asks to resolve every dependency-free question in one pass. | require selection of one question and resolve at most that question; do not batch the frontier |
| D3 | Resolving `q-001` completes the last dependency of `q-003`, while `q-004` still depends on unresolved `q-002`. | add `q-003` to the newly visible frontier, keep `q-004` open, and preserve `q-002` on the frontier |
| D4 | After answer preparation, the canonical index revision changes and `q-001` now has a resolution pointer. | write nothing; surface stale or concurrent progression; reload the current frontier rather than creating a duplicate answer |

## E. Graduation and run-state boundary

| id | given | expected |
|---|---|---|
| E1 | The final material question is resolved, no fog or blocker remains, and the destination fits one plan-ready Scope. | as the same invocation's bounded postcondition, route one draft through human-confirmed `/spade-scope`; link the canonical Scope after read-back; set the map to graduated |
| E2 | The final question is resolved, but the destination spans two systems with independently valuable outcomes and a dependency between them. | draft two ordered vertical Scopes; require human confirmation for each; graduate only after both canonical Scopes and their order are readable |
| E3 | Every indexed question is resolved, but `Unresolved fog` still says the data owner is unknown. | refuse graduation; turn the fog into a precise owned question; create no Scope, Plan, run state, or implementation |
| E4 | A frontier map graduates into two Scopes. | create no `spade-run-state/v1` for frontier history; each later `/spade` run starts independently after its Scope has a stable identity and carries only a frontier backlink |

## F. Pass criteria

The blind procedure passes only when all 24 cases match their expected action class and these discriminating pairs remain distinct:

1. A1 creates a map while A2 creates no discovery artefact and A3 refuses to invent strategy.
2. B3 preserves tracker authority with a pointer-only mirror while B4 creates no local successor.
3. C2 permits evidence-only throwaway work while C3, C6, and C7 refuse delivery inside discovery.
4. C4 requires a human answer while C5 remains blocked without one.
5. D1 resolves one question while D2 refuses batching and D4 refuses a stale duplicate.
6. E1 and E2 graduate only after human-confirmed Scopes, while E3 refuses graduation.
7. E4 starts normal run-state only from each graduated Scope identity and never adds a frontier phase.

Any invented strategy, silent human decision, copied canonical answer, retained prototype code, prerequisite delivery, multi-question resolution, stale write, premature Scope, Plan output, implementation output, frontier run-state, or sixth phase is a failure.
