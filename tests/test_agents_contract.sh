#!/usr/bin/env bash
# AI-OS AGENTS.md Safety Content Contract Test Suite
# Asserts that AGENTS.md (master and template) retains all core safety criteria by content.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing AGENTS.md Safety Content Contract"
echo "============================================================"

# Verification function that checks all 8 required criteria on a given file
verify_agents_contract() {
    local target_file="$1"
    local label="$2"
    
    if [ ! -f "$target_file" ]; then
        echo "❌ File not found: $target_file" >&2
        return 1
    fi
    
    local content
    content=$(cat "$target_file")
    
    # 1. Candidate gate (no direct rule append, must record candidate)
    assert_contains "$content" "mistakes-candidates.md" "$label: Must enforce candidate gate via mistakes-candidates.md"
    
    # 2. Safe self-modification / untrusted source defense
    if ! echo "$content" | grep -Ei "(untrusted source|external content|prompt injection|cannot authorize.*rule)" >/dev/null; then
        echo "ASSERTION FAILED: $label: Must contain safe self-modification / untrusted source defense" >&2
        return 1
    fi
    
    # 3. Never record secrets in rules / persistent state
    if ! echo "$content" | grep -Ei "(never.*(record|learn|persist|commit|hardcode).*secret)" >/dev/null; then
        echo "ASSERTION FAILED: $label: Must contain never-record-secrets directive" >&2
        return 1
    fi
    
    # 4. Conflict detection
    if ! echo "$content" | grep -Ei "(conflict|duplicate.*prevent|contradict)" >/dev/null; then
        echo "ASSERTION FAILED: $label: Must contain conflict detection directive" >&2
        return 1
    fi
    
    # 5. 4-part prompt contract (GOAL, CONSTRAINTS, FORMAT, FAILURE)
    assert_contains "$content" "GOAL" "$label: Contract must include GOAL"
    assert_contains "$content" "CONSTRAINTS" "$label: Contract must include CONSTRAINTS"
    assert_contains "$content" "FORMAT" "$label: Contract must include FORMAT"
    assert_contains "$content" "FAILURE" "$label: Contract must include FAILURE"
    
    # 6. Instruction-priority order
    assert_contains "$content" "System safety" "$label: Priority must include System safety"
    assert_contains "$content" "Explicit user instructions" "$label: Priority must include Explicit user instructions"
    assert_contains "$content" "Agent defaults" "$label: Priority must include Agent defaults"
    
    # 7. On-demand loading pointer to playbooks
    if ! echo "$content" | grep -Ei "(playbooks/|\.ai-os/playbooks)" >/dev/null; then
        echo "ASSERTION FAILED: $label: Must reference on-demand playbooks" >&2
        return 1
    fi
    
    # 8. Non-interactive escape for reverse prompting
    if ! echo "$content" | grep -Ei "(non-interactive|batch|automated)" >/dev/null; then
        echo "ASSERTION FAILED: $label: Must specify non-interactive escape for reverse prompting" >&2
        return 1
    fi
    
    # 9. Explicit authorization gate (must be <= 250 bytes and match all 4: merge, tag or release, repository settings, continue)
    local rule_line
    rule_line=$(grep -i "explicit instruction" "$target_file" || true)
    if [ -z "$rule_line" ]; then
        echo "ASSERTION FAILED: $label: Must contain explicit authorization gate rule line" >&2
        return 1
    fi
    local rule_len
    rule_len=$(echo "$rule_line" | wc -c)
    if [ "$rule_len" -gt 250 ]; then
        echo "ASSERTION FAILED: $label: Rule line length ($rule_len bytes) exceeds 250 bytes limit" >&2
        return 1
    fi
    if ! echo "$content" | grep -qi "merge"; then
        echo "ASSERTION FAILED: $label: Must match 'merge'" >&2
        return 1
    fi
    if ! echo "$content" | grep -qiE "(tag|release)"; then
        echo "ASSERTION FAILED: $label: Must match 'tag or release'" >&2
        return 1
    fi
    if ! echo "$content" | grep -qi "repository settings"; then
        echo "ASSERTION FAILED: $label: Must match 'repository settings'" >&2
        return 1
    fi
    if ! echo "$content" | grep -qi "continue"; then
        echo "ASSERTION FAILED: $label: Must match 'continue'" >&2
        return 1
    fi
    
    # 10. Evidence & Verification block (must exist, be <= 700 bytes, and match all 5 required clauses)
    local ev_block
    ev_block=$(sed -n '/Evidence & Verification/,/Details:.*hallucination-guard/p' "$target_file" || true)
    if [ -z "$ev_block" ]; then
        echo "ASSERTION FAILED: $label: Must contain Evidence & Verification block" >&2
        return 1
    fi
    local ev_len
    ev_len=$(echo "$ev_block" | wc -c)
    if [ "$ev_len" -gt 700 ]; then
        echo "ASSERTION FAILED: $label: Evidence & Verification block length ($ev_len bytes) exceeds 700 bytes limit" >&2
        return 1
    fi
    if ! echo "$ev_block" | grep -qiE "never claim tests pass.*without evidence"; then
        echo "ASSERTION FAILED: $label: Evidence block must match 'never claim tests pass without evidence'" >&2
        return 1
    fi
    if ! echo "$ev_block" | grep -qi "deps-approved.txt"; then
        echo "ASSERTION FAILED: $label: Evidence block must match 'deps-approved.txt'" >&2
        return 1
    fi
    if ! echo "$ev_block" | grep -qi "file:line"; then
        echo "ASSERTION FAILED: $label: Evidence block must match 'file:line'" >&2
        return 1
    fi
    if ! echo "$ev_block" | grep -qi "never guess signatures"; then
        echo "ASSERTION FAILED: $label: Evidence block must match 'never guess signatures'" >&2
        return 1
    fi
    if ! echo "$ev_block" | grep -qi "ai-os-run"; then
        echo "ASSERTION FAILED: $label: Evidence block must match 'ai-os-run'" >&2
        return 1
    fi
    
    return 0
}

# --- Tests ---

test_stripped_agents_fails_contract() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local stripped="$sandbox/STRIPPED_AGENTS.md"
    
    # Deliberately stripped copy missing safety rules and escapes
    cat << 'EOF' > "$stripped"
# Basic Agent Rules
## 1. Operating Rules
- Write good code.
- Answer user questions.
## 2. Learned Rules
1. [CODE] Use bun — faster.
EOF

    local failed=0
    verify_agents_contract "$stripped" "Stripped AGENTS.md" >/dev/null 2>&1 || failed=1
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$failed" "Stripped AGENTS.md must FAIL safety contract verification"
}

test_master_agents_satisfies_contract() {
    verify_agents_contract "$REPO_ROOT/AGENTS.md" "Master AGENTS.md"
}

test_template_agents_satisfies_contract() {
    verify_agents_contract "$REPO_ROOT/templates/project/AGENTS.md" "Template AGENTS.md"
}

test_codeowners_covers_deps_approved() {
    local codeowners_file="$REPO_ROOT/.github/CODEOWNERS"
    if [ ! -f "$codeowners_file" ]; then
        echo "ASSERTION FAILED: .github/CODEOWNERS not found" >&2
        return 1
    fi
    if ! grep -q "\.ai/deps-approved\.txt" "$codeowners_file"; then
        echo "ASSERTION FAILED: .github/CODEOWNERS must cover .ai/deps-approved.txt" >&2
        return 1
    fi
    return 0
}

run_test "AGENTS.md Contract: Stripped file FAILS safety criteria" test_stripped_agents_fails_contract
run_test "AGENTS.md Contract: Master AGENTS.md PASSES safety criteria" test_master_agents_satisfies_contract
run_test "AGENTS.md Contract: Template AGENTS.md PASSES safety criteria" test_template_agents_satisfies_contract
run_test "AGENTS.md Contract: CODEOWNERS covers .ai/deps-approved.txt" test_codeowners_covers_deps_approved

echo ""
echo "AGENTS Contract Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0
