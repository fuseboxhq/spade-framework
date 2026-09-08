# Prior Learning Matching

Read this reference completely only when `.spade/learnings/` exists and matching must run.
### Prior Learnings Considered

If any `.spade/learnings/*.md` entries matched the Scope (see "Before You
Start" step 3), include a **Prior Learnings Considered** section near the
top of the Plan. Each matched learning gets:

1. The learning's title (verbatim, from its frontmatter).
2. Its filename in parentheses, e.g. `(2026-04-22-onboarding-must-be-idempotent.md)`.
3. A one-line note on how the Plan honours it.
4. **A match-reason log line (v1.1.1)** underneath, showing *why* the
   learning surfaced. This lets a human scanning the Plan see when
   matching is off:
   - `Match reason: scope_ref=<ID>` when the scope_ref path fired.
   - `Match reason: tags matched [<tag1>, <tag2>, ...]` when the tag
     path fired — list only the tags that actually matched the Scope
     title / tech stack, not the entry's full tag set.

If a matched learning has `status: archived`, do not include it.
(The framework has no "supersedes" field — `/spade-learn --refresh`
resolves conflicts by archiving the superseded entry explicitly, so
the archived filter is the single source of truth.)

If no entries match, do not include the section at all. Silence is
cheaper than padding — no "no matches found" line.

Example (cold-start regime, one-tag match):

```markdown
### Prior Learnings Considered

- *Any write into a consumer file must be idempotent via delimited markers*
  (`2026-04-22-onboarding-must-be-idempotent.md`) — Plan Bundle A extends
  the existing `spade-marker-replace` contract rather than inventing a
  new mechanism.
  Match reason: tags matched [markers]
```

Example (scope_ref match):

```markdown
### Prior Learnings Considered

- *For review and evaluation gates, a panel of persona-specific reviewers
  beats one generalist*
  (`2026-04-22-single-reviewer-is-weaker-than-panel.md`) — this Scope
  preserves the panel shape; only adds verifiability layers.
  Match reason: scope_ref=M-323
```
