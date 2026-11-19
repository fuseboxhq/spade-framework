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

## Acceptance criteria
A copy of the Scope's criteria as they stood at approval, so the repository keeps the finish line even when the Scope lives in a tracker.

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
The agent records it itself when guards are live (§ Mechanical guards), every row is met with fresh evidence on the reviewed head, and the Delivery Review has no open blocking finding: every finding has a disposition, none is escalated, every contest cites evidence, and no lens is `not run` (§ Review).
Otherwise the agent recommends a verdict and the human records it.
Whoever records PASS moves the Scope to Done; PARTIAL, FAIL, or any unconfirmed row leaves it in Evaluating.

When a verdict is recorded for a PR, by the agent or by the human through the agent, Evaluate writes `.spade/guard/reviewed-head-<pr>` as `<head sha> <VERDICT>` in the session repository for the PR's working folder (§ Mechanical guards), so the merge guard can check it.

The PR body is the durable record.
After Evaluate, the agent adds the evaluation table, the verdict, and the finding dispositions to the PR body with `gh pr edit`, keeping every existing section, which does not move the head; an on-green merge passes that body as the squash message (a human merging by hand should do the same), so the record lands in git history.
Nothing is committed to the PR branch after review to record it; that would make the review and verdict stale.
In `local` mode the Scope file moves to `status: evaluating` before the Delivery Review.
The move to `done`, with the evaluation appended to the Plan, is a follow-up commit after the merge rather than on the reviewed branch.
After an on-green merge the agent makes it right away; under `merge: human` the next `/spade` resume of that Scope makes it once the PR shows as merged.

Quick-path work evaluates the PR directly: merged, checks green, PR checklist complete.

### Ship and merge policy

The human owns Ship and sets the merge policy in `.spade/config`:

- `autonomy.deliver.merge: human` (the default): the human operates the merge.
  With guards live, agent merge commands are denied.
  Without guards live, the human may still ask the agent to merge once checks are green.
- `autonomy.deliver.merge: on-green`: the agent may merge a PR whose recorded verdict is PASS on the current head, whose checks are green, with the merge pinned to that head (`gh pr merge <pr> --match-head-commit <sha>`).
  The guard enforces every condition.
  With `autonomy.deliver.merge_partial: true` as well, a recorded PARTIAL on the current head also merges, for work whose last criteria can only be checked once it ships, such as a live test.
  A FAIL verdict still blocks the merge, and PARTIAL leaves the Scope in Evaluating until its open rows are confirmed.
  A few changes still need a human merge under `on-green`: any changed path (old or new name) in secrets and credentials, production data, permission widening, or CI; a migration whose added lines drop, rename, truncate, delete, remove, or alter (a loose word match, so an additive line whose names contain those words, such as `deleted_at`, also gets a human merge); and any path matching `guards.human_merge_paths` (comma-separated globs in `.spade/config`). Other security categories, such as auth or crypto code, merge on green once review and Evaluate pass.

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
2. **Blocking review finding.** A reviewer reports a problem it would block the merge for and the fix changes the approach, or a blocking finding is still open after the third Delivery Review round.
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
3. **Arm the guard.** Check whether guards are live for the folder you deliver in (§ Mechanical guards, **Guards live or not**); that decides tripwire 6, who records the verdict, and the merge. Write `deliver` to `.spade/guard/$CLAUDE_CODE_SESSION_ID/mode` in that folder's session repository and remove it on every exit (halt, abort, merge).
4. **Fix the base.** Record the exact base commit SHA the review range will start from.
5. **Build.** Deliver the tasks (§ Deliver), checking tripwire 6 as the diff takes shape.
6. **Open the PR.** Refuse to open one when the project already has `autonomy.deliver.max_open_prs` (default 3) open Deliver PRs; halt instead. The PR body leads with the approach, the rejected forks and why each lost, and the calls the agent made on its own, then **Risk** (what could break and who would notice), **How to revert** (the revert or flag that undoes it), and **Protected paths** (touched categories, or `none`). Apply `/unslop` to the title and body.
7. **CodeRabbit, if present.** Wait for one CodeRabbit pass (at most 10 minutes). Apply only small local fixes that do not add files or touch dependencies, permissions, security-sensitive paths, or agent-behaviour files; leave everything else on the PR. CodeRabbit never replaces the Delivery Review.
8. **Checks and Delivery Review.** Resolve the final head SHA, run the project's checks, and run `/spade-review` in Delivery Review mode on exactly base..head.
9. **Evaluate.** Run `/spade-evaluate` on the reviewed head; it writes the evaluation and finding dispositions into the PR body.
10. **Merge or halt.** Under `on-green` with guards live and a recorded PASS on the current head (or PARTIAL, when `autonomy.deliver.merge_partial` is true), merge pinned to that head with the PR body as the squash message: save the body (`gh pr view <pr> --json body -q .body > <file>`), then `gh pr merge <pr> --squash --match-head-commit <sha> --body-file <file>`, PR number first, with no `--repo` or PR URL. If that merge succeeds, make the local-mode follow-up commit (§ Evaluate); if it fails (for example the repository does not allow squash merges), halt for the human rather than trying another method. Under `human`, or without guards live or a mergeable verdict on the current head, halt for the human. Any commit after review makes the review, the checks, and the verdict stale; rerun them before merging.

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
Every accepted blocking finding still ends with one disposition: fixed (with the commit), contested (citing evidence the reviewer could read), escalated to the human, or pre-existing (in code the diff did not change, confirmed against base and raised as a Lead).
Severity changes only through a contest with evidence.
A reviewer that fails twice is reported as `not run`, which never counts as a clean review.
An escalated finding, an evidence-free contest, or a `not run` lens blocks an agent-recorded PASS.

**Delivery Review** reviews a fixed commit range, base..head, against two questions: does the diff meet every acceptance criterion, and does it meet the repository's own standards (ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md, existing conventions, checks).
Record the base and head SHAs with the report.
A later commit makes the review stale.
An uncommitted working tree gets a provisional review that cannot support PASS.
Delivery Review runs at most three rounds per PR: rounds after the first cover the new commits plus open findings, settled findings are passed in and not reopened, and the round that supports PASS covers the full base..head on the final head.

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
| Protected path | `Edit`, `Write`, `MultiEdit`, `NotebookEdit` | A session repository's `.spade/guard/<session_id>/mode` exists, which arms that repository. An edit lexically outside an armed repository denies. Inside it, the path is classified relative to the armed repository and, when a deeper session repository holds the file, relative to that one too, matching that repository's path both exactly and without regard to case (a case-insensitive filesystem treats `WEB/x` as `web/x`); any match denies. In `quick` mode any path matching the fourteen categories denies. In `deliver` mode only secrets and credentials, production data, and permission widening deny; permission widening covers `.spade/config`, the recorded `.spade/guard/<session_id>/repos`, `.claude/settings*.json`, `hooks/hooks.json`, `bin/spade-guard`, and any path whose purpose grants or widens a permission. |
| Merge policy | `Bash` running `gh pr merge`, `glab mr merge`, or a `gh api` merge | The merge's working directory is unknown and the recorded list is more than the session folder alone, or, when the session folder has no `.spade/config`, outside every session repository. Otherwise the target repository's `autonomy.deliver.merge` is `human` or absent. Under `on-green`, denies unless the PR is not a draft, is mergeable, has at least one check and every check is SUCCESS or SKIPPED, the target repository's `.spade/guard/reviewed-head-<pr>` reads `<head sha> PASS` for the current head (or `PARTIAL`, when `autonomy.deliver.merge_partial` is true), and the command pins that head exactly once with `--match-head-commit` and a literal SHA and neither uses `--admin`, `--repo`, or a PR URL nor sets `GH_REPO`, `GH_HOST`, `GIT_DIR`, or `GIT_WORK_TREE`, and the merge floor (§ Ship and merge policy) passes over every changed file listed by `gh api .../pulls/<n>/files`, with the listed count equal to `changedFiles`. Every `gh` call runs in the target repository. `glab` is not verified and denies under `on-green`. |
| Stage all | `Bash` running `git add -A`, `--all`, or `.` | `guards.deny_stage_all: true` in the target repository's config, or, when the working directory is unknown, in any session repository's. Off by default. |

Every deny that depends on a config ends by naming it: `(read <path>/.spade/config)`.

**Session repositories.** The first `SessionStart` of a session records which repositories count, in `.spade/guard/<session_id>/repos`:

- the session folder (`CLAUDE_PROJECT_DIR`), when it holds `.spade/config`;
- every child or grandchild folder that holds both `.git` (a directory, or a worktree's file) and `.spade/config`. Hidden folders such as `~/.spade` and folders without `.git`, such as test fixtures, are skipped.

With a config at the session folder, the list and `live` go in its `.spade/guard/<session_id>/`.
Without one, a copy of each goes in every recorded child, and nothing is written in the session folder.
A folder with neither stays inert.
Later `SessionStart` events (compact, resume, clear) leave an existing list alone, so a repository created or cloned mid-session, or a config an agent writes, never joins it; it counts from the next session.
The exception is a session whose first `SessionStart` found nothing to record: no list exists, so a later one records what it finds then, including a repository created since. The guard enforces that repository's own config, where before this session would have had no guards at all.
Copies of the list that disagree deny merges and armed edits.

**Which repository a call targets.** The session repository for a path is the deepest recorded repository that contains it. For an edit, paths are compared lexically, without following symlinks.
An edit targets its file.
A Bash command targets its working directory, which the guard reads from an allow-list.
It is the hook input's `cwd`, moved only by a run of commands at the very start of the input, each exactly `cd [-L|--] <literal path>` and joined to the next by `&&`; for stage-all, `git -C <literal path>` also moves it.
A literal path has no `$`, glob or brace character, redirection, comment, substitution, backtick, backslash, quoted or escaped `~`, or `~user`, and no `$'…'` or `$"…"` quoting.
An unquoted `~` or `~/…` expands to `$HOME` unless the command names `HOME` earlier, and a relative path resolves against the directory so far unless the guard's own `CDPATH` is set.
A newline ends a command the way `;` does.
Anything else before the checked command makes the directory unknown, whatever it is: any other command, a comment, a heredoc, a subshell, a brace group, a substitution, or a joiner other than `&&`.
The words in front of the checked command are an allow-list too. Only literal `NAME=value` assignments, `command`, `time`, `env` and `nice` (alone or with a numeric `-n`) may come before it. Any other word makes the directory unknown, which covers `sudo`, `xargs`, `find -execdir`, `pnpm -C` and `env -C`. For stage-all, `git -C <literal path>` sets the directory, and `--git-dir`, `--work-tree`, `GIT_DIR` or `GIT_WORK_TREE` make it unknown.
A `cd` resolves `..` lexically, as the shell's logical `cd` does, and `git -C` follows symbolic links physically, as git does. The directory is unknown when it doesn't exist, or when its physical repository differs from the lexical one.
In a single-repository session, where the recorded list is just the session folder, an unknown directory is the session folder, as before; otherwise it denies a merge, and denies a stage-all when any session repository sets `deny_stage_all`.
When the target is outside every session repository, the session folder's config applies if it has one.
Without one, such a merge denies, and such a stage-all is not checked.

**Markers.** `SessionStart` writes `live` and `repos` as above; `SessionEnd` removes the session directory everywhere it was written.
`live` is a session-start timestamp kept for older skills; it is not the liveness signal, which is the recorded list (**Guards live or not**).
`/spade` Deliver and `/spade-quick` write `mode` in `.spade/guard/<session_id>/` of the session repository for the folder they deliver in, at start, and remove it at close, using `CLAUDE_CODE_SESSION_ID`.
With no session repository for the folder, there is nothing to arm.
A `mode` file anywhere else is ignored.
`/spade-evaluate` writes `reviewed-head-<pr>` in `.spade/guard/` of the session repository for the PR's working folder, which is where the merge guard reads it.
`.spade/guard/` is gitignored.
A missing marker means guards are inert, never that something is allowed.

**Guards live or not.** Guards are live for a folder when the nearest folder at or above it that holds `.git` or `.spade/config` is named in the session's recorded list, the nearest `.spade/guard/<session_id>/repos` at or above it:

```sh
d=$PWD; while [ ! -e "$d/.git" ] && [ ! -f "$d/.spade/config" ] && [ "$d" != / ]; do d=$(dirname "$d"); done
l=$d; while [ ! -f "$l/.spade/guard/$CLAUDE_CODE_SESSION_ID/repos" ] && [ "$l" != / ]; do l=$(dirname "$l"); done
grep -qxF "$d" "$l/.spade/guard/$CLAUDE_CODE_SESSION_ID/repos" 2>/dev/null
```

A worktree or clone added mid-session has its own `.git` and is not listed, so guards are not live there until the next session, even inside a listed repository such as `.claude/worktrees/<name>`; the guard still judges its edits as part of the repository around it.
Only when guards are live do the lighter rules apply: the narrowed tripwire 6, the agent-recorded Evaluate verdict, and merge under `on-green`.
Otherwise (Codex, a Claude session without the hooks, a repository without `.spade/config`, or one added mid-session), any security category halts before code and the human merges.

**A deny is a halt.** Tell the human the reason and wait.
Do not remove a marker, edit the guard or the config, or reach the same file another way.
A human may disarm a guard for one run; note it in the Plan's Halts section.

**Limits.** Guards are not a sandbox; they catch the ordinary tool path.
Paths are split into words at non-alphanumeric and camelCase boundaries and matched as whole words, so `access-token.ts` matches `token` and `tokenizer.ts` does not.
`key` counts as a credential only beside a credential word such as `api`, `private`, or `ssh`.
Well-known credential files (`id_rsa`, `authorized_keys`, `.npmrc`, `.netrc`, `kubeconfig`) are named directly.
A check that needs a literal value, such as the merge head pin, fails rather than trusting a command substitution.
The working directory starts from the `cwd` Claude Code reports; `cd <literal path> &&` in front of a merge works whatever that is.
The guard reads that `cwd` byte for byte, and a `cwd` whose name holds a tab or line break, including at its end, is unknown. Every folder a `cd` moves to, and the folder in front of each `..` in its path, must be enterable as written, because bash falls back to the physical path when one is not; otherwise the directory is unknown.

**The framework's own layout.** `src/`, `skills/`, `agents/`, `plugins/`, `fragments/`, `hooks/`, `bin/`, `setup`, and the generated host trees are governance surfaces only inside this repository (detected by `src/CAPABILITIES.md` and `src/skills/` both existing).
In a consumer repository `src/` is application code.

**Where they ship.** The Claude plugin carries `hooks/hooks.json` and `scripts/spade-guard`, and this repository registers the same hooks in `.claude/settings.json`.
A clone install ships `~/.spade/bin/spade-guard` without registering hooks; to opt in, run `~/.spade/setup --host claude --hooks`, which merges the entries from `src/hooks/hooks.json` into `~/.claude/settings.json` with the absolute guard path and keeps every other setting; `setup.ps1` has no equivalent yet, so on Windows copy the entries by hand and replace each `${CLAUDE_PLUGIN_ROOT}` command with the installed guard path.
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

*The SPADE Framework v6.1.0, November 2026, Fusebox HQ*
