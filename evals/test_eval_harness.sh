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
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode with --agent-cmd "$STUB_APPLY_BASH" >/dev/null 2>&1 || status_with_apply=$?
assert_eq 0 "$status_with_apply" "run_task.sh with apply-stub in --mode with must PASS (exit 0)"

# Test 2: Bash --mode with + Stub Noop -> FAIL
echo "▶️ Testing Bash: --mode with --agent-cmd (noop)..."
status_with_noop=0
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode with --agent-cmd "$STUB_NOOP_BASH" >/dev/null 2>&1 || status_with_noop=$?
assert_eq 1 "$status_with_noop" "run_task.sh with noop-stub in --mode with must FAIL (exit 1)"

# Test 3: Bash --mode without + Stub Apply Reference -> PASS
echo "▶️ Testing Bash: --mode without --agent-cmd (apply reference)..."
status_without_apply=0
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode without --agent-cmd "$STUB_APPLY_BASH" >/dev/null 2>&1 || status_without_apply=$?
assert_eq 0 "$status_without_apply" "run_task.sh with apply-stub in --mode without must PASS (exit 0)"

# Test 4: Bash --mode without + Stub Noop -> FAIL
echo "▶️ Testing Bash: --mode without --agent-cmd (noop)..."
status_without_noop=0
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --mode without --agent-cmd "$STUB_NOOP_BASH" >/dev/null 2>&1 || status_without_noop=$?
assert_eq 1 "$status_without_noop" "run_task.sh with noop-stub in --mode without must FAIL (exit 1)"

# --- 2. PowerShell Harness Tests (evals/run_task.ps1) ---
if command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
    PS_BIN="powershell.exe"
    if ! command -v powershell.exe >/dev/null 2>&1 && command -v pwsh >/dev/null 2>&1; then
        PS_BIN="pwsh"
    fi

    # Convert SCRIPT_DIR to Windows path (mixed slashes) for PowerShell if running under Git Bash
    PS_SCRIPT_DIR="$SCRIPT_DIR"
    if command -v cygpath >/dev/null 2>&1; then
        PS_SCRIPT_DIR=$(cygpath -m "$SCRIPT_DIR")
    fi

    STUB_APPLY_PS="$PS_BIN -ExecutionPolicy Bypass -File \"$PS_SCRIPT_DIR/stub_agent.ps1\" -Action apply"
    STUB_NOOP_PS="$PS_BIN -ExecutionPolicy Bypass -File \"$PS_SCRIPT_DIR/stub_agent.ps1\" -Action noop"

    # Test 5: PowerShell -Mode with + Stub Apply Reference -> PASS
    echo "▶️ Testing PowerShell: -Mode with -AgentCmd (apply reference)..."
    status_ps_with_apply=0
    $PS_BIN -ExecutionPolicy Bypass -File "$PS_SCRIPT_DIR/run_task.ps1" -Task 01-bug-fix -Mode with -AgentCmd "$STUB_APPLY_PS" >/dev/null 2>&1 || status_ps_with_apply=$?
    assert_eq 0 "$status_ps_with_apply" "run_task.ps1 with apply-stub in -Mode with must PASS"

    # Test 6: PowerShell -Mode with + Stub Noop -> FAIL
    echo "▶️ Testing PowerShell: -Mode with -AgentCmd (noop)..."
    status_ps_with_noop=0
    $PS_BIN -ExecutionPolicy Bypass -File "$PS_SCRIPT_DIR/run_task.ps1" -Task 01-bug-fix -Mode with -AgentCmd "$STUB_NOOP_PS" >/dev/null 2>&1 || status_ps_with_noop=$?
    assert_eq 1 "$status_ps_with_noop" "run_task.ps1 with noop-stub in -Mode with must FAIL"

    # Test 7: PowerShell -Mode without + Stub Apply Reference -> PASS
    echo "▶️ Testing PowerShell: -Mode without -AgentCmd (apply reference)..."
    status_ps_without_apply=0
    $PS_BIN -ExecutionPolicy Bypass -File "$PS_SCRIPT_DIR/run_task.ps1" -Task 01-bug-fix -Mode without -AgentCmd "$STUB_APPLY_PS" >/dev/null 2>&1 || status_ps_without_apply=$?
    assert_eq 0 "$status_ps_without_apply" "run_task.ps1 with apply-stub in -Mode without must PASS"

    # Test 8: PowerShell -Mode without + Stub Noop -> FAIL
    echo "▶️ Testing PowerShell: -Mode without -AgentCmd (noop)..."
    status_ps_without_noop=0
    $PS_BIN -ExecutionPolicy Bypass -File "$PS_SCRIPT_DIR/run_task.ps1" -Task 01-bug-fix -Mode without -AgentCmd "$STUB_NOOP_PS" >/dev/null 2>&1 || status_ps_without_noop=$?
    assert_eq 1 "$status_ps_without_noop" "run_task.ps1 with noop-stub in -Mode without must FAIL"
fi

# --- 3. Sandbox Isolation & Safety Tests ---

# Test 9: Refusal when --agent-cmd contains --dangerously-skip-permissions without AI_OS_EVAL_SANDBOX=1
echo "▶️ Testing refusal of --dangerously-skip-permissions without env var..."
status_danger_refused=0
AI_OS_EVAL_SANDBOX=0 bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --agent-cmd "claude --dangerously-skip-permissions -p" >/dev/null 2>&1 || status_danger_refused=$?
assert_eq 1 "$status_danger_refused" "run_task.sh must refuse --dangerously-skip-permissions when AI_OS_EVAL_SANDBOX is unset/0"

# Test 10: Refusal when sandbox directory is under repository tree
echo "▶️ Testing refusal when target directory is located under repository tree..."
mkdir -p "$ROOT_DIR/scratch/illegal_sandbox"
status_tree_refused=0
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --target "$ROOT_DIR/scratch/illegal_sandbox" >/dev/null 2>&1 || status_tree_refused=$?
rm -rf "$ROOT_DIR/scratch/illegal_sandbox" 2>/dev/null || true
assert_eq 1 "$status_tree_refused" "run_task.sh must refuse sandbox located inside repository tree"

# Test 11: Secret environment stripping before launching agent command
echo "▶️ Testing secret environment stripping with stub agent..."
SAFE_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t 'safe_tmp')
export SECRET_KEY_TEST="leaked_secret_val"
export AWS_ACCESS_KEY_ID="leaked_aws_id"
export GITHUB_TOKEN="leaked_gh_token"
export DB_PASSWORD_TEST="leaked_db_pwd"

bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --agent-cmd "bash $SCRIPT_DIR/stub_agent.sh --mode print-env" --target "$SAFE_TMP" >/dev/null 2>&1 || true

ENV_LEAKS=0
if [ -f "$SAFE_TMP/stub_env.txt" ]; then
    if grep -E 'SECRET_KEY_TEST|AWS_ACCESS_KEY_ID|GITHUB_TOKEN|DB_PASSWORD_TEST' "$SAFE_TMP/stub_env.txt" >/dev/null 2>&1; then
        ENV_LEAKS=1
    fi
else
    ENV_LEAKS=1
fi
rm -rf "$SAFE_TMP" 2>/dev/null || true
assert_eq 0 "$ENV_LEAKS" "run_task.sh must strip secret environment variables before executing agent command"

# Test 12: Negative control suite with --expect-fail exits 0
echo "▶️ Testing negative-control suite with --expect-fail (exits 0 on all rejections)..."
status_expect_fail=0
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --negative --expect-fail >/dev/null 2>&1 || status_expect_fail=$?
assert_eq 0 "$status_expect_fail" "run_task.sh with --negative --expect-fail must exit 0 when all controls rejected"

# Test 13: Default run (no passthrough) leaves ANTHROPIC_API_KEY absent
echo "▶️ Testing default run leaves ANTHROPIC_API_KEY absent..."
SAFE_TMP_DEFAULT=$(mktemp -d 2>/dev/null || mktemp -d -t 'safe_tmp_def')
export ANTHROPIC_API_KEY="test_anthropic_secret_key"
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --agent-cmd "bash $SCRIPT_DIR/stub_agent.sh --mode print-env" --target "$SAFE_TMP_DEFAULT" >/dev/null 2>&1 || true
has_anthropic=0
if [ -f "$SAFE_TMP_DEFAULT/stub_env.txt" ] && grep -q 'ANTHROPIC_API_KEY' "$SAFE_TMP_DEFAULT/stub_env.txt"; then
    has_anthropic=1
fi
rm -rf "$SAFE_TMP_DEFAULT" 2>/dev/null || true
assert_eq 0 "$has_anthropic" "default run without --pass-env must strip ANTHROPIC_API_KEY"

# Test 14: Run with --pass-env ANTHROPIC_API_KEY preserves it
echo "▶️ Testing --pass-env ANTHROPIC_API_KEY preserves allowed variable..."
SAFE_TMP_PASS=$(mktemp -d 2>/dev/null || mktemp -d -t 'safe_tmp_pass')
export ANTHROPIC_API_KEY="test_anthropic_secret_key"
export OTHER_SECRET_KEY="other_secret_val"
bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --pass-env ANTHROPIC_API_KEY --agent-cmd "bash $SCRIPT_DIR/stub_agent.sh --mode print-env" --target "$SAFE_TMP_PASS" >/dev/null 2>&1 || true
pass_survived=0
other_stripped=1
if [ -f "$SAFE_TMP_PASS/stub_env.txt" ]; then
    grep -q 'ANTHROPIC_API_KEY=test_anthropic_secret_key' "$SAFE_TMP_PASS/stub_env.txt" && pass_survived=1
    grep -q 'OTHER_SECRET_KEY' "$SAFE_TMP_PASS/stub_env.txt" && other_stripped=0
fi
rm -rf "$SAFE_TMP_PASS" 2>/dev/null || true
assert_eq 1 "$pass_survived" "run with --pass-env ANTHROPIC_API_KEY must preserve ANTHROPIC_API_KEY"
assert_eq 1 "$other_stripped" "run with --pass-env must still strip unpassed secrets"

# Test 15: Run with --pass-env GITHUB_TOKEN without AI_OS_EVAL_SANDBOX=1 is refused
echo "▶️ Testing refusal of cloud/source-control credential in --pass-env without sandbox flag..."
status_gh_refused=0
AI_OS_EVAL_SANDBOX=0 bash "$SCRIPT_DIR/run_task.sh" --task 01-bug-fix --pass-env GITHUB_TOKEN --agent-cmd "bash $SCRIPT_DIR/stub_agent.sh --mode noop" >/dev/null 2>&1 || status_gh_refused=$?
assert_eq 1 "$status_gh_refused" "--pass-env GITHUB_TOKEN without AI_OS_EVAL_SANDBOX=1 must be refused (exit 1)"

unset ANTHROPIC_API_KEY OTHER_SECRET_KEY 2>/dev/null || true

echo ""
echo "Harness Test Summary: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ] || exit 1
