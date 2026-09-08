#!/usr/bin/env bash
set -euo pipefail

# Validate the generated Codex plugin with stdlib-only schema checks.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$REPO_ROOT/scripts/lint/validate-codex-plugin.py" "$REPO_ROOT" --allow-checkout-name
python3 "$REPO_ROOT/scripts/lint/validate-codex-plugin.py" --allow-checkout-name
python3 "$REPO_ROOT/scripts/lint/validate-codex-plugin.py" "$REPO_ROOT/plugins/spade-framework"
python3 -m json.tool "$REPO_ROOT/.agents/plugins/marketplace.json" >/dev/null
echo "lint-codex-plugin: marketplace and both plugin payloads are valid"
