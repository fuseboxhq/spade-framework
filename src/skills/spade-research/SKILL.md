---
name: spade-research
description: Research an external question through an isolated read-only agent. Use for prior art, current libraries or frameworks, benchmarks, postmortems, technical comparisons, or requests to "properly research this", "look into this", or "check the landscape".
---

# SPADE research

Read `.spade/config` if present.
Follow `docs/FRAMEWORK.md` § Research.

## Run the research

Identify one clear research question.
Ask a short clarifying question only when the answer would materially change the search.

Dispatch the work through `{{SPADE_READ_ONLY_RESEARCH}}` to the `spade-researcher` agent.
The researcher cannot see the conversation, so provide a self-contained prompt with:

- the question in the human's words;
- the Scope ID and relevant Scope context, when present;
- relevant local paths when the question compares the repository with outside work;
- any time, jurisdiction, compatibility, or source constraints;
- the report contract below.

Show the returned report inline.
Apply `/unslop` to its prose without changing citations, URLs, dates, technical terms, or the report structure.

## Report contract

The report uses these headings in this order:

1. `## Question`
2. `## Findings`
3. `## Recommendation`
4. `## Sources`
5. `## Could not confirm`

Findings use footnote citations that resolve to entries under Sources.
Sources name the page, URL, and access date.
The report never invents a citation or presents an unfetched source as evidence.
Could not confirm lists unresolved claims and says where the researcher looked.
If nothing is unconfirmed, it says `None.`

## Linear posting

Research is read-only unless the human explicitly approves posting the finished report to an existing Linear issue.
Before any post, ask for that approval through `{{SPADE_ASK_USER}}` and name the target issue.
Do not infer consent from Scope context or post by default.

Post the report the human approved, including any edits they requested.
Do not create issues or change statuses.
If the post fails, report the error and leave the report inline so the human can copy it.
