---
name: bad-id-empty-scope
id:
title: A Scope whose stable id field is present but blank
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-empty-scope fixture

The `id` key is present with no value. That is **malformed**, not
grandfathered: a pre-v1.8 Scope has no `id` key at all, whereas this one
asserts an identifier and then supplies nothing. The schema lint MUST
hard-fail this file, otherwise a blank identifier inherits the missing-field
warning and slips through as a legacy file.
