---
title: A guard that inspects shell commands or paths needs a tokenizer, not a substring match
area: delivery
tags: guards, hooks, shell, review, security, spade-guard
created: 2026-09-08
status: active
public_safe: true
scope_ref: PS-3017
---

## What happened

`bin/spade-guard` started life matching shell commands with `grep -E`. Six rounds of
Delivery Review found six separate ways past it, each one real and each one cheap to
type:

1. A quoted flag: `git add "-A"`.
2. A backslash-escaped command name, `\gh pr merge`, and a quoted one, `"gh" pr merge`.
3. A wrapper in front: `env`, `sudo`, `command`, `xargs` — then the same wrappers with
   their own flags, `sudo -n`, `nice -n 10`.
4. An escaped quote inside a double-quoted string, which closed the quote early and hid
   everything chained after the next separator.
5. Then the fixes started causing false positives: a substitution mentioned inside single
   quotes was read as a command, denying ordinary prose.
6. And a fix for that regressed into a bypass, because an apostrophe in `don't` flipped a
   naive single-quote toggle.

Each regex patch closed one hole and left the shape of the next one. The defect only
stopped recurring when the matching was replaced with a quote-aware tokenizer that splits
a command into pipeline segments, resolves escapes, keeps a quoted argument as one token,
lifts command substitutions into their own segment, and compares whole tokens.

## What to do next time

If a hook, guard, or lint has to decide something about a shell command, write the
tokenizer first. A pattern over the raw string is not a cheaper version of the same thing;
it is a different thing that happens to agree on the examples you thought of.

Two smaller lessons worth keeping:

- **A false positive is a real defect, not the safe side.** The guard denied its own
  author's commit message and a read-only probe. "Fails closed" does not excuse blocking
  ordinary work, and the reviewer was right to score it the same as a bypass.
- **Test the fix against the thing you just broke.** Three of the six rounds found a
  defect introduced by the previous round's fix. Every fix in this area needs a fixture
  for both directions: the evasion must deny, and the everyday form must still allow.

## Where the boundary is

None of this makes a guard a sandbox, and `docs/FRAMEWORK.md` § Mechanical guards says so.
A shell can still reach a guarded file another way. The tokenizer is what makes the guard
reliable on the ordinary path; it is not what makes it airtight, and the docs should never
imply otherwise.

## The same mistake twice, in the same file

Hours after v5.0.0 merged, the path classifier turned out to have the identical
flaw in a different guise. It matched category words as substrings, so
`tokenizer.ts` read as credentials because it contains `token`, `processor.ts`
read as authentication because it contains `sso`, and `oracle.ts` read as IAM
because it contains `acl`. Worse, the framework's own layout was treated as
governance everywhere, so in any consumer repository `src/**` was protected and
the fast paths could not touch application code at all.

The fix is the same shape as the command one: split the path into words and
match whole words, and scope the framework-layout paths to the framework
repository. Fixed in v5.0.1 under PS-3026.

The lesson generalises past shell: when a check decides something about
structured text, parse the structure. A substring match is not a cheap
approximation of that, it is a different check that agrees only on the examples
you happened to try.
