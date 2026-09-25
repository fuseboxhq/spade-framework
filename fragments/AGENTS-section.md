# SPADE

This repository uses SPADE.
Humans own the intent (the Scope) and the decision to ship; agents plan, build, review, and verify in between.
The skills carry the procedure, and every SPADE skill ships the full reference as `references/FRAMEWORK.md`, so this section only holds what applies every session.

## What needs the loop

- Work that will land in this repository goes through `/spade` or, when it is small and low-risk, `/spade-quick`.
- Questions, debugging, exploration, reviews, and throwaway spikes need no Scope. If a spike is worth keeping, bring it back through `/spade-quick` or `/spade`.
- When someone asks directly for a small change, take it through `/spade-quick`; do not ask them to write a Scope.

## Keep going or stop

When a step does not need the human, keep going and put status notes in the same message as your next action.
Stop and ask only when you cannot continue without the human, when a SPADE tripwire fires (`references/FRAMEWORK.md` § Tripwires in any SPADE skill), or before anything destructive or outside this repository: deleting data, force-pushing, rewriting history, or changing shared systems.
Write every halt where the work is tracked as well as in the session.

## Hard lines

- On the full loop, do not start delivery without an approved Plan: a human approval, or the machine-recorded one at the Deliver level.
- Do not move a Scope to Done without a recorded PASS.
- Merges follow `autonomy.deliver.merge` in `.spade/config`.
- A SPADE guard deny is a halt: tell the human the reason and do not route around it.
- Before planning, read ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md, and name any conflict in the Plan.

## Writing

Apply `/unslop` to human-facing prose: Scopes, Plans, PR titles and bodies, and reports.
End every run with **Blocked on me**, **Changed**, and **Found**.
