#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# validate_examples.sh — CRG Grade B: check examples/ .lfe files for syntax errors
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
SKIP=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
skip() { echo "SKIP: $1"; SKIP=$((SKIP + 1)); }

# Grace-degrade if LFE/Erlang toolchain not available
if ! command -v erlc &>/dev/null; then
    skip "erlc not found — skipping example syntax validation"
    echo ""
    echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
    exit 0
fi

# Find LFE ebin directory for include path
LFE_EBIN=""
if [ -d "_build/default/lib/lfe/ebin" ]; then
    LFE_EBIN="-pa _build/default/lib/lfe/ebin"
fi

EXAMPLES=()
while IFS= read -r -d '' f; do
    EXAMPLES+=("$f")
done < <(find examples -maxdepth 1 -name '*.lfe' -print0 2>/dev/null)

if [ "${#EXAMPLES[@]}" -eq 0 ]; then
    skip "No .lfe files found in examples/ — nothing to validate"
    echo ""
    echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
    exit 0
fi

for f in "${EXAMPLES[@]}"; do
    filename="$(basename "$f")"
    # Count error lines; 0 errors = pass
    # shellcheck disable=SC2086
    error_count=$(erlc $LFE_EBIN "$f" 2>&1 | grep -c "Error" || true)
    if [ "$error_count" -eq 0 ]; then
        pass "examples/$filename — no syntax errors"
    else
        fail "examples/$filename — $error_count error(s) detected"
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
