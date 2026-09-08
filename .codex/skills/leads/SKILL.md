---
name: leads
description: Capture out-of-scope discoveries (bugs, tech debt, improvements, security smells, flaky tests, good ideas) as tracked "Leads" without derailing the current task, and manage them (list, show, promote, close). A Lead is a tracker item intended to carry `lead` plus exactly one fixed classification label, but label failures never prevent capture. Use when: you spot something worth doing that is not part of the current job; someone says "raise a lead", "log that as a lead", "any leads?", "show leads", "promote lead N", "close lead N"; or you are about to bury a discovery in a final summary that will never be actioned.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using exec_command.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Project Config

Read the repository's `CLAUDE.md`, `AGENTS.md`, and `.spade/config` when present before choosing the tracker.
A repository instruction or `.spade/config` declaration that makes Linear the tracker of record overrides the GitHub default below.
Do not add a second tracker configuration or duplicate SPADE's mode resolver inside this skill.

# Leads

A **Lead** is something you notice *in passing* while doing other work - a bug, a bit of tech debt, an improvement, a security smell, a flaky or failing test, a missing docstring, or a genuinely good idea - that is **out of scope for the task you are currently on**.

The rule is simple: **don't derail the main task, and don't lose the discovery.**
Capture it as a Lead and keep working.
Leads are triaged and confirmed by a human, or a later session, at any point.

This skill does two things:

1. **Raise** leads automatically while you work, as the standing behaviour.
2. **Manage** leads on demand with `list`, `show`, `promote`, and `close`.

## When to raise a Lead vs. just do it

Judge every discovery against the current task:

- **Trivial AND directly related to what you are already touching** (a typo on the line you are editing, an obvious one-liner in the same function): just fix it inline and mention it in your summary.
  No Lead is needed.
- **Out of scope, OR non-trivial, OR a "great idea" for later**: raise a Lead and carry on.
  This is the default for anything that would otherwise make you stop, context-switch, or expand the task.
- **Never silently drop** something worth doing.
  If it is worth a sentence in your final summary, it is worth a Lead.

Do not interrupt the human to ask before raising a Lead.
Raise it, keep working, and report every Lead you raised in your final summary.

## Raising a Lead

### 1. Select exactly one classification

Choose one intended classification before any tracker mutation.
The allowed classifications are exactly `security`, `documentation`, `testing`, `bug`, `feature`, `enhancement`, and `maintenance`.
Apply the following predicates in order and stop at the first match:

1. `security` - security, privacy, access, secret, or supply-chain risk.
2. `documentation` - work limited to human-readable documentation.
3. `testing` - work limited to tests, fixtures, or test infrastructure.
4. `bug` - incorrect existing behaviour.
5. `feature` - a new externally observable capability.
6. `enhancement` - an improvement to an existing capability that does not fix incorrect behaviour.
7. `maintenance` - internal cleanup, dependency work, refactoring, or other technical debt.

The order resolves overlaps.
For example, a documentation-only security concern is `security`, and a product bug that also needs regression tests is `bug` because the work is not limited to tests.
Use only the selected classification throughout the operation.
Do not substitute repository aliases or add a second classification label.

### 2. Deduplicate against existing open Leads

Treat discovery text as data, never executable shell source.
Build the concise summary and search keywords from normalized plain text with no control characters, pass scalar values as quoted arguments, and never use `eval`.
Write comment and issue bodies to temporary files without evaluating their contents, pass those files with `--body-file`, and remove them after the tracker operation.

Check for an existing open Lead first through exec_command:

```bash
query='Lead: <2-4 normalized keywords> in:title'
gh issue list --state open --search "$query" --json number,title,labels
```

If a clear duplicate exists, add a brief comment with `gh issue comment "$number" --body-file "$comment_file"` instead of creating a new one, and note the existing number in your summary.
Do not require the `lead` label for this search because an earlier label failure may have left a valid Lead without it.

### 3. Inspect and prepare both labels

Read the repository's labels before changing them:

```bash
gh label list --limit 1000 --json name
```

The required labels are `lead` and the one selected classification.
If either is absent, attempt to create it through exec_command.
Use `FBCA04` and `Agent-raised lead: out-of-scope discovery to triage` for `lead`.
Use a concise description such as `Lead classification: <classification>` for the classification label; its colour is presentation, not taxonomy.

```bash
gh label create lead --color FBCA04 --description "Agent-raised lead: out-of-scope discovery to triage"
gh label create <classification> --color 6E7781 --description "Lead classification: <classification>"
```

Do not hide label-creation failures with `|| true` or redirected error output.
If a create response is ambiguous, re-read the label list before retrying.
Retry a label creation only when that authoritative read confirms the label is still absent, and make at most one such retry.
Track which required labels are available and which remain unavailable.

### 4. Create or preserve the Lead

Create the issue through exec_command:

```bash
label_args=()
[ "$lead_label_available" = "yes" ] && label_args+=(--label lead)
[ "$classification_label_available" = "yes" ] && label_args+=(--label "$classification")
gh issue create "${label_args[@]}" --title "$title" --body-file "$body_file"
```

`classification` comes only from the fixed set above, `title` is the normalized `Lead: <concise summary>` scalar, and `body_file` contains the structured body as data.
Pass only the required labels that the authoritative label read says are available.
An unavailable label must not prevent issue creation.

The structured body fields are:

- What
- Where (`file:line` or N/A)
- Why it matters
- Suggested action
- Effort (agentic estimate)
- Confidence (`high`, `medium`, or `low`)
- Type (the one selected classification, exactly as named above)
- Discovered while

Refer to the result as **Lead #<issue-number>**.
The natural GitHub issue number is the canonical ID, with no separate counter.
The `Type` field must agree with the intended classification even when its label is unavailable.

If issue creation returns an error without proving that no issue was created, treat the response as ambiguous.
Search all issue pages for the exact title and confirm candidates with `gh issue view "$number" --json number,title,body,labels,state` before any retry.
For ambiguous recovery, a candidate is the same operation only when its exact title and structured `What`, `Where`, `Type`, and `Discovered while` fields match the attempted body.
Preserve and use that issue in any state; if another actor already closed it, report the closed state instead of creating a duplicate.
When no issue exists, re-read the label list, rebuild the create command from the required labels still available, and make one corrected labelled attempt.
If that attempt fails, search for the exact issue again before doing anything else.
When the issue is still absent, make one final capture-only attempt with the same title and body but no labels.
If the final response is ambiguous, perform the same exact-title and issue-body read before falling back.
Never make another issue-creation attempt after the capture-only attempt.

### 5. Verify and repair labels

Read the created or preserved issue with `gh issue view <n> --json number,title,body,labels,state`.
If that verification read fails or is ambiguous, make at most one read-only retry; if authoritative state is still unavailable, preserve the known issue, make no creation or label mutation, and report `verification unavailable`.
Compare its labels with exactly `lead` and the selected classification.
Confirm that the persisted `Type` field equals the selected classification; if it differs, preserve the Lead, report the exact mismatch, and do not describe recovery as successful.
If an available required label is missing, attempt one repair with `gh issue edit <n> --add-label <label>` and then read the issue again.
If the edit response is ambiguous, the read decides whether another action is needed; never create another issue during label repair.
If another classification from the fixed set is present, attempt to remove each unexpected classification once and then read the issue again.
Do not remove unrelated repository labels.

Successful recovery ends with both required labels and no other classification from the fixed set.
If either label is still absent, keep the Lead and report the exact state, for example `Lead #42 created; classification enhancement recorded in Type; missing labels: enhancement (label creation denied)`.
Name every missing required label and whether creation or application failed.
Name every unexpected fixed classification that could not be removed.
Do not describe a partly labelled Lead as fully labelled.

## Fallback when GitHub Issues are unavailable

If the repo is not on GitHub, issues are disabled, or no tracker issue exists after the bounded creation sequence, append the Lead to a tracked `LEADS.md` at the repo root instead.
Create the file with a heading if absent.
Use one section per Lead with the same fields plus a Status line.
Use the intended classification in `Type` and report `labels unavailable: tracked-file fallback`.

### Per-repo override to Linear

If the repo's own `CLAUDE.md`, `AGENTS.md`, or `.spade/config` indicates Linear is the tracker of record, apply the same sequence through the available Linear integration.
Select one classification, deduplicate by title keywords without relying only on `lead`, inspect workspace or team labels, create missing `lead` and classification labels when permitted, and create the issue with every available required label.
After an ambiguous label or issue mutation, authoritatively re-read Linear labels and matching issues before retrying.
For ambiguous creation recovery, use the same exact title and structured-field identity predicate, but preserve a matching issue in any state because even a closed match proves that the attempted operation created the Lead.
After a failed labelled creation attempt that produced no issue, re-read the labels and make one corrected labelled attempt; if that also produces no issue, make one final creation attempt without labels.
After creation, re-read the issue, repair each available missing required label once, remove each unexpected fixed classification once, and preserve the issue if the exact label state still cannot be reached.
If the final Linear attempt produces no issue, use the tracked-file fallback rather than losing the Lead.
The Linear body uses the same structured fields and its `Type` value remains the intended classification.
Report the Linear identifier plus every missing required label or unexpected fixed classification after bounded recovery.
The repo's instruction always wins over the GitHub default.

## Managing Leads

Run the requested on-demand subcommand through exec_command:

- `list` - `gh issue list --label lead --state open`
- `show N` - `gh issue view N`
- `promote N` - `gh issue edit N --remove-label lead`, then comment `Promoted from Lead to active work.`
- `close N` - `gh issue close N --comment "<reason: done / not worth it / duplicate of #M>"`

A promoted Lead is confirmed real work.
Do not start implementing a promoted Lead without the usual scoping and approval the repo requires, such as a SPADE Scope.

## Reporting

Whenever you raise one or more Leads during a task, end your final summary with a short **Leads raised** list containing the Lead number, its one-line summary, and its type.

## Completion

Leads is complete only when every requested raise or management action has an observable issue, comment, list, view, close, or tracked-file result; every raised or deduplicated Lead is included in the final summary; and control has returned to the original task without implementing promoted work.
