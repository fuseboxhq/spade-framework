---
name: spade-evaluate
description: Check delivered work against its Scope's acceptance criteria with fresh evidence and record a PASS, PARTIAL, or FAIL verdict. Use when delivery is complete, someone says "evaluate this", "is this done", "verify the output", or when /spade reaches Evaluate. Handles full-loop Scopes and spade:quick PRs.
---

## Mode Resolution

Read `.spade/config` if it exists and resolve `mode:` per `references/FRAMEWORK.md` § Operating modes.
With no config, work as `local`.

# SPADE Evaluate

Judge the delivered head against the Scope, not against the Plan or the agent's own account of the work (`references/FRAMEWORK.md` § Evaluate).
Done means: an evaluation with one evidence row per acceptance criterion and a verdict, recorded by you when guards are live and every row is met with fresh evidence, otherwise recommended to the human and recorded by them.

## Quick-path items

For a `spade:quick` issue or PR there is no Scope or Plan.
Check the PR's checks, that its template is filled in, and that the diff still fits the quick path: no new dependency, no schema, migration, or data-layer change, no auth, crypto, secrets, or permission change, no public interface break.
PASS needs the PR merged with green checks, and closes the issue; for a PR still open, report what is left and leave the issue open.
PARTIAL means a small follow-up: new commits on the same PR if it is still open, or a new `/spade-quick` PR that references it if merged.
FAIL means the quick path was misused: say which line it crossed and recommend taking the work through `/spade`.

## Full-loop items

1. Read the Scope and the Plan (`.spade/plans/<scope-key>.md`).
2. Resolve the reviewed head SHA. Make sure a Delivery Review exists for exactly base..head; if it is missing or tied to another head, run `/spade-review` in Delivery Review mode.
3. For each acceptance criterion, gather evidence against that head: run the command the Plan names under "verify with", read the code, or drive the product for anything with a UI (the project's verification skill, if it has one, is the right tool). Record the command and its result, or the file and line, or what you looked at.
4. Mark each row met, not met, or unconfirmed. Unconfirmed says where you looked. A criterion that depends on external state (a production metric, a stakeholder sign-off) stays unconfirmed until an authoritative source or the human confirms it.
5. Decide the verdict from the rows and the open blocking findings in the Delivery Review.

```markdown
## Evaluation: <Scope title>

Reviewed head: <sha> (Delivery Review: <report path>, <n> blocking findings open)

| # | Criterion | Evidence | Status |
|---|---|---|---|
| 1 | <criterion as written> | <command and result, file:line, or what was checked> | met / not met / unconfirmed (where you looked) |

**Verdict:** PASS | PARTIAL | FAIL - <one line why>
**Recorded by:** agent | <human name>
**Needed to pass:** <only when not PASS>
```

Apply `/unslop` to the prose, not to commands, SHAs, or the table values.

## Recording the verdict

Record the verdict yourself only when guards are live (`.spade/guard/$CLAUDE_CODE_SESSION_ID/live` exists), every row is met with evidence fresh on the reviewed head, and no blocking review finding is open.
When you record it and the work has a PR, write `.spade/guard/reviewed-head-<pr>` through `exec_command` as one line, `<reviewed head sha> <VERDICT>`, so the merge guard can check it (`references/FRAMEWORK.md` § Mechanical guards).

Otherwise ask the human through `request_user_input when available, otherwise a concise direct question`: *PASS*, *PARTIAL*, or *FAIL*, with your recommendation first and a plain statement when the evidence does not support PASS.

Then:

- Post the evaluation on the Scope issue (`linear`) or append it to the Plan file (`local`).
- PASS moves the Scope to Done.
- PARTIAL or FAIL leaves it in Evaluating: small defects go back to delivery, a wrong approach goes back to `/spade-plan`.
- A commit after evaluation makes the verdict stale.

If the evaluation surfaced a gotcha a future Plan should know, offer `/spade-learn` with a drafted entry.

## Finish

End with the run summary (`references/FRAMEWORK.md` § Run summary).
