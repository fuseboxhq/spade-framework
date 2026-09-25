---
last_reviewed: 2026-09-25
---

# Project Intent

## Problem

Teams adopting AI agents for engineering work fall into one of two failure
modes. Either AI is used as fancy autocomplete — humans still do all the
planning, structuring, and project management, so there is no leverage. Or AI
is handed open-ended goals with no review gates — and produces work that is
confidently wrong: architecturally off, insecure, or solving the wrong
problem. There is no shared, auditable operating model for *where humans
decide and where AI executes*. A second pain compounds it: AI-delivered work
becomes opaque — with no recorded plan, nobody can later explain what
frameworks, patterns, or decisions went into the output, and debugging it in
production is guesswork.

## Users

Engineering teams using Claude Code (or any agent that reads structured
context) who want a fast but auditable loop for AI-assisted delivery. Two
roles are served: **engineers**, who get a structured handoff between human
judgement and AI execution; and **engineering leadership**, who get a
traceable audit trail for every piece of AI-delivered work. SPADE is *not* for
end users of any product — it is a developer-workflow framework, not a runtime
anyone ships to customers.

## What it does

SPADE is a convention-plus-skills framework.
It defines the loop Scope, Plan, Approve, Deliver, Evaluate, Ship: humans own the intent and the decision to ship, and agents plan, build, review, and verify in between against the human's acceptance criteria.
It ships as a small set of skills for Claude Code and Codex, a short AGENTS.md section every agent loads, one framework reference, Claude-host guard hooks for the rules that need no judgement, and Linear integration.
Every delivered change traces from Scope through Plan, approval, PR, and Evaluate record.

## Success

SPADE is working when every delivered piece of work can be traced back through
scope → plan → approval → delivery → evaluation, and a developer can explain
*why* the output looks the way it does. When the Approve gate genuinely
catches bad plans rather than rubber-stamping them. When neither failure mode
(all-manual, or unsupervised-slop) shows up in practice. And when each pass of
the loop makes the next one stronger — captured learnings actually reach the
next Plan.

## Non-goals

- SPADE is **not** a runtime, service, or package — there is no server, no
  database, no daemon, no compiled artefact. It will never become one.
- SPADE does **not** plan strategy. Deciding *what* to build and *why it
  matters to the business* is human-owned; SPADE consumes the output of
  strategic thinking as Scopes and Milestones, it does not generate it.
- AI never decides what to build, and AI output is never shipped without human
  verification — this is a permanent boundary, not a maturity stage.
- SPADE does **not** bind to a single agent platform, and does **not** add a
  second external tracker integration speculatively (Linear is the only one).
- SPADE does **not** centralise state outside the consumer's repo.

## Maturity

In production and dogfooding itself: SPADE governs its own development through the loop it provides.
The framework is at v6.0.0, which cut the always-loaded rules and skill procedure down to what current models need, kept the guards, merge policy, and independent review, and moved progress tracking into the Plan file.
