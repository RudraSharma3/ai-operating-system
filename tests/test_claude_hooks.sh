#!/usr/bin/env bash
# Unit tests for Claude Code hooks (.ai-os/optional/claude-hooks/)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/.ai-os/optional/claude-hooks"

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

assert_contains() {
    TEST_COUNT=$((TEST_COUNT + 1))
    local needle="$1"
    local haystack="$2"
    local msg="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "  [PASS] $msg"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  [FAIL] $msg: did not find '$needle'"
    fi
}

echo "=== Testing Claude Code Opt-In Hooks ==="

TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'claude-hooks-test')
trap 'rm -rf "$TMP_DIR"' EXIT

export CLAUDE_PROJECT_DIR="$TMP_DIR"
mkdir -p "$TMP_DIR/docs"
echo "# Active Task" > "$TMP_DIR/docs/task-state.md"
echo "Rule 1" > "$TMP_DIR/AGENTS.md"

# Test 1: session-start.sh runs and prints budget & task state
out_session=$(echo '{}' | bash "$HOOKS_DIR/session-start.sh")
assert_contains "AI-OS Claude Code Session Active" "$out_session" "SessionStart prints header"
assert_contains "Token Budget" "$out_session" "SessionStart prints token budget"
assert_contains "Task State Summary" "$out_session" "SessionStart prints task state"

# Test 2: pre-compact.sh appends checkpoint
out_compact=$(echo '{}' | bash "$HOOKS_DIR/pre-compact.sh")
assert_contains "Pre-compaction checkpoint" "$out_compact" "PreCompact logs checkpoint"
content_task_state=$(cat "$TMP_DIR/docs/task-state.md")
assert_contains "Compaction Checkpoint" "$content_task_state" "PreCompact appends checkpoint to task-state.md"

# Test 3: pre-tool-use.sh blocks AGENTS.md without AI_OS_ALLOW_GOVERNANCE_EDIT
json_agents='{"tool_name":"Write","tool_input":{"file_path":"AGENTS.md","content":"malicious"}}'
out_block_agents=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_agents" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_block_agents" "PreToolUse blocks AGENTS.md edit"

# Test 4: pre-tool-use.sh allows AGENTS.md with AI_OS_ALLOW_GOVERNANCE_EDIT=1
out_allow_agents=$(export AI_OS_ALLOW_GOVERNANCE_EDIT=1; echo "$json_agents" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_eq "" "$out_allow_agents" "PreToolUse allows AGENTS.md edit when AI_OS_ALLOW_GOVERNANCE_EDIT=1"

# Test 5: pre-tool-use.sh blocks .githooks and scripts
json_hooks='{"tool_name":"Edit","tool_input":{"file_path":".githooks/pre-commit","content":"echo bypassed"}}'
out_block_hooks=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_hooks" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_block_hooks" "PreToolUse blocks .githooks edit"

json_scripts='{"tool_name":"Edit","tool_input":{"file_path":"scripts/install.sh","content":"bad"}}'
out_block_scripts=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_scripts" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_block_scripts" "PreToolUse blocks scripts/ edit"

json_deps='{"tool_name":"Write","tool_input":{"file_path":".ai/deps-approved.txt","content":"tamper"}}'
out_block_deps=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_deps" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_block_deps" "PreToolUse blocks .ai/deps-approved.txt edit"

# Test 6: pre-tool-use.sh allows normal app file edits
json_app='{"tool_name":"Write","tool_input":{"file_path":"src/index.js","content":"console.log(1);"}}'
out_app=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_app" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_eq "" "$out_app" "PreToolUse allows normal application files"

# Test 7: pre-tool-use.sh blocks git commit --no-verify
json_no_verify='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"skip check\" --no-verify"}}'
out_no_verify=$(echo "$json_no_verify" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_no_verify" "PreToolUse blocks git commit --no-verify"

# Test 8: pre-tool-use.sh blocks git push --force
json_force='{"tool_name":"Bash","tool_input":{"command":"git push origin main --force"}}'
out_force=$(echo "$json_force" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_force" "PreToolUse blocks git push --force"

# Test 8b: pre-tool-use.sh blocks NotebookEdit on governance files
json_notebook='{"tool_name":"NotebookEdit","tool_input":{"file_path":".ai/deps-approved.txt","content":"tamper"}}'
out_block_nb=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_notebook" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_contains '"permissionDecision": "deny"' "$out_block_nb" "PreToolUse blocks NotebookEdit on .ai/deps-approved.txt"

# Test 9: pre-tool-use.sh allows legitimate git commands
json_legit_git='{"tool_name":"Bash","tool_input":{"command":"git push origin hardening"}}'
out_legit_git=$(echo "$json_legit_git" | bash "$HOOKS_DIR/pre-tool-use.sh")
assert_eq "" "$out_legit_git" "PreToolUse allows legitimate git push"

# Test 9b: Shell heuristic deny cases for .ai/deps-approved.txt: >, >>, tee, sed -i, cp, mv, dd of=
for deny_cmd in \
    "echo x > .ai/deps-approved.txt" \
    "echo x >> .ai/deps-approved.txt" \
    "echo x | tee .ai/deps-approved.txt" \
    "echo x | tee -a .ai/deps-approved.txt" \
    "sed -i 's/a/b/' .ai/deps-approved.txt" \
    "cp /tmp/evil .ai/deps-approved.txt" \
    "mv /tmp/evil .ai/deps-approved.txt" \
    "dd if=/dev/zero of=.ai/deps-approved.txt"; do
    json_deny=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$deny_cmd")
    out_deny=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_deny" | bash "$HOOKS_DIR/pre-tool-use.sh")
    assert_contains '"permissionDecision": "deny"' "$out_deny" "PreToolUse blocks shell write: $deny_cmd"
done

# Test 9c: Shell heuristic allow cases: cat, grep, cat AGENTS.md > /dev/null
for allow_cmd in \
    "cat .ai/deps-approved.txt" \
    "grep x .ai/deps-approved.txt" \
    "cat AGENTS.md > /dev/null"; do
    json_allow=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$allow_cmd")
    out_allow=$(unset AI_OS_ALLOW_GOVERNANCE_EDIT; echo "$json_allow" | bash "$HOOKS_DIR/pre-tool-use.sh")
    assert_eq "" "$out_allow" "PreToolUse allows benign shell command: $allow_cmd"
done

# Test 10: pre-tool-use.sh never executes tool input (injection defense)
MARKER_FILE="$TMP_DIR/injected_execution.txt"
json_injected="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"test.txt; touch $MARKER_FILE\",\"content\":\"malicious\"}}"
echo "$json_injected" | bash "$HOOKS_DIR/pre-tool-use.sh" >/dev/null 2>&1
if [ -f "$MARKER_FILE" ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  [FAIL] PreToolUse executed content from tool input!"
else
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  [PASS] PreToolUse did not execute content from tool input"
fi
TEST_COUNT=$((TEST_COUNT + 1))

echo "Results: $PASS_COUNT/$TEST_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ] || exit 1
