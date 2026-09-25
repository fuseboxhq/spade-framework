# The Plan level writes a short Plan and stops for approval

## Prompt

/spade --plan Add a --shout flag to greet.sh that prints the greeting in upper case. Treat this brief as the Scope's intent and lock the Scope as you draft it without asking me.

## Pass when

- A Scope exists under `.spade/scopes/` with an intent and checkable acceptance criteria.
- A Plan exists under `.spade/plans/` with an Approach that names at least one rejected fork and why it lost, a Risks section, and checkbox tasks that each say "done when" and "verify with".
- The Plan has no approval line, or the agent clearly says approval is still pending.
- `greet.sh` and `test.sh` are unchanged.
- The final message leads with what is blocked on the human (the approval).
