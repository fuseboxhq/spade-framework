# Onboarding file templates

Use these shapes for new files.
On reruns, preserve valid existing values and content unless the human confirms a change.

## `.spade/config`

For local mode, omit the `linear` block.
For Linear mode, replace every example value with the selected team and project.

```yaml
mode: local

autonomy:
  default: deliver
  size_ceiling:
    tasks: 7
    files: 12
  deliver:
    merge: human
    max_open_prs: 3
```

```yaml
mode: linear

linear:
  team: Example Team
  team_id: <team UUID>
  project: Example Project
  project_id: <project UUID>
  default_assignee: me

autonomy:
  default: deliver
  size_ceiling:
    tasks: 7
    files: 12
  deliver:
    merge: human
    max_open_prs: 3
```

## `.spade/version`

```text
spade_version=<installed version>
```

## `ARCHITECTURE.md`

```markdown
# Architecture

## System boundaries

<Owned components, external systems, and where responsibility changes.>

## Data and control flow

<The flows that constrain changes or failure handling.>

## Deployment and operations

<Runtime, persistence, security, and operational constraints.>

## Decisions and gotchas

<Non-obvious choices, rejected forks, and facts a future Plan must respect.>
```

## `PATTERNS.md`

```markdown
# Patterns

## Required conventions

<Project-specific conventions that are not reliably obvious from nearby code.>

## Verification

<Where checks live, how they are selected, and any non-obvious test boundaries.>

## Decisions

<Approved approaches and why the project chose them.>
```

## `ANTI-PATTERNS.md`

```markdown
# Anti-patterns

## Rejected approaches

<What must not be introduced, with the reason and preferred alternative.>

## Recurring mistakes

<Failures a contributor could repeat even after reading the code.>
```

## `INTENT.md`

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Project intent

## Problem

<The human-confirmed problem this project exists to solve.>

## Users

<Who it serves and who it does not serve.>

## What it does

<User outcomes, without implementation detail.>

## Success

<Observable signs that the project is working.>

## Non-goals

<Explicit boundaries that future Scopes must respect.>

## Maturity

<Prototype, production, maintenance, or sunsetting, with current context.>
```

## Verification skill

Replace every angle-bracketed field with a command or observed outcome that the human confirmed.

```markdown
---
name: verify
description: Verify a change through this project's real build, tests, running product, and user-visible flow. Use before reporting project work complete.
---

# Verify this project

Run from the repository root.

## Build

`<exact build command>`

## Test

`<exact focused and full test commands>`

## Run

`<exact command to start the product and its required services>`

## Drive the app

1. Open `<exact URL or client entry point>`.
2. Perform `<exact user flow>`.
3. Confirm `<visible outcome>`.

Report every command result and mark any step you could not observe as unverified.
```
