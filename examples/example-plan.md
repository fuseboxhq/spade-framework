# Example Plan: Device Telemetry Ingestion

This is a worked example of a well-formed SPADE Plan, generated from the
example Scope. Every task is one strict card - What / Done when / How /
Verify / Needs / Blocks / Who - in fixed order, every field present,
each field one to two sentences.

---

## Plan for: Build Databricks telemetry ingestion worker

**Technical Approach Summary:**
Build a Temporal workflow with two activities: one to query Databricks via the
SQL connector and one to normalise and index into Elasticsearch. Use the
existing consumer-template as a starting point. Data quality checks run inline
during normalisation, with failed records routed to a dead-letter index.

**Risks and Assumptions:**

- Assumes Databricks SQL connector latency is acceptable for 5-minute cycles
  (need to validate with real query volumes)
- Assumes the Argus data model v2 schema is finalised (check with team)
- Slack webhook URL for #argus-alerts needs to be provisioned (human task)
- If telemetry volume exceeds expectations, the single-worker model may need
  scaling. Plan for this in Task 3 by using Temporal's built-in worker scaling.

### Tasks

#### Task 1: Temporal worker scaffold and Databricks connection
- **What:** Set up the Temporal workflow definition, activity stubs, the
  Databricks SQL connector, and the 5-minute schedule trigger, starting
  from consumer-template.
- **Done when:** The scheduled worker starts and runs a Databricks query
  activity through the mocked connector.
- **How:** test-first (FRAMEWORK.md § Delivery approaches) - copy
  consumer-template, replace its Kafka consumer with a Databricks SQL
  query activity using the existing Temporal Cloud connection config.
- **Verify:** Temporal workflow integration test with the Databricks
  activity mocked at its connector boundary.
- **Needs:** none · **Blocks:** Tasks 2 and 4
- **Who:** AI · moderate

#### Task 2: Normalisation logic for Argus data model
- **What:** Transform Databricks telemetry records into Argus data model
  v2, rejecting malformed records to a dead-letter index with the
  original payload and error reason.
- **Done when:** A queried telemetry record becomes a valid Argus v2
  record or a traceable dead-letter record.
- **How:** test-first (FRAMEWORK.md § Delivery approaches) - every field
  mapping is a contract, so write the assertions before the transforms;
  TypeScript types with Zod validation (see PATTERNS.md).
- **Verify:** Databricks-activity-to-normalisation integration test with
  valid and malformed source records, plus unit tests per field mapping.
- **Needs:** Task 1 · **Blocks:** Task 3
- **Who:** AI · moderate

#### Task 3: Elasticsearch indexing layer
- **What:** Bulk-index normalised records into monthly
  `argus-telemetry-YYYY-MM` indices using the shared ES client, creating
  the index when absent.
- **Done when:** Normalised telemetry is queryable in the expected
  monthly Elasticsearch index.
- **How:** straight-through (FRAMEWORK.md § Delivery approaches) -
  wrapping a well-known ES client with bulk indexing, covered by the
  integration test rather than new unit tests.
- **Verify:** Pipeline integration test against local Elasticsearch
  (docker-compose) from normalised record to indexed document.
- **Needs:** Task 2 · **Blocks:** Task 5
- **Who:** AI · brief

#### Task 4: Slack failure alerting
- **What:** Wrap workflow execution in an error handler that POSTs the
  worker name, error message, and timestamp to the existing Slack
  webhook pattern.
- **Done when:** A failed workflow produces one useful operator alert
  with the worker, error, and time.
- **How:** test-first (FRAMEWORK.md § Delivery approaches) - small
  surface, fully contract-driven (message shape, error handler path).
- **Verify:** Workflow-failure integration test against a mock webhook
  endpoint, plus a unit test for message formatting.
- **Needs:** Task 1 · **Blocks:** Task 5
- **Who:** AI · brief

#### Task 5: Provision Slack webhook and validate end-to-end
- **What:** Create the #argus-alerts webhook, run the full pipeline
  against real Databricks data, and validate indexing plus alerting.
- **Done when:** Real Databricks telemetry reaches Elasticsearch and a
  simulated failure reaches the operator Slack channel.
- **How:** straight-through (FRAMEWORK.md § Delivery approaches) -
  operational work in the Slack admin panel and a production-like run;
  no code change.
- **Verify:** Manual verification against the Scope's acceptance
  criteria across Databricks, Temporal, Elasticsearch, and Slack.
- **Needs:** Tasks 1-4 and human Slack + Databricks access · **Blocks:** Scope evaluation
- **Who:** human · brief

### Delivery Sequence

1. Task 1 (no dependencies, start immediately)
2. Task 4 (depends on Task 1, can run in parallel with Task 2)
3. Task 2 (depends on Task 1)
4. Task 3 (depends on Task 2)
5. Task 5 (depends on all above, human-delivered)

### Delivery Bundles

#### Bundle 1: telemetry-ingestion
- **Branch:** `spade/M-000-telemetry-ingestion`
- **PR title:** Ingest device telemetry from Databricks into Elasticsearch
- **Tasks:** Task 1, Task 2, Task 3, Task 4
- **Rationale:** Single bundle - the tasks share the worker module and
  land together; Task 5 is human validation after merge, not a PR.
