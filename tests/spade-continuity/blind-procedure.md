# SPADE continuity blind procedure (PS-2322)

This is the required independent behavioral gate for resumable runs and learning-candidate capture.
It is a documented procedure rather than an executable implementation because SPADE behavior lives in skill prose and the repository forbids scripts that duplicate that prose.

## Independence requirement

The decider must run in a fresh isolated context that did not author the continuity contract or corpus.
Give it the canonical continuity section from `docs/FRAMEWORK.md` and the canonical `src/skills/spade/references/continuity.md` contract.
For section F cases, also give it `src/skills/spade-learn/references/candidate-capture.md`.
Do not give it the corpus's `expected` cells, its pass criteria, this procedure's comparison rules, or prior decisions from the authoring context.

If an isolated context is unavailable, the gate is not satisfied.
Do not grade the corpus in the authoring context and call it blind.

## Procedure

1. Extract each `given`, `interruption`, or observation cell from [`corpus.md`](./corpus.md) without its identifier or expected result.
2. Give the blind decider one case at a time and ask it to return exactly:
   - structural state: accept, malformed, unsupported, contradictory, or unsafe;
   - action: continue, rerun incomplete stage, halt at human gate, repair with confirmation, restart, cancel, complete, candidate, or no candidate;
   - next boundary or learning route;
   - authoritative evidence that must be read before the action;
   - prohibited actions for that case.
3. Compare the answer with the hidden expected result in the corpus.
4. Record match, pass-with-wording-note, or divergence for every case.
5. Re-run any divergence once in a new blind context to distinguish ambiguous prose from an isolated decider mistake.

## Pass criteria

Pass only when every case matches its expected action class, every discriminating pair in corpus section G remains distinct, and no answer guesses external state or authorizes a silent learning write or destructive dirty-worktree operation.

A wording difference is a pass-with-wording-note only when it preserves the same state classification, next safe boundary, human gate, evidence requirements, and prohibited actions.
A different boundary, permission, write outcome, or freshness decision is a divergence.

Two divergences on the same case fail the gate.
Fix the canonical contract or skill wording, then rerun the affected case and all discriminating pairs that share its rule.

## Evidence record

The delivery record must name:

- the isolated-context mechanism;
- the canonical commit or working-tree head tested;
- every case result;
- any first-pass divergence and the wording change that resolved it;
- the final pass or fail verdict.

Do not include private learning bodies, credentials, tokens, cookies, or other authentication state in the evidence record.
