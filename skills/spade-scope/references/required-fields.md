# Required Scope Fields

Read this reference completely when creating, editing, or validating Scope content.
## Required Fields

Every Scope MUST include all of the following. If any field is missing, the
Scope is not ready for planning. Flag missing fields clearly.

### 1. Statement of Intent
What needs to be achieved and why it matters. This is not a task description.
It is a statement of outcome. One to three sentences maximum.

Good: "Device telemetry is flowing into the intelligence platform and
available for threat analysis, giving the TI team real-time visibility
into fleet behaviour patterns."

Bad: "Build the telemetry pipeline."

The first describes an outcome. The second describes an activity.

### 2. Acceptance Criteria
Specific, verifiable conditions that define "done". Write these as testable
statements. A person (or AI) reading them should be able to unambiguously
determine whether each criterion has been met.

Good: "Telemetry data appears in the Elasticsearch index within 5 minutes
of device transmission."

Bad: "Telemetry works."

Each criterion should be a checkbox item. Aim for 3-7 criteria. Fewer
than 3 suggests the scope is underspecified. More than 7 suggests it
might be too large.

### 3. Architectural Constraints
What tech stack, patterns, security requirements, or conventions apply.
Reference ARCHITECTURE.md and PATTERNS.md where relevant. If the Scope
touches areas covered by ANTI-PATTERNS.md, note the boundaries.

If no constraints apply, explicitly state "No additional constraints
beyond ARCHITECTURE.md" rather than leaving this blank.

### 4. Dependencies
What must be true or in place before this work can start or complete.
This includes:
- Other issues or scopes that must complete first
- External teams or services that need to provide something
- Infrastructure or access that needs provisioning
- Data or APIs that must be available

If there are no dependencies, state "None" explicitly.

### 5. Context
What does this connect to in the broader system?
- **Upstream:** What feeds into this? What triggers it?
- **Downstream:** What depends on this? What consumes its output?
- **Related:** What other work is happening in the same area?

### 6. Out of Scope
What this work explicitly does NOT cover. This prevents scope creep
during planning and delivery. Be specific.

Good: "This scope covers ingestion only. Enrichment, correlation, and
alerting on the ingested data are separate scopes."

Bad: (leaving this blank)

### 7. Origin
Where this work came from:
- OKR / Milestone reference (e.g., "Q2 2026 OKR: Argus is operationally valuable")
- Reactive ticket reference (e.g., "Incident INC-1234")
- Ad-hoc (with brief justification for why it matters now)

### 8. Risk / Unknowns
Things the scoper is already aware might be tricky, uncertain, or
require investigation. This saves the AI from generating a plan that
ignores known landmines.

Examples:
- "Schema v2 may not be finalised yet — check with data team"
- "Databricks query performance at scale is untested"
- "This touches the auth layer which has had reliability issues"

If no known risks, state "None identified" explicitly.

### 9. Delivery Preference
Whether the human expects this to be:
- **Mostly AI-delivered** — standard code/config/docs work
- **Mostly human-delivered** — requires org context, vendor access, etc.
- **Mixed** — some tasks AI, some human (specify which aspects)

This helps the AI generate a Plan with realistic task assignments.
