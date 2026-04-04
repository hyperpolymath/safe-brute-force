#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# validate_structure.sh — CRG Grade B structural check for safe-brute-force
set -euo pipefail

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Required root files
[ -f README.adoc ]    && pass "README.adoc present"    || fail "README.adoc missing"
[ -f LICENSE ]        && pass "LICENSE present"         || fail "LICENSE missing"
[ -f SECURITY.md ]    && pass "SECURITY.md present"    || fail "SECURITY.md missing"
[ -f Justfile ]       && pass "Justfile present"        || fail "Justfile missing"
[ -f rebar.config ]   && pass "rebar.config present"   || fail "rebar.config missing"

# Required directories
[ -d src ]            && pass "src/ directory present"  || fail "src/ directory missing"
[ -d test ]           && pass "test/ directory present" || fail "test/ directory missing"

# GitHub workflows — require at least 3
WORKFLOW_COUNT=0
if [ -d .github/workflows ]; then
    WORKFLOW_COUNT=$(find .github/workflows -maxdepth 1 -name '*.yml' -o -name '*.yaml' | wc -l)
fi
if [ "$WORKFLOW_COUNT" -ge 3 ]; then
    pass ".github/workflows/ has $WORKFLOW_COUNT workflow files (≥3 required)"
else
    fail ".github/workflows/ has only $WORKFLOW_COUNT workflow files (≥3 required)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
