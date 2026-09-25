---
name: spade-review
description: Get an independent second opinion on a SPADE Scope, Plan, or delivered diff. Use when someone says "second opinion", "review this", "challenge this", or "review the delivery", and when invoked by /spade, /spade-plan, or /spade-evaluate.
---

# SPADE review

Read `.spade/config` if present.
Follow `references/FRAMEWORK.md` § Review as the single definition of review policy.

## Modes

### Scope and Plan review

Review a Scope, a Plan, or both together.
When `/spade` invokes this skill at the Plan or Deliver level, review the Scope and Plan together.
Check whether the intent, acceptance criteria, approach, risks, and tasks agree and give delivery a sound finish line.

### Delivery Review

Resolve and record exact base and head commit SHAs before dispatch.
Give every reviewer the same fixed `base..head` range.
Ask the two questions from `references/FRAMEWORK.md` § Review:

1. Does the diff meet every acceptance criterion?
2. Does the diff meet the repository's own standards, including its architecture, patterns, anti-patterns, conventions, and checks?

An uncommitted working tree can receive only a provisional review and cannot support PASS.
A commit after the review makes the report stale.

## Choose reviewers

Use one general reviewer by default.
Add a lens reviewer only when the change carries the matching risk in the table in `references/FRAMEWORK.md` § Review.
Do not copy the table here or add reviewers for generic coverage.
Run added lens reviewers in parallel when the host supports it.

Dispatch each review through `Task` to the `spade-reviewer` agent.
When the host ships the reviewer as `references/personas/spade-reviewer.md` instead of a registered agent, put that file's instructions at the top of the prompt.
When ANTI-PATTERNS.md has many rules, split them across reviewers so each rule gets a clean look.
Reviewers work independently and do not receive another reviewer's findings.

## Build the prompt

The reviewer cannot see the conversation, so every prompt must stand alone.
Include:

- the review mode and lens;
- the complete Scope and Plan material needed for the review;
- relevant project context and repository paths;
- the exact base and head SHAs for Delivery Review;
- the two Delivery Review questions when that mode applies;
- relevant constraints from `ARCHITECTURE.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`, or instructions to read those files;
- the required output contract below.

Do not summarise away acceptance criteria, constraints, or changed behaviour that the reviewer needs to verify.

## Output contract

Each reviewer returns only problems it would block the merge or Plan for.
Every blocking finding must include:

- a file and line, diff location, or Scope or Plan section;
- why it is wrong;
- how to show it fails.

Suspicions that the reviewer could not prove belong in a separate `Unconfirmed` list.
Every unconfirmed item says where the reviewer looked.
Style preferences and nits stay out.
When there are no blocking problems, the reviewer says `No blocking problems.` plainly.

## Verify and report

Check each finding against the cited material and reproduce its evidence where practical before accepting it.
Move anything that cannot be confirmed to the unconfirmed list, with where you looked.
Drop duplicates and keep the clearest location and failure evidence.

Save the complete report under `.spade/reviews/` with a clear name.
For Delivery Review, include the base and head SHAs in the saved report.

Present the accepted blocking findings first, followed by unconfirmed items.
Say plainly when no blocking problems survive verification.
Apply `/unslop` to report prose without changing locations, commands, evidence, or SHAs.
