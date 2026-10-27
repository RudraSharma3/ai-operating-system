#!/usr/bin/env bash
# Integration test for evals/run_task.sh and evals/run_task.ps1
# Tests deterministic stub-agents passed via --agent-cmd:
#   (a) Stub that applies reference solution -> reports PASS
#   (b) Stub that does nothing -> reports FAIL
# Tests both --mode with and --mode without across Bash and PowerShell.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

assert_eq() {
    TEST_COUNT=$((TEST_COUNT + 1))
    local expected="$1"
    local actual="$2"
    local msg="$3"
    if [ "$expected" = "$actual" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "  [PASS] $msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  [FAIL] $msg: expected '$expected', got '$actual'"
    fi
}

echo "=== Testing Eval Harness Stub-Agent Integration ==="

STUB_APPLY_BASH="bash $SCRIPT_DIR/stub_agent.sh --mode apply"
STUB_NOOP_BASH="bash $SCRIPT_DIR/stub_agent.sh --mode noop"

# --- 1. Bash Harness Tests (evals/run_task.sh) ---

# Test 1: Bash --mode with + Stub Apply Reference -> PASS
echo "▶️ Testing Bash: --mode with --agent-cmd (apply reference)..."
status_with_apply=0
out_with_apply=$(bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode with --agent-cmd "$STUB_APPLY_BASH" 2>&1) || status_with_apply=$?
assert_eq 0 "$status_with_apply" "run_task.sh with apply-stub in --mode with must PASS (exit 0)"

# Test 2: Bash --mode with + Stub Noop -> FAIL
echo "▶️ Testing Bash: --mode with --agent-cmd (noop)..."
status_with_noop=0
out_with_noop=$(bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode with --agent-cmd "$STUB_NOOP_BASH" 2>&1) || status_with_noop=$?
assert_eq 1 "$status_with_noop" "run_task.sh with noop-stub in --mode with must FAIL (exit 1)"

# Test 3: Bash --mode without + Stub Apply Reference -> PASS
echo "▶️ Testing Bash: --mode without --agent-cmd (apply reference)..."
status_without_apply=0
out_without_apply=$(bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode without --agent-cmd "$STUB_APPLY_BASH" 2>&1) || status_without_apply=$?
assert_eq 0 "$status_without_apply" "run_task.sh with apply-stub in --mode without must PASS (exit 0)"

# Test 4: Bash --mode without + Stub Noop -> FAIL
echo "▶️ Testing Bash: --mode without --agent-cmd (noop)..."
status_without_noop=0
out_without_noop=$(bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode without --agent-cmd "$STUB_NOOP_BASH" 2>&1) || status_without_noop=$?
assert_eq 1 "$status_without_noop" "run_task.sh with noop-stub in --mode without must FAIL (exit 1)"

# --- 2. PowerShell Harness Tests (evals/run_task.ps1) on Windows ---
if command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
    PS_BIN="powershell.exe"
    command -v pwsh >/dev/null 2>&1 && PS_BIN="pwsh"

    # Convert SCRIPT_DIR to Windows path for PowerShell if running under Git Bash
    WIN_SCRIPT_DIR="$SCRIPT_DIR"
    if command -v cygpath >/dev/null 2>&1; then
        WIN_SCRIPT_DIR=$(cygpath -w "$SCRIPT_DIR")
    fi

    STUB_APPLY_PS="powershell.exe -ExecutionPolicy Bypass -File \"$WIN_SCRIPT_DIR\\stub_agent.ps1\" -Action apply"
    STUB_NOOP_PS="powershell.exe -ExecutionPolicy Bypass -File \"$WIN_SCRIPT_DIR\\stub_agent.ps1\" -Action noop"

    # Test 5: PowerShell -Mode with + Stub Apply Reference -> PASS
    echo "▶️ Testing PowerShell: -Mode with -AgentCmd (apply reference)..."
    status_ps_with_apply=0
    $PS_BIN -ExecutionPolicy Bypass -File "$WIN_SCRIPT_DIR\\run_task.ps1" -Task 01-bug-fix -Mode with -AgentCmd "$STUB_APPLY_PS" >/dev/null 2>&1 || status_ps_with_apply=$?
    assert_eq 0 "$status_ps_with_apply" "run_task.ps1 with apply-stub in -Mode with must PASS"

    # Test 6: PowerShell -Mode with + Stub Noop -> FAIL
    echo "▶️ Testing PowerShell: -Mode with -AgentCmd (noop)..."
    status_ps_with_noop=0
    $PS_BIN -ExecutionPolicy Bypass -File "$WIN_SCRIPT_DIR\\run_task.ps1" -Task 01-bug-fix -Mode with -AgentCmd "$STUB_NOOP_PS" >/dev/null 2>&1 || status_ps_with_noop=$?
    assert_eq 1 "$status_ps_with_noop" "run_task.ps1 with noop-stub in -Mode with must FAIL"

    # Test 7: PowerShell -Mode without + Stub Apply Reference -> PASS
    echo "▶️ Testing PowerShell: -Mode without -AgentCmd (apply reference)..."
    status_ps_without_apply=0
    $PS_BIN -ExecutionPolicy Bypass -File "$WIN_SCRIPT_DIR\\run_task.ps1" -Task 01-bug-fix -Mode without -AgentCmd "$STUB_APPLY_PS" >/dev/null 2>&1 || status_ps_without_apply=$?
    assert_eq 0 "$status_ps_without_apply" "run_task.ps1 with apply-stub in -Mode without must PASS"

    # Test 8: PowerShell -Mode without + Stub Noop -> FAIL
    echo "▶️ Testing PowerShell: -Mode without -AgentCmd (noop)..."
    status_ps_without_noop=0
    $PS_BIN -ExecutionPolicy Bypass -File "$WIN_SCRIPT_DIR\\run_task.ps1" -Task 01-bug-fix -Mode without -AgentCmd "$STUB_NOOP_PS" >/dev/null 2>&1 || status_ps_without_noop=$?
    assert_eq 1 "$status_ps_without_noop" "run_task.ps1 with noop-stub in -Mode without must FAIL"
fi

echo ""
echo "Harness Test Summary: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ] || exit 1
