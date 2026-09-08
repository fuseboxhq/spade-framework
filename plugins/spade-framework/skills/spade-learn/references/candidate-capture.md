# Learning Candidate Capture

Read this reference when Deliver or Evaluate invokes `/spade-learn` with observed evidence rather than a human-authored learning request.
Manual capture and periodic refresh keep their existing behavior.

## Candidate gate

A candidate is eligible only when the evidence demonstrates one of five fixed categories:

1. `failed-assumption` - a named Plan or delivery assumption was disproved;
2. `recurring-pitfall` - the same specific failure or rework pattern occurred in at least two named tasks or Scopes;
3. `project-constraint` - work discovered an undocumented repository, architecture, toolchain, environment, or organizational constraint that changes future planning;
4. `useful-pattern` - a concrete approach succeeded at a named high practical seam and is reusable beyond the current task; or
5. `learning-correction` - current evidence contradicts or materially narrows an active learning.

Every eligible draft must contain:

- one proposed one-line learning title;
- one specific observed fact;
- the named task, Scope, review finding, check, command, or authoritative source that proves it;
- one concrete implication for how a future Scope or Plan should change;
- the originating Scope reference;
- one area and proposed tags; and
- the candidate category.

Reject generic completion summaries, restated acceptance criteria, ordinary successful checks, style preferences without demonstrated impact, speculative advice, and observations that apply only to the current diff.
"Tests found a bug", "be more careful", and "the task went well" are not candidates.
The normal successful outcome is `candidate:none` with no human prompt.

Use only bounded delivery and evaluation evidence: approved Plan assumptions, task or bundle verification, retained review findings, acceptance-evidence rows, failed or corrected checks, and explicit human corrections.
Never mine an unrestricted transcript, infer personality or preference, or include credentials, tokens, cookies, customer data, private discussion, or unrelated conversation.

## Draft shape

Draft one candidate at a time:

```markdown
Category: <one fixed category>
Title: <proposed one-line learning title>
Observation: <specific fact>
Evidence: <named retained source and concise result>
Future implication: <what a future Scope or Plan should do differently>
Scope: <scope identifier>
Area: <existing learning area>
Tags: <comma-separated proposed tags>
```

Do not persist this draft before the human chooses its route.
A resumable run may record only `learning-decision-pending` without the draft, evidence body, or tags.

## Deduplication

Before showing the draft, read active public and private learnings in the current project.
Private content remains local and must never be copied into tracker comments or a public draft.

Treat an active entry as a possible match when either condition holds:

- its normalized title equals the candidate's proposed one-line title; or
- its case-insensitive tag-set Jaccard similarity with the candidate is at least 0.5.

Read each possible match and classify it as:

- `duplicate` when it asserts the same fact and future action;
- `update` when the candidate adds current evidence or narrows the same fact without contradicting it;
- `correction` when current evidence contradicts or supersedes it; or
- `distinct` when tag overlap is coincidental.

Show at most the strongest matching active entry, naming its title, path, public or private store, match reason, and recommended action.
For a private match, show no body excerpt or sensitive detail.
Do not create a second file for a duplicate.

## Human route before any learning write

Present the deduplicated draft through `request_user_input when available, otherwise a concise direct question` with exactly:

- `Public-safe`;
- `Private`;
- `Skip`.

Do not preselect a route.
When a private match exists, recommend Private but still require the human's choice.
Skip writes no learning.

If there is no active match, the existing capture flow writes the approved draft to the chosen store.
If there is a duplicate, record Skip or the approved no-write duplicate outcome and leave the file unchanged.
If there is an update or correction, continue through the candidate refresh branch below.

## Candidate refresh branch

Candidate-driven update and supersession reuse `/spade-learn --refresh`'s explicit human gate and archived-entry rules.
They do not wait for the ordinary 180-day housekeeping threshold.

After the public or private route is chosen, present exactly:

- `Update active` - revise the matching entry in its existing store with the new evidence while preserving its original `created` value and Scope provenance in the body;
- `Archive and replace` - set the matching entry to `status: archived`, then write the approved replacement to the selected store; or
- `Skip` - change nothing.

Use Update only when the learning's core fact still holds.
Use Archive and replace for a correction, contradiction, store change, or materially different future action.
Never silently move private content into the public store.

Preview the exact file changes and require human confirmation before either write.
If the archive succeeds but replacement fails, report the partial state and stop; never hide or delete the archived entry.

## Continuity outcomes

After the human decision, record only one content-free outcome in run state:

- `candidate:none`;
- `candidate:skipped`;
- `candidate:duplicate-no-write`;
- `candidate:captured-public`;
- `candidate:captured-private`;
- `candidate:updated-active`; or
- `candidate:archived-and-replaced`.

Never record the draft, learning body, evidence body, tags, private path, or sensitive match detail in tracker continuity state.
