#!/usr/bin/env bash
# AI-OS Claude Code Hook: PreToolUse
# Blocks unauthorized direct edits to governance files and subversive git commands.
# Input: JSON context delivered via stdin. Never executes tool input.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, os, json, re

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {})
if not isinstance(tool_input, dict):
    tool_input = {}

# Check 1: Direct governance file edits (Write / Edit)
write_tools = {"Write", "Edit", "NotebookEdit", "FileEdit", "WriteToFile", "ReplaceFileContent", "multi_replace_file_content", "replace_file_content", "write_to_file"}
if tool_name in write_tools:
    target_path = tool_input.get("file_path") or tool_input.get("path") or tool_input.get("target_file") or tool_input.get("TargetFile") or ""
    # Normalize path
    target_path = str(target_path).replace("\\", "/").strip()
    
    # Check if target is a governance path or evidence record
    is_governance = bool(re.search(r"(^|/)(AGENTS\.md|\.ai/rules/.*|\.githooks/.*|scripts/.*|\.ai/evidence/.*)$", target_path))
    if is_governance:
        allow_override = os.environ.get("AI_OS_ALLOW_GOVERNANCE_EDIT") == "1"
        if not allow_override:
            decision = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": "Direct edits to AI-OS governance and evidence files (AGENTS.md, .ai/rules/, .githooks/, scripts/, .ai/evidence/) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
                }
            }
            print(json.dumps(decision, indent=2))
            sys.exit(0)

# Check 2: Subversive Git Commands in Bash / PowerShell
shell_tools = {"Bash", "PowerShell", "Terminal", "ExecuteCommand", "run_command"}
if tool_name in shell_tools:
    cmd = tool_input.get("command") or tool_input.get("CommandLine") or ""
    cmd = str(cmd)
    
    # Check for git commit --no-verify or git push --force / -f
    no_verify = bool(re.search(r"\bgit\s+commit\b.*--no-verify", cmd))
    force_push = bool(re.search(r"\bgit\s+push\b.*(--force|-f\b|--force-with-lease)", cmd))
    
    if no_verify or force_push:
        reason = "Subversive git command detected: " + ("--no-verify" if no_verify else "--force") + " is blocked by AI-OS governance."
        decision = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason
            }
        }
        print(json.dumps(decision, indent=2))
        sys.exit(0)

sys.exit(0)
'
else
    # Fallback POSIX Shell when Python is unavailable
    INPUT_JSON=$(cat)
    if [[ "$INPUT_JSON" =~ (AGENTS\.md|\.ai/rules/|\.githooks/|scripts/) ]]; then
        if [ "${AI_OS_ALLOW_GOVERNANCE_EDIT:-0}" != "1" ]; then
            cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Direct edits to AI-OS governance files (AGENTS.md, .ai/rules/, .githooks/, scripts/) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
  }
}
EOF
            exit 0
        fi
    fi
    if [[ "$INPUT_JSON" =~ git[[:space:]]+commit.*--no-verify ]] || [[ "$INPUT_JSON" =~ git[[:space:]]+push.*--force ]]; then
        cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Subversive git commands (--no-verify, --force) are blocked by AI-OS governance."
  }
}
EOF
        exit 0
    fi
fi

exit 0
