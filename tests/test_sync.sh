#!/usr/bin/env bash
# AI-OS Federated Sync & Quality Gate Test Suite (Verifying F6 Fixes)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing Federated Rule Sync & Quality Gate"
echo "============================================================"

test_gate_rejects_rule_with_secrets() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.ai/rules"
    # Construct key dynamically so fixture does not trigger pre-commit scanner
    local sec_prefix="sk"
    local fake_sec="${sec_prefix}-proj-1234567890abcdefghijklmnopqrstuvwxyz"
    echo "1. [SECURITY] Use secret key ${fake_sec} for api calls — needed for auth." > "$sandbox/.ai/rules/0001-secret-rule.md"
    
    local sync_output
    sync_output=$("$REPO_ROOT/scripts/sync-rules.sh" --project "$sandbox" 2>&1 || true)
    cleanup_sandbox "$sandbox"
    
    assert_contains "$sync_output" "Contains credential or secret pattern" "10-point gate must reject rules containing credentials"
}

test_gate_rejects_rule_without_rationale() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.ai/rules"
    echo "1. [CODE] Always write good clean code every day." > "$sandbox/.ai/rules/0001-no-rationale.md"
    
    local sync_output
    sync_output=$("$REPO_ROOT/scripts/sync-rules.sh" --project "$sandbox" 2>&1 || true)
    cleanup_sandbox "$sandbox"
    
    assert_contains "$sync_output" "Missing evidence/rationale separator" "10-point gate must reject rules without rationale"
}

test_gate_rejects_rule_with_local_paths() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.ai/rules"
    echo "1. [ARCH] Put files into /Users/rudra/project/apps/web/ — project specific architecture." > "$sandbox/.ai/rules/0001-local-path.md"
    
    local sync_output
    sync_output=$("$REPO_ROOT/scripts/sync-rules.sh" --project "$sandbox" 2>&1 || true)
    cleanup_sandbox "$sandbox"
    
    assert_contains "$sync_output" "Contains project-specific local file paths" "10-point gate must reject rules with local paths"
}

test_gate_skips_existing_master_rule() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.ai/rules"
    # Rule 1 already exists in master
    echo "1. [PROCESS] Read existing files and understand system boundaries before editing code — avoids breaking established architecture or introducing redundant logic." > "$sandbox/.ai/rules/0001-dup.md"
    
    local sync_output
    sync_output=$("$REPO_ROOT/scripts/sync-rules.sh" --project "$sandbox" 2>&1 || true)
    cleanup_sandbox "$sandbox"
    
    assert_contains "$sync_output" "duplicate" "10-point gate must skip existing duplicate master rules"
}

test_gate_creates_valid_proposal() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.ai/rules"
    echo "1. [UX] Always include loading indicators on async actions — improves user perception during long operations." > "$sandbox/.ai/rules/0001-loading-state.md"
    
    local sync_output
    sync_output=$("$REPO_ROOT/scripts/sync-rules.sh" --project "$sandbox" 2>&1 || true)
    cleanup_sandbox "$sandbox"
    # Clean up created proposal file so tests leave clean working tree
    find "$REPO_ROOT/proposals" -maxdepth 1 -name "*-always-include-loading-indicators-on-asy.md" -delete 2>/dev/null || true
    
    assert_contains "$sync_output" "PROPOSAL GENERATED" "10-point gate must create proposal for valid candidate rule"
}

# Run all gate tests
run_test "sync-rules: Rejects candidate rule containing secrets" test_gate_rejects_rule_with_secrets
run_test "sync-rules: Rejects candidate rule without rationale" test_gate_rejects_rule_without_rationale
run_test "sync-rules: Rejects candidate rule with local paths" test_gate_rejects_rule_with_local_paths
run_test "sync-rules: Skips duplicate rule already in master" test_gate_skips_existing_master_rule
run_test "sync-rules: Creates proposal for valid engineering rule" test_gate_creates_valid_proposal

echo ""
echo "Sync Gate Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0
