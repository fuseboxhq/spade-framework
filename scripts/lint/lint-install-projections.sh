#!/usr/bin/env bash
set -euo pipefail

# Run the isolated exact-manifest, idempotency, stale-file, and path-safety suite.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$REPO_ROOT/tests/install-projections.sh"
