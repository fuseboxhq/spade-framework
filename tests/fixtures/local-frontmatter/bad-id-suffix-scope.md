---
name: bad-id-suffix-scope
id: sp-readable-stable-ids-k3f9
title: A Scope whose stable id has a four-character suffix
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-suffix-scope fixture

The suffix is four characters, not five. The schema lint MUST hard-fail this
file. This is the case a looser regex would silently wave through, since the
value still looks like a well-formed id.
