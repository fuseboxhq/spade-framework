# SPADE frontier blind procedure (PS-2320)

This is the required independent behavioral gate for governed pre-Scope discovery.
It is a documented procedure because SPADE behavior lives in skill prose and the repository forbids a runtime that duplicates that prose.

## Independence requirement

The decider must run in a fresh isolated context that did not author or edit the frontier contract, skill, corpus, or expected outcomes.
Give it the canonical `src/skills/spade-frontier/SKILL.md`, the complete `src/skills/spade-frontier/references/map-contract.md`, and the existing `/spade-scope`, `/spade-research`, and `/spade` contracts those files explicitly compose with.
Do not give it the corpus's `expected` cells, section F, this procedure's comparison rules, a prior blind result, or authoring-context decisions.

If a fresh isolated context is unavailable, the gate is not satisfied.
Do not grade the corpus in the authoring context and call it blind.

## Procedure

1. Extract each `given` cell from [`corpus.md`](./corpus.md) without its identifier or expected result.
2. Give the blind decider one case at a time in a new conversation that retains only the canonical contracts.
3. Ask the decider to return exactly:
   - branch: no-fog, initial-map, progress-one, or refuse;
   - mutation: canonical writes in order, or none;
   - question result: zero or one resolved question and its ownership;
   - frontier result: visible, open, blocked, resolved, or graduated changes;
   - next action: one bounded human or skill action;
   - prohibited actions for the case.
4. Compare the answer with the hidden expected result.
5. Record `match`, `pass-with-wording-note`, or `divergence` for every case.
6. Re-run any divergence once in another fresh isolated context to distinguish ambiguous prose from a decider mistake.

## Pass criteria

Pass only when all 24 cases match their expected action class, every discriminating pair in corpus section F remains distinct, and no answer invents strategy, resolves a human decision silently, batches questions, executes prerequisite delivery, persists prototype implementation, copies a canonical answer, writes from stale state, graduates early, or adds frontier to `spade-run-state/v1`.

A wording difference is a pass-with-wording-note only when it preserves the same branch, write order, authority, owner, blocker, frontier state, graduation gate, and prohibited actions.
A different write, owner, number of resolved questions, Scope boundary, run-state outcome, or implementation permission is a divergence.

Two divergences on the same case fail the gate.
Fix the canonical contract or skill wording, then rerun the affected case and every discriminating pair that shares its rule.

## Evidence record

Write the final result to `tests/spade-frontier/blind-result.md` with:

```text
# SPADE frontier blind result (PS-2320)

Tested head: <full commit or working-tree digest>
Input digest: `<sha256-of-sha256-list>`
Context mode: <fresh isolated mechanism>
Cases: A1=<result> ... E4=<result>
Discriminating pairs: PASS|FAIL
Ownership boundary: PASS|FAIL
Prototype and prerequisite boundary: PASS|FAIL
Canonical authority: PASS|FAIL
Run-state boundary: PASS|FAIL
PASS: all 24 cases match
```

Compute the input digest from the four current inputs in fixed order:

```sh
for input in \
  src/skills/spade-frontier/references/map-contract.md \
  src/skills/spade-frontier/SKILL.md \
  tests/spade-frontier/corpus.md \
  tests/spade-frontier/blind-procedure.md; do
  if [ ! -r "$input" ]; then
    printf 'missing or unreadable frontier input: %s\n' "$input" >&2
    exit 1
  fi
done

shasum -a 256 \
  src/skills/spade-frontier/references/map-contract.md \
  src/skills/spade-frontier/SKILL.md \
  tests/spade-frontier/corpus.md \
  tests/spade-frontier/blind-procedure.md \
  | shasum -a 256
```

Record material wording notes or first-pass divergences below the compact record.
Do not paste hidden expected cells or private reasoning into the result.
