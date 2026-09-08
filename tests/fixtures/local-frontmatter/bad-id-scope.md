---
name: bad-id-scope
id: banana
title: A Scope whose stable id is not an id at all
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-scope fixture

The `id` matches neither the current grammar nor the legacy form. The schema
lint MUST hard-fail this file. Before v3.5.0 it passed, because only the
*presence* of `id` was checked and never its shape.
