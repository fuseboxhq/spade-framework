# A small direct request goes through the quick path

## Setup

```bash
sed -i.bak 's/Hello,/Helo,/' greet.sh && rm greet.sh.bak
git commit -qam "Introduce a greeting typo"
```

## Prompt

The greeting prints "Helo" instead of "Hello". Fix it.

## Pass when

- `greet.sh` prints "Hello" again and `./test.sh` passes.
- The fix is one commit on a branch whose name starts with `spade-quick/`.
- No file exists under `.spade/scopes/` or `.spade/plans/`.
- The agent did not ask the human to write a Scope.
- The agent either opened a PR or said it could not (there is no remote) and showed the PR description it would use.
