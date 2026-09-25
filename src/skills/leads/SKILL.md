---
name: leads
description: Capture out-of-scope work without derailing the current task, or list, show, promote, and close existing Leads.
---

# Leads

A Lead is out-of-scope work worth keeping.
Raise it without interrupting the human, then return to the task.

Fix a discovery inline only when it is trivial and directly related to code already being changed.
Raise a Lead when it is out of scope, non-trivial, or an idea for later.
If it is worth mentioning, capture it.

Read `CLAUDE.md`, `AGENTS.md`, and `.spade/config` when present to choose Linear or GitHub Issues, with `LEADS.md` as the fallback.

## Classify before touching the tracker

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

Do not substitute repository aliases or add a second classification label.

## Keep discovery text out of shell source

Treat discovery text as data, never executable shell source.
Normalize titles and keywords without control characters, quote scalar arguments, and never use `eval`.
Pass bodies with temporary `--body-file` files and remove them afterward.

## Deduplicate

Search open issues by two to four title keywords without requiring `lead`:

```bash
query='Lead: <2-4 normalized keywords> in:title'
gh issue list --state open --search "$query" --json number,title,labels
```

Comment on a clear duplicate with `gh issue comment "$number" --body-file "$comment_file"`, report its number, and create nothing.

## Prepare labels

Read all repository labels with `gh label list --limit 1000 --json name`.
Create missing required labels through {{SPADE_SHELL}}:

```bash
gh label create lead --color FBCA04 --description "Agent-raised lead: out-of-scope discovery to triage"
gh label create <classification> --color 6E7781 --description "Lead classification: <classification>"
```

Do not hide errors with redirected output or `|| true`.
If a create response is ambiguous, re-read the label list before retrying.
Retry at most once only after confirming absence, and track unavailable labels.

## Create the Lead

Build arguments only from labels confirmed available:

```bash
label_args=()
[ "$lead_label_available" = "yes" ] && label_args+=(--label lead)
[ "$classification_label_available" = "yes" ] && label_args+=(--label "$classification")
gh issue create "${label_args[@]}" --title "$title" --body-file "$body_file"
```

An unavailable label must not prevent issue creation.

Use title `Lead: <concise summary>` and these body fields:

- What
- Where (`file:line` or `N/A`)
- Why it matters
- Suggested action
- Effort (agentic estimate)
- Confidence (`high`, `medium`, or `low`)
- Type
- Discovered while

The `Type` field must agree with the intended classification even when its label is unavailable.
Call it `Lead #<issue-number>`.

## Recover an ambiguous create

Treat an error as ambiguous unless it proves no issue was created.
Search all pages for the exact title, then read candidates with `gh issue view "$number" --json number,title,body,labels,state`.
A candidate matches only when its exact title and the structured `What`, `Where`, `Type`, and `Discovered while` fields match.
Preserve a match in any state and report if another actor closed it.

When no issue exists, re-read the label list, rebuild the create command from the required labels still available, and make one corrected labelled attempt.
Search again for the exact issue after that attempt.
When the issue is still absent, make one final capture-only attempt with the same title and body but no labels.
After an ambiguous final response, repeat that read and never create again.

## Verify and repair GitHub labels

Read the created or preserved issue with `gh issue view <n> --json number,title,body,labels,state`.
If that verification read fails or is ambiguous, make at most one read-only retry; if authoritative state is still unavailable, preserve the known issue, make no creation or label mutation, and report `verification unavailable`.

Confirm that the persisted `Type` field equals the selected classification; if it differs, preserve the Lead, report the exact mismatch, and do not describe recovery as successful.
Require exactly `lead` and the selected classification.
If an available required label is missing, attempt one repair with `gh issue edit <n> --add-label <label>` and then read the issue again.
If the edit response is ambiguous, let the read decide the state and never create another issue.
If another classification from the fixed set is present, attempt to remove each unexpected classification once and then read the issue again.
Do not remove unrelated repository labels.

Keep a partly labelled Lead.
Name every missing required label and whether creation or application failed.
Name unexpected fixed classifications that remain.
Claim exact recovery only with both required labels and no other fixed classification.

## Linear tracker

Use the same bounded sequence when Linear is the repository tracker.
Select one classification, deduplicate by title without relying only on `lead`, read team labels, create missing required labels when permitted, and create with every available required label.

For ambiguous creation recovery, use the same exact title and structured-field identity predicate, but preserve a matching issue in any state because even a closed match proves that the attempted operation created the Lead.
After a failed labelled creation attempt that produced no issue, re-read the labels and make one corrected labelled attempt; if that also produces no issue, make one final creation attempt without labels.
After creation, re-read the issue, repair each available missing required label once, remove each unexpected fixed classification once, and preserve the issue if the exact label state still cannot be reached.
If the final Linear attempt produces no issue, use the tracked-file fallback rather than losing the Lead.

Use the same body fields and `Type`, then report the identifier and remaining label problems.

## Tracked-file fallback

If no tracker issue exists after the bounded sequence, append to tracked root `LEADS.md`.
Create the heading when absent and use one section per Lead with the same fields plus `Status`.
Use the intended classification in `Type` and report `labels unavailable: tracked-file fallback`.

## Manage Leads

Run the requested command through {{SPADE_SHELL}}:

- `list`: `gh issue list --label lead --state open`
- `show N`: `gh issue view N`
- `promote N`: remove `lead`, then comment `Promoted from Lead to active work.`
- `close N`: close it with a reason such as done, not worth it, or duplicate

Promotion confirms the work but does not authorize implementation under the repository's Scope and approval rules.

## Finish

Require an observable issue, comment, list, view, close, or tracked-file result.
Return to the original task without implementing promoted work.
Put every raised or deduplicated Lead in **Found** with its identifier, summary, type, and any label problem.

End with:

- **Blocked on me**: a tracker decision the human owes, or `nothing`.
- **Changed**: the Lead operations completed, or `nothing`.
- **Found**: the **Leads raised** list and any verification or label problem, or `nothing`.
