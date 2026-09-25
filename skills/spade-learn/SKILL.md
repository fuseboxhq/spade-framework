---
name: spade-learn
description: Capture or refresh a repository gotcha that a future SPADE Plan should know. Use for failed assumptions, recurring pitfalls, new constraints, corrections, or a request to record what the team learned.
---

# SPADE learn

A learning is knowledge that should change a future Plan.
Capture a failed assumption, recurring pitfall, new project constraint, or correction to an earlier learning.
Do not capture generic advice, completion summaries, ordinary successful checks, or facts the code already makes clear.

Run in capture mode by default.
Use `--refresh` only to review existing entries for stale or contradictory guidance.

## Storage

Public learnings live at `.spade/learnings/YYYY-MM-DD-<slug>.md`.
Private learnings live at `.spade/learnings/private/YYYY-MM-DD-<slug>.md` and must remain gitignored.

Use the frontmatter from `references/FRAMEWORK.md` § Learnings:

```yaml
---
title: One-line summary
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active
public_safe: true | false
scope_ref: <optional Scope id>
---
```

The body has two short sections:

```markdown
## What we learned

<The specific fact and the evidence that established it.>

## Why it matters for future work

<What a future Scope or Plan should do differently.>
```

## Capture

1. Draft one learning from the conversation, Scope, Plan, review, failed check, or explicit correction.
2. Name the evidence and the concrete effect on future planning.
3. Read active public and private learnings and check for the same fact or instruction.
4. If an active entry already says the same thing, do not create another file.
5. If new evidence corrects an active entry, stop and offer a targeted `--refresh` instead of leaving both active.
6. Apply `/unslop` to the draft before writing it.

Classify the draft as public-safe when it contains no internal systems, customer details, credential paths, security details, private discussion, or other information that should not leave the repository.
Classify it as private when any of those appear.

When public safety is unclear, ask through `AskUserQuestion` with exactly these choices:

- `Public-safe`
- `Private`
- `Skip`

Do not ask that question when the classification is clear.
`Skip` writes nothing.

Choose a short lowercase slug that matches `^[a-z0-9][a-z0-9-]{0,63}$`.
Create parent directories when needed.
For a public learning, include it with the work that produced it when practical.
For a private learning, do not stage or commit it.

## Refresh

With `--refresh`, read active public learnings and private ones only when the human includes them.
Compare each entry with current code, docs, decisions, and other active learnings.
Flag entries that are stale, contradicted, duplicated, or narrowed by newer evidence.

For each proposed change, show the evidence and the exact diff.
Use `AskUserQuestion` to confirm before setting `status: archived` or revising an active entry.
Archive stale, contradictory, or superseded entries rather than deleting them.
Preserve the original `created` date when revising an entry.
Never move private content into the public directory without explicit approval.

## Completion

Check that the title stands alone, the evidence is specific, the implication changes future planning, the frontmatter is flat and valid, and the selected store matches `public_safe`.

End with:

- **Blocked on me**: a required safety or refresh decision, or `nothing`.
- **Changed**: the learning created, revised, or archived, or `nothing`.
- **Found**: duplicates, contradictions, or facts that still need evidence, or `nothing`.
