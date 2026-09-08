# Scope Output Shape

Read this reference when presenting or persisting a completed Scope.
## Output Format

Present the Scope in this format:

```markdown
## Scope: [Title]

**Intent:** [What and why, 1-3 sentences]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Architectural Constraints:**
- [Constraints, or "No additional constraints beyond ARCHITECTURE.md"]

**Dependencies:**
- [Dependency 1, or "None"]

**Context:**
- Upstream: [What feeds into this]
- Downstream: [What depends on this]
- Related: [Other work in the same area]

**Out of Scope:**
- [What this does NOT cover]

**Origin:** [OKR/Milestone | Reactive ticket | Ad-hoc]

**Risk / Unknowns:**
- [Known risks, or "None identified"]

**Delivery Preference:** [Mostly AI-delivered | Mostly human-delivered | Mixed]
```

## Plain-Language Rules

A Scope is written for humans - someone who has never seen the work
should understand it in about 30 seconds. When presenting or persisting
a Scope, hold every field to these rules:

- **Sentence caps.** Intent: 1-3 sentences. Each acceptance criterion:
  one testable sentence. Every other bullet: one sentence, two at most
  when genuinely needed - never a paragraph.
- **No jargon.** No framework or process jargon in any field - plain
  words only. If a constraint relies on a specific technology, pattern,
  or technique, name it and point to where it is defined
  (ARCHITECTURE.md, PATTERNS.md, or the relevant doc) rather than
  explaining it inline.
- **Lead with the outcome.** Say what will be true when the work is
  done, not which activities will happen.
