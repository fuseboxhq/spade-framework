# Skill Authoring Behavioral Corpus

This corpus is the deterministic review oracle for critical workflow contracts.
Each applicable cell requires a positive control (`P`) and a seeded negative (`N`).
A dash is non-applicable and includes its reason below the matrix.

| Skill | Premature completion | Skipped human gate | Silent no-op | Missing halt persistence | Weakened refusal |
|---|---|---|---|---|---|
| spade | P/N | P/N | P/N | P/N | P/N |
| spade-frontier | P/N | P/N | P/N | P/N | P/N |
| spade-scope | P/N | P/N | P/N | P/N | P/N |
| spade-plan | P/N | P/N | P/N | P/N | P/N |
| spade-approve | P/N | P/N | P/N | P/N | P/N |
| spade-review | P/N | N/A-G1 | P/N | P/N | P/N |
| spade-quick | P/N | P/N | P/N | P/N | P/N |
| spade-onboard | P/N | N/A-G2 | P/N | P/N | P/N |
| spade-update | P/N | P/N | P/N | P/N | P/N |
| spade-evaluate | P/N | P/N | P/N | P/N | P/N |
| spade-unhinged | P/N | P/N | P/N | P/N | P/N |

N/A-G1: `spade-review` is advisory and owns no human approval gate.
N/A-G2: `spade-onboard` provisions project state and owns no human approval gate.

The executable contracts in `tests/skill-authoring-contracts.tsv` bind every P/N cell to an exact canonical anchor.
`tests/skill-authoring-behavior.sh` proves the current skill passes each positive control and that deleting each load-bearing anchor makes the corresponding mutated fixture fail.
The same contract file contains one terminating-completion predicate for every
governed skill.
Advisory skills such as `leads`, `unslop`, and `spade-research` stay outside the critical-skill matrix but still require that terminating-completion predicate.

## Positive controls

- SA-P1: completion names the created or updated artefact and its verification result.
- SA-P2: human-owned gates stop or carry an explicit Deliver-level machine attribution.
- SA-P3: every action step names observable state, evidence, or a command result.
- SA-P4: every halt is recorded both in-session and on the canonical artefact.
- SA-P5: invalid mode, path, permission, malformed marker, or stale state refuses safely.

## Seeded negatives

- SA-N1: delete the final verification predicate and claim completion after the last action verb.
- SA-N2: replace a human decision or explicit Deliver attribution with unconditional continuation.
- SA-N3: replace an observable action with "ensure this is correct".
- SA-N4: remove the durable halt record and leave only an unanswered prompt.
- SA-N5: replace a fail-closed refusal with best-effort continuation.

## Semantic drift seeds

- SA-D1: add a second normative copy of the merge gate to a host adapter.
- SA-D2: change only the Codex projection to widen permissions.
- SA-D3: edit a generated skill without changing `src/`.
- SA-D4: leave an unresolved host token in a projection.

All four seeds must make the authoring or projection checks fail.
