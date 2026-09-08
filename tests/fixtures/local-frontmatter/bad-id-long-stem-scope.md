---
name: bad-id-long-stem-scope
id: sp-aaaaaaaaaa-bbbbbbbbbb-cccccccccc-dddddddddd-eeee-fghij
title: A Scope whose stable id has an over-length stem
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-long-stem-scope fixture

The stem is 48 characters, over the 40-character bound. The schema lint MUST
hard-fail this file, so the truncation rule cannot rot into a suggestion.
