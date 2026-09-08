---
issue: add-healthz-endpoint
title: Add a /healthz endpoint to the API
date: 2026-05-18
status: approved
---

# Plan — Add a /healthz endpoint to the API

**Technical Approach Summary:** Register one unauthenticated route that
returns a static JSON body. No persistence, no downstream calls.

**Risks and Assumptions:** None — the route is independent of
application state.

## Tasks

### Task 1: Add the /healthz route

- **What:** Register `GET /healthz` returning `200 {"status":"ok"}`,
  outside the auth middleware, alongside the existing public routes.
- **Done when:** An unauthenticated request to `/healthz` returns 200
  with the static JSON body.
- **How:** test-first (FRAMEWORK.md § Delivery approaches) - the
  contract (status code, body, no auth) is fully specified.
- **Verify:** A request test asserting status, body, and that no auth
  header is required.
- **Needs:** none · **Blocks:** none
- **Who:** AI · brief

### Delivery Sequence

1. Task 1 (no dependencies).

### Delivery Bundles

#### Bundle 1: healthz
- **Branch:** `spade/add-healthz-endpoint`
- **PR title:** Add a /healthz endpoint
- **Tasks:** Task 1
- **Rationale:** Single task, single bundle.
