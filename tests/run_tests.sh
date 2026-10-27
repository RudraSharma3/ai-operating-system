#!/usr/bin/env bash
# AI-OS Master Test Runner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_FAILED=0

echo "============================================================"
echo " 🛡️ RUNNING ALL AI-OS INTEGRATION & REGRESSION TESTS"
echo "============================================================"
echo ""

run_suite() {
    local suite_script="$1"
    echo "▶️ Running Suite: $(basename "$suite_script")"
    if ! bash "$suite_script"; then
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
}

run_suite "$SCRIPT_DIR/test_hook.sh"
run_suite "$SCRIPT_DIR/test_installer.sh"
run_suite "$SCRIPT_DIR/test_sync.sh"
run_suite "$SCRIPT_DIR/test_agents_contract.sh"
run_suite "$SCRIPT_DIR/test_claude_hooks.sh"

echo "============================================================"
if [ "$TOTAL_FAILED" -eq 0 ]; then
    echo " 🎉 ALL TEST SUITES PASSED!"
    exit 0
else
    echo " ❌ $TOTAL_FAILED TEST SUITE(S) FAILED!"
    exit 1
fi
