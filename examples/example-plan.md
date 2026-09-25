# Plan: Build Databricks telemetry ingestion worker

Scope: `examples/example-scope.md`
Approved by Priya Shah, 2026-04-08.

## Approach
Start from `consumer-template/` and replace its Kafka consumer with a Temporal workflow of two activities: query Databricks through the SQL connector, then normalise and bulk-index into Elasticsearch.
Validation runs inside normalisation, and rejected records go to a dead-letter index so nothing is dropped silently.
Rejected forks: a Databricks-to-Elasticsearch connector job lost because it cannot apply the Argus v2 normalisation or route rejects; a streaming consumer lost because Databricks only exposes the table in 5 minute batches.

## Risks
- Databricks SQL latency at real volumes is unmeasured; if a query takes more than about 2 minutes the schedule needs to widen or the query needs partitioning.
- Argus v2 may still change; the schema file is pinned so a change shows up as a failing test.
- The Slack webhook is a platform-team dependency, so alerting is a human task.

## Tasks
- [ ] 1. Worker skeleton runs on schedule - done when the scheduled workflow runs the Databricks query activity against a mocked connector; verify with `make test-integration`.
- [ ] 2. Normalisation and validation - done when every rejection rule and the Argus v2 mapping are covered and invalid records land in the dead-letter index; verify with `make test` and the schema assertion.
- [ ] 3. Indexing end to end - done when a seeded Databricks row appears in `argus-telemetry` within 5 minutes; verify with the staging end-to-end test.
- [ ] 4. Alerting (human) - done when the webhook exists and a forced failure posts to #argus-alerts; verify with a forced failure in staging.

## Halts
None.
