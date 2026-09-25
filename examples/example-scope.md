# Example Scope: Device Telemetry Ingestion

A worked example of a SPADE Scope in the format `/spade-scope` writes.

---

## Scope: Build Databricks telemetry ingestion worker

**Intent:** The threat intelligence team can see device behaviour across the fleet in near real time, because telemetry flows from Databricks into the shared Argus data model in Elasticsearch without anyone moving it by hand.

### Acceptance criteria
1. A Temporal worker runs on a configurable schedule, every 5 minutes by default, visible in the Temporal Cloud schedule list.
2. A record that lands in the Databricks telemetry table appears in the `argus-telemetry` index within 5 minutes, checked by the integration test's end-to-end timing assertion.
3. Indexed documents validate against the Argus data model v2 JSON schema; the integration test fails on any invalid document.
4. Malformed records go to the `argus-telemetry-dlq` index with the rejection reason, covered by unit tests for each rejection rule.
5. A failed worker run posts to #argus-alerts within one minute, shown by forcing a failure in staging.

### Constraints
Temporal Cloud and the existing Elasticsearch cluster only, no new infrastructure.
Normalisation follows Argus data model v2.
Databricks credentials come from the existing secrets manager, never from code.
The worker deploys to the existing EKS cluster.

### Dependencies
The Slack webhook for #argus-alerts must be provisioned by the platform team.

### Out of scope
Backfilling historical telemetry, and any change to the Argus relevancy engine that reads the index.

### References
`consumer-template/` shows the existing worker pattern; the Argus data model v2 schema lives in `schemas/argus-v2.json`.
