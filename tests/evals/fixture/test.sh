#!/usr/bin/env bash
# Run the greeting checks; exits non-zero on the first failure.
set -eu
[ "$(./greet.sh Ada)" = "Hello, Ada!" ] || { echo "FAIL: named greeting"; exit 1; }
[ "$(./greet.sh)" = "Hello, world!" ] || { echo "FAIL: default greeting"; exit 1; }
echo "ok"
