---
name: spade-scope
description: Create or edit a SPADE Scope - the human-owned statement of intent, acceptance criteria, and constraints that everything downstream is measured against. Use when someone says "scope this", "create a scope", "edit this scope", "write a scope", or describes non-trivial work they want done but have not written down. Invoked by /spade at every level except Stub.
---

## Mode Resolution

Read `.spade/config` if it exists and resolve `mode:` per `references/FRAMEWORK.md` § Operating modes.
With no config, work as `local` and suggest `/spade-onboard` once.

# SPADE Scope

Help the human write a Scope a Plan can be built and judged against (`references/FRAMEWORK.md` § Scope).
Done means: the Scope is locked by the human and filed (a Linear issue in status Scoped, or `.spade/scopes/<slug>.md`), and every acceptance criterion can be checked by a command or a named piece of evidence.

When `/spade` invokes this skill it has already routed small work to `/spade-quick`; when invoked directly and the work is clearly quick-sized, say so and offer `/spade-quick`.

## How to run it

Draft first.
When the brief carries the intent, draft the whole Scope, show it, and ask one question through `AskUserQuestion`: *Lock this Scope* or *Edit it*.
Ask about a field only when the brief left it genuinely open, one field at a time.
Push vague criteria into checkable ones ("works reliably" becomes "p99 under 200 ms and no dropped records over a 24 hour soak") and suggest the stronger version rather than asking the human to invent it.
Match the depth to the work: a reactive bug fix can take the ticket as its intent and "the bug no longer reproduces, with a regression test" as its criterion.

You may tighten structure (criteria wording, edge cases, constraints) without asking.
You never rewrite intent; a suggestion that changes the outcome, the problem, the user, or the why goes to the human.

If the work spans several systems, teams, or months, propose splitting it into separate Scopes.
If the destination is clear but key decisions are still open, write the Scope with those questions under **Open questions**; a Scope with open questions that block planning is not locked until the human answers them.

Rich references beat description: link the mockup, the failing test, the API spec, or the code to port instead of paraphrasing it.

## Scope format

```markdown
## Scope: <title>

**Intent:** <The outcome and why it matters, in one to three sentences. An outcome, not an activity.>

### Acceptance criteria
1. <Checkable statement: what is observed, where, and how it is checked.>

### Constraints
<Stack, patterns, security or compliance requirements; cite ARCHITECTURE.md or ANTI-PATTERNS.md where relevant, or say "none beyond ARCHITECTURE.md".>

### Dependencies
<What must exist first, or "none".>

### Out of scope
<What this deliberately does not cover.>

### Open questions
<Only when some remain.>

### References
<Links to mockups, specs, tests, or code, when they exist.>
```

Apply `/unslop` to the prose before filing.

## Filing

- **`linear` mode.** Create or update the parent issue with the Scope as its description and status Scoped. Ask who owns it only if `.spade/config` has no `default_assignee`. In a Horizon-bound repository (`horizon:` in `.spade/config`), list the project's Milestones, recommend the best fit, and attach the one the human picks; if none fits, warn that the roadmap item is probably missing and file without one. Never create a Milestone.
- **`local` mode.** Write `.spade/scopes/<slug>.md` with the frontmatter in `references/FRAMEWORK.md` § Local layout. Mint `id` once as `sp-<stem>-<suffix>`: the stem is the slugified title cut to 40 characters, the suffix five random `[a-z0-9]` characters. Refuse a slug that already exists or does not match the slug grammar.
- **Editing.** Given an issue id, URL, or Scope file, load it, point out the weak or missing fields, fix them with the human, and update it in place. The `id` never changes.

When pandoc is installed, render a local Scope with `spade-render <file>` and give the `file://` link.

## Finish

End with the run summary (`references/FRAMEWORK.md` § Run summary).
Under Changed, give the Scope link; the next step is `/spade-plan`, or `/spade` to carry on.
