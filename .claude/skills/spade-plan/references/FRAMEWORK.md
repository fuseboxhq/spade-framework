# The SPADE Framework

SPADE is a human-AI operating model for engineering work.
Humans own the edges: what to build and why (the Scope), and the decision to ship.
Agents own the middle: planning, building, reviewing, and verifying against the Scope.

This is the reference.
README.md is the quick start, and AGENTS.md holds the short rules agents load every session.
Skills link here with `§ <section>` and do not restate what is defined here.

## Why it works

Current models do their best work when they are told what done looks like, when to stop and ask, and are then left to run.
They do their worst work when nobody decided what to build, when the finish line is vague, or when they grade their own homework.
SPADE puts the human where intent and taste are decided, makes the finish line explicit (acceptance criteria), and keeps verification independent of the agent that built the change.

It also leaves a trail.
Every delivered change traces back through Scope, Plan, approval, the PR, and the Evaluate record, so someone can later explain why the code looks the way it does.

## The loop

```
SCOPE -> PLAN -> APPROVE -> DELIVER -> EVALUATE -> SHIP
 human    AI     human*      AI         AI*        human
```

`*` At the Deliver autonomy level with guards live, Approve is machine-recorded and Evaluate is agent-recorded when every criterion has fresh evidence.
Both stay human on the Plan and Scope levels and whenever guards are not live.

Evaluate failures loop back: small defects to Deliver, a wrong approach to Plan.

### Scope

A Scope says what outcome is wanted and why, and how anyone will know it is done.
It has an intent (outcome, not activity), acceptance criteria that can each be checked by a command or a named piece of evidence, constraints, dependencies, and what is out of scope.
The acceptance criteria are the finish line: Deliver runs until they are met with evidence.

Scope authoring is draft-first.
When the brief already carries the intent, the agent drafts the whole Scope and asks one confirm (lock or edit).
It probes only the fields the brief left open.
A Scope is nailed when every required field is filled and every acceptance criterion is individually verifiable; higher autonomy never lowers that bar.

The agent may improve structure (criteria wording, edge cases, constraints) without asking.
It never rewrites intent: a change to the outcome, the problem, the user, or the why is a strategic-fork tripwire.

### Plan

The Plan is written for the human who approves it.
It is short and lives at `.spade/plans/<scope-key>.md`, where `<scope-key>` is the tracker identifier (for example `PS-2400`) or the local Scope slug.

```markdown
# Plan: <Scope title>

Scope: <link or path>
Approved by <human name | Deliver auto-approval>, <date>.

## Approach
What we will build and how, in a few sentences.
Rejected forks, each with the reason it lost.

## Risks
Assumptions and unknowns that could sink the work.

## Tasks
- [ ] 1. <outcome> - done when <observable result>; verify with <command or evidence>.
- [ ] 2. <outcome> (human) - done when ...

## Bundles
Only when the work needs more than one PR: which tasks go in which PR, and why.

## Halts
Tripwire halts and how they were resolved.
```

Tasks are vertical slices with observable results unless a preparatory task says what it enables.
Mark tasks that need a human with `(human)`.
There is no fixed task count; `autonomy.size_ceiling` decides when a Plan is big enough to need human eyes.
Before planning, read ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md, and matching learnings (§ Learnings), and name any conflict in the Plan.

The Plan file is the working checklist.
Deliver ticks tasks as they finish and commits the file on the delivery branch, so it survives context compaction and doubles as the resume point.
In `linear` mode the Plan is also posted as a comment on the Scope issue when it is written, and the final state is posted when the run ends.
SPADE creates no per-task sub-issues.

### Approve

At the Plan level `/spade` runs the review first, then asks the human to approve, revise, or reject; `/spade-plan` run on its own offers the review before asking.
Approval records a line in the Plan file and, in `linear` mode, moves the issue to Delivering.
A rejected Plan is revised against the human's feedback and shown again.
Approval is a real check: does it fit the architecture, are there gaps, are the assumptions sound, is the breakdown sensible.

On the Deliver level the orchestrator records a machine-attributed approval instead (§ Deliver).
It covers the Plan only; it never authorises a merge.

### Deliver

Delivery works through the Plan's tasks in order, one bundle (one branch, one PR) at a time; the default is one bundle per Scope.
Commit as you go, tick the task in the Plan file, and run the relevant tests before ticking.
Broad mechanical work (a rename across many modules, a migration across many services) can fan out to isolated agents, each in its own worktree; check each agent's evidence before accepting its result.

If delivery shows the Plan is wrong, stop, say what broke, and say whether the Plan or the Scope needs to change.

§ The Deliver level covers what the unattended Deliver autonomy level adds.

### Evaluate

Evaluate checks the delivered head against the Scope.
It records one row per acceptance criterion:

| Criterion | Evidence | Status |
|---|---|---|
| AC text | command and result, file and line, or screenshot, fresh on the reviewed head | met, not met, or unconfirmed (say where you looked) |

External-state and human-only criteria (a stakeholder sign-off, a production metric) stay unconfirmed until their owner confirms them.
Findings from the Delivery Review feed the verdict.

The verdict is PASS, PARTIAL, or FAIL.
The agent records it itself when guards are live (§ Mechanical guards), every row is met with fresh evidence on the reviewed head, and the Delivery Review has no open blocking finding.
Otherwise the agent recommends a verdict and the human records it.
Whoever records PASS moves the Scope to Done; PARTIAL, FAIL, or any unconfirmed row leaves it in Evaluating.

When Evaluate records its own verdict for a PR, it writes `.spade/guard/reviewed-head-<pr>` as `<head sha> <VERDICT>` so the merge guard can check it.

Quick-path work evaluates the PR directly: merged, checks green, PR checklist complete.

### Ship and merge policy

The human owns Ship and sets the merge policy in `.spade/config`:

- `autonomy.deliver.merge: human` (the default): the human operates the merge.
  With guards live, agent merge commands are denied.
  Without guards live, the human may still ask the agent to merge once checks are green.
- `autonomy.deliver.merge: on-green`: the agent may merge a PR whose recorded verdict is PASS on the current head, whose checks are green, with the merge pinned to that head (`gh pr merge <pr> --match-head-commit <sha>`).
  The guard enforces every condition.

A merge authorisation covers the merge only; deploys need their own.

## Autonomy levels

`/spade` takes one piece of work as far as the chosen level allows.
The level comes from a flag (`--deliver`, `--plan`, `--scope`, `--stub`), else `autonomy.default` in `.spade/config`, else a one-question picker.

| Level | Travels | Halts |
|---|---|---|
| Deliver | Scope, Plan, review, code, PR, checks, Delivery Review, Evaluate | before merge under `human`; merges under `on-green` with guards live |
| Plan | Scope, Plan, review | at the Approve gate |
| Scope | Scope | after the Scope is locked |
| Stub | a title and one-line placeholder | immediately |

Before authoring a Scope, `/spade` checks the fast-track gate (§ Fast-track) and routes small work to `/spade-quick`.

### Tripwires

Between a locked Scope and the level's halt point, `/spade` keeps going without asking unless a tripwire fires:

1. **Strategic fork.** Two viable options differ materially (cost, reversibility, architecture, user-visible behaviour) and the Scope does not choose between them. A choice with an obvious default is not a fork: pick it and note why.
2. **Blocking review finding.** A reviewer reports a problem it would block the merge for and the fix changes the approach.
3. **Architecture conflict.** The Scope or Plan conflicts with ARCHITECTURE.md, ANTI-PATTERNS.md, or a stated constraint.
4. **Unverifiable criterion.** An acceptance criterion cannot be checked by a command or named evidence.
5. **Size ceiling.** The Plan exceeds `autonomy.size_ceiling` (default 7 tasks or 12 changed files).
6. **Security-sensitive path** (Deliver only). The diff touches § Security-sensitive path surface. With guards live, only secrets and credentials, production data, and permission widening halt before code; other categories are listed under **Protected paths** in the PR body. Without guards live, any category halts.

A halt goes to the human in the session and is also written where the work is tracked (a Scope issue comment in `linear` mode, the Plan file's Halts section in `local` mode), so a human who is not watching still sees it.
When unsure whether something is a tripwire, halt: a false halt costs one message.

### Keep going or stop

When a step does not need the human, keep going, and put status notes in the same message as the next action.
Do not stop to summarise, offer to continue, or list options that do not block the work.
Stop and ask only for a tripwire, when you cannot continue without the human, or before anything destructive or that changes state outside the repository: deleting data, force-pushing, rewriting history, or changing shared systems. Read-only checks outside the repository (identity, permissions, status) do not need a stop.

### Run summary

Every run ends with three short sections, in this order:

- **Blocked on me**: decisions or approvals the human owes, or "nothing".
- **Changed**: what landed, with links (Scope, Plan, PR).
- **Found**: anything surprising, unconfirmed, or worth a Lead or a learning.

### The Deliver level

Deliver writes code and opens a PR without stopping at the Approve gate.
Everything above still applies; this is what it adds.

1. **Scope, Plan, review.** Author and lock the Scope, write the Plan, then run one `/spade-review` pass over Scope and Plan together. A blocking finding is tripwire 2.
2. **Auto-approve.** Record `Approved by Deliver auto-approval, <date>` in the Plan with the review result and a one-line architecture check. This approves the Plan only. In `linear` mode post the Plan on the Scope issue and move it to Delivering.
3. **Arm the guard.** If `.spade/guard/$CLAUDE_CODE_SESSION_ID/live` exists, guards are live. Write `deliver` to `.spade/guard/$CLAUDE_CODE_SESSION_ID/mode` and remove it on every exit (halt, abort, merge).
4. **Fix the base.** Record the exact base commit SHA the review range will start from.
5. **Build.** Deliver the tasks (§ Deliver), checking tripwire 6 as the diff takes shape.
6. **Open the PR.** Refuse to open one when the project already has `autonomy.deliver.max_open_prs` (default 3) open Deliver PRs; halt instead. The PR body leads with the approach, the rejected forks and why each lost, and the calls the agent made on its own, then a **Protected paths** section (touched categories, or `none`). Apply `/unslop` to the title and body.
7. **CodeRabbit, if present.** Wait for one CodeRabbit pass (at most 10 minutes). Apply only small local fixes that do not add files or touch dependencies, permissions, security-sensitive paths, or agent-behaviour files; leave everything else on the PR. CodeRabbit never replaces the Delivery Review.
8. **Checks and Delivery Review.** Resolve the final head SHA, run the project's checks, and run `/spade-review` in Delivery Review mode on exactly base..head.
9. **Evaluate.** Run `/spade-evaluate` on the reviewed head.
10. **Merge or halt.** Under `on-green` with guards live and a recorded PASS on the current head, merge pinned to that head. Otherwise halt for the human. Any commit after review makes the review, the checks, and the verdict stale; rerun them before merging.

An abort signal (`.spade/abort`, or `autonomy.deliver.abort: true`) is checked between steps; on abort, stop and leave the work in place.

## Fast-track

`/spade-quick` handles small changes without a Scope or Plan; the PR description is the audit record.
Use it when the change is one concern, fits in one reviewable commit, and existing tests cover the area.
Never use it when the change adds a dependency, touches a schema, migration, or data layer, touches auth, crypto, secrets, or permissions, or breaks a public interface.
Anything else that feels bigger than a quick fix goes through `/spade`.

In `linear` mode the Scope-less issue gets `spade:quick` and one `type:*` label (`bug`, `tweak`, `chore`, `docs`, `refactor`) and closes when the PR merges green.
Incidents use the full loop.

## Work that needs no Scope

Questions, debugging, exploration, reviews, and throwaway spikes need no Scope.
Only work that will land in the repository goes through `/spade-quick` or `/spade`.
If a spike turns out to be worth keeping, bring it back through one of them.
When someone asks directly for a small change, take it through `/spade-quick`; do not ask them to write a Scope.

## Review

`/spade-review` gives an independent opinion from agents that did not write the work.
Reviewers run in isolated contexts with read-only tools (the `spade-reviewer` agent).

Every reviewer reports only problems it would block the merge (or the Plan) for.
Each finding gives the file and line (or Scope/Plan section), why it is wrong, and how to show it fails.
Anything the reviewer suspects but could not confirm goes in a separate unconfirmed list with where it looked.
Style preferences and nits are left out.

The default is one reviewer.
Add lens reviewers in parallel only when the change carries that risk:

| Lens | Add when the change touches |
|---|---|
| security | auth, secrets, crypto, permissions, input handling, supply chain |
| data | schemas, migrations, backfills, production data |
| delivery | queues, retries, webhooks, idempotency, ordering |
| operability | deploys, config, alerting, rollout, anything run in production |
| architecture | new patterns, new dependencies, cross-module boundaries |
| adversarial | a Plan whose premise could be wrong, or a large irreversible change |

When ANTI-PATTERNS.md has many rules, split them across reviewers so each rule gets a clean look.

The coordinator checks each finding's evidence before accepting it, drops duplicates, and presents what survives.
Findings are advice; tripwire 2 decides whether a finding halts an unattended run.

**Delivery Review** reviews a fixed commit range, base..head, against two questions: does the diff meet every acceptance criterion, and does it meet the repository's own standards (ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md, existing conventions, checks).
Record the base and head SHAs with the report.
A later commit makes the review stale.
An uncommitted working tree gets a provisional review that cannot support PASS.

Reports are saved under `.spade/reviews/` (gitignored).

## Security-sensitive path surface

This is the single definition of security-sensitive work for every SPADE workflow.
Classify each changed or proposed path, with its purpose, against every category.
The surface fails closed: a path that cannot confidently be placed outside every category is protected.

1. **Authentication and identity.**
   Auth, authentication, authorisation, session, identity, and login boundaries.
2. **Secrets and credentials.**
   Secrets, credentials, tokens, environment-secret material, private keys, certificates, and key stores.
3. **Cryptography.**
   Encryption, decryption, signing, verification, hashing used as a security control, and key management.
4. **Permissions and IAM.**
   Access control, roles, policies, RBAC, permission grants, `.claude/settings.local.json`, and any permission widening.
5. **Schemas.**
   Application, database, event, API, and infrastructure schemas whose change affects persisted or trusted structure.
6. **Migrations and backfills.**
   Schema migrations, data migrations, backfills, and lifecycle migration definitions.
7. **Production data.**
   Paths or commands that read, write, transform, export, delete, or repair production data.
8. **CI.**
   Workflow definitions, CI scripts, runner permissions, and CI credential or execution configuration.
9. **Release.**
   Version authority, release manifests, changelogs used by release tooling, release provenance, and publication configuration.
10. **Deploy.**
    Deployment scripts, deployment configuration, rollout controls, and production environment definitions.
11. **Infrastructure.**
    Infrastructure-as-code, cloud resource definitions, network and platform policy, and privileged operational configuration.
12. **Kubernetes.**
    Manifests, operators, admission policy, RBAC, namespaces, and cluster configuration.
13. **Helm.**
    Charts, templates, values that affect deployed resources, and release hooks.
14. **Framework governance, execution, and fetch surfaces.**
    Consumer framework-marker regions; `docs/FRAMEWORK.md`; root governing files including `AGENTS.md`, `CLAUDE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`, and `INTENT.md`; canonical and generated skill contracts; `src/CAPABILITIES.md`; `setup`; `setup.ps1`; `bin/**`; lifecycle and release manifests; anything changing what `spade-update-check` fetches; and `.spade/config`.

## Mechanical guards

Rules that need no judgement are enforced by Claude Code command hooks driven by `bin/spade-guard`, not by prose.
A guard is a deterministic check over the tool call's input plus named local state (a marker file, a `.spade/config` key, or the PR's check status from `gh`).
It never weighs a trade-off or reads the conversation.

| Guard | Fires on | Denies when |
|---|---|---|
| Protected path | `Edit`, `Write`, `MultiEdit`, `NotebookEdit` | `.spade/guard/<session_id>/mode` exists. In `quick` mode any path matching the fourteen categories denies. In `deliver` mode only secrets and credentials, production data, and permission widening deny; permission widening covers `.spade/config`, `.claude/settings*.json`, `hooks/hooks.json`, `bin/spade-guard`, and any path whose purpose grants or widens a permission. |
| Merge policy | `Bash` running `gh pr merge`, `glab mr merge`, or a `gh api` merge | `autonomy.deliver.merge` is `human` or absent. Under `on-green`, denies unless the PR is not a draft, is mergeable, has at least one check and every check is SUCCESS or SKIPPED, `.spade/guard/reviewed-head-<pr>` reads `<head sha> PASS` for the current head, and the command pins that head with `--match-head-commit` and a literal SHA. `glab` is not verified and denies under `on-green`. |
| Stage all | `Bash` running `git add -A`, `--all`, or `.` | `guards.deny_stage_all: true`. Off by default. |

**Markers.** `SessionStart` writes `.spade/guard/<session_id>/live`; `SessionEnd` removes the session directory.
`/spade` Deliver and `/spade-quick` write `.spade/guard/<session_id>/mode` at start and remove it at close, using `CLAUDE_CODE_SESSION_ID`.
`.spade/guard/` is gitignored.
A missing marker means guards are inert, never that something is allowed.

**Guards live or not.** Guards are live when `.spade/guard/<session_id>/live` exists.
Only then do the lighter rules apply: the narrowed tripwire 6, the agent-recorded Evaluate verdict, and merge under `on-green`.
Without it (Codex, a Claude session without the hooks, or a repository without `.spade/config`), any security category halts before code and the human merges.

**A deny is a halt.** Tell the human the reason and wait.
Do not remove a marker, edit the guard or the config, or reach the same file another way.
A human may disarm a guard for one run; note it in the Plan's Halts section.

**Limits.** Guards are not a sandbox; they catch the ordinary tool path.
Paths are split into words at non-alphanumeric and camelCase boundaries and matched as whole words, so `access-token.ts` matches `token` and `tokenizer.ts` does not.
`key` counts as a credential only beside a credential word such as `api`, `private`, or `ssh`.
Well-known credential files (`id_rsa`, `authorized_keys`, `.npmrc`, `.netrc`, `kubeconfig`) are named directly.
A check that needs a literal value, such as the merge head pin, fails rather than trusting a command substitution.

**The framework's own layout.** `src/`, `skills/`, `agents/`, `plugins/`, `fragments/`, `hooks/`, `bin/`, `setup`, and the generated host trees are governance surfaces only inside this repository (detected by `src/CAPABILITIES.md` and `src/skills/` both existing).
In a consumer repository `src/` is application code.

**Where they ship.** The Claude plugin carries `hooks/hooks.json` and `scripts/spade-guard`, and this repository registers the same hooks in `.claude/settings.json`.
A clone install ships `~/.spade/bin/spade-guard` without registering hooks; to opt in, copy the entries from `src/hooks/hooks.json` into `~/.claude/settings.json` with the command `~/.spade/bin/spade-guard`.
Codex has no hook surface.
`tests/hooks/guards.sh` pins the guard's behaviour; change this section and the guard together.

## Operating modes

`.spade/config` sets `mode:`:

- `linear`: Linear is the system of record for Scopes and Plan comments; the Plan file still lives in the repository.
- `local`: everything lives under `.spade/`.

`hybrid` is accepted as a legacy alias for `linear`.
When `mode:` is absent, use `linear` if the Linear MCP server answers and knows the configured `linear.team_id`, otherwise `local`.
When `mode: linear` is explicit and Linear is unreachable, say so, then keep going with local files and note it in the run summary.

In `linear` mode, parent issues are Scopes, and their status follows the loop: Scoped, Planning, Approval, Delivering, Evaluating, Done.
Never create a Linear Milestone; that is a human roadmap decision.

### Local layout

| Artefact | Path |
|---|---|
| Scope | `.spade/scopes/<slug>.md` |
| Plan | `.spade/plans/<scope-key>.md` |
| Learning | `.spade/learnings/YYYY-MM-DD-<slug>.md` (`private/` is gitignored) |
| Review report | `.spade/reviews/` (gitignored) |

A slug matches `^[a-z0-9][a-z0-9-]{0,63}$`; input that cannot make a valid slug aborts rather than writing outside `.spade/`.

Scope files carry flat YAML frontmatter:

```yaml
---
name: <slug>
id: sp-<stem>-<5 random [a-z0-9]>
title: <title>
status: scoped | planning | approval | delivering | evaluating | done
type: feature | bug | chore | docs | refactor | investigation
created: YYYY-MM-DD
updated: YYYY-MM-DD
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
linear_issue: <id, when a tracker exists>
---
```

`lint-local-frontmatter.sh` enforces the `status`, `type`, and `priority` values.

### Horizon roadmap binding

A repository whose Linear project feeds a Horizon roadmap board declares a `horizon:` block in `.spade/config`.
Then every Scope belongs to exactly one existing Linear Milestone; `/spade-scope` recommends one and warns (does not block) when none fits.

## Learnings

A learning is a repository gotcha that a future Plan should know: a failed assumption, a pitfall that recurred, a new constraint, or a correction to an earlier learning.
Generic advice and anything the code already shows are not learnings.

Learnings live in `.spade/learnings/YYYY-MM-DD-<slug>.md` with flat frontmatter:

```yaml
---
title: One-line summary
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active | archived
public_safe: true | false
scope_ref: <optional Scope id>
---
```

The body says what was learned and why it matters for future work.
Entries that reference internal systems or security details go in `private/` with `public_safe: false`.
`/spade-plan` reads active learnings whose tags or Scope reference match the work.
`/spade-learn` captures and refreshes them.
A Lead (`/leads`) is different: it is an out-of-scope task to do later, not knowledge.

## Research

`/spade-research` sends one question to the read-only `spade-researcher` agent and shows its report: Question, Findings with citations, Recommendation, Sources, and a list of what it could not confirm and where it looked.
It never invents a citation.
Posting the report to Linear needs the human's explicit consent.

## HTML rendering

`bin/spade-render <file.md>` renders a Scope or Plan to a standalone HTML file next to it using pandoc 3.0+ with raw HTML stripped.
Markdown stays canonical, and skills never read the HTML back.
Exit codes: 0 success, 1 usage or missing input, 2 pandoc missing, 3 render error.

## Trusted lifecycle

`src/CAPABILITIES.md` is the release and installed-capability authority.
Its flat frontmatter declares the canonical remote, commit policy, supported version floor, published versions, skills, agents, researcher, and helpers.
Plugin manifests, install manifests, the repository pin, and documentation claims derive from it or are checked against it.
Global setup records SHA-256 receipts of the installed projection; host-managed plugins embed SHA-256 payload claims.

`bin/spade-lifecycle diagnose` is read-only and emits one redacted finding per check; exit 0 healthy, 1 drift, 2 unsupported.

`migrations/manifest.tsv` holds one explicit transition per published version.
The lifecycle helper maps only allowlisted action names to bounded Bash, stages and verifies each unit before mutation, rolls back on failure, and writes the consumer version pin last.

Clone updates fetch only the canonical remote and need human approval of one exact commit SHA, which is re-resolved immediately before the fast-forward.
Host-managed plugins update only through their host manager.

---

*The SPADE Framework v6.0.1, September 2026, Fusebox HQ*
