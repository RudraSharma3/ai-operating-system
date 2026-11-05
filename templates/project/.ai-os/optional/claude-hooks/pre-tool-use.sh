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

# Check 1: Direct governance file edits (Write / Edit / NotebookEdit)
write_tools = {"Write", "Edit", "NotebookEdit"}
if tool_name in write_tools:
    target_path = tool_input.get("file_path") or tool_input.get("notebook_path") or tool_input.get("path") or ""
    # Normalize path
    target_path = str(target_path).replace("\\", "/").strip()
    
    # Check if target is a governance path or dependency approvals file
    is_governance = bool(re.search(r"(^|/)(AGENTS\.md|\.ai/rules/.*|\.githooks/.*|scripts/.*|\.ai/deps-approved\.txt)$", target_path))
    if is_governance:
        allow_override = os.environ.get("AI_OS_ALLOW_GOVERNANCE_EDIT") == "1"
        if not allow_override:
            decision = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": "Direct edits to AI-OS governance files (AGENTS.md, .ai/rules/, .githooks/, scripts/, .ai/deps-approved.txt) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
                }
            }
            print(json.dumps(decision, indent=2))
            sys.exit(0)

# Check 2: Subversive Git Commands in Bash / PowerShell
shell_tools = {"Bash", "PowerShell"}
if tool_name in shell_tools:
    cmd = tool_input.get("command") or ""
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

    # Check 3: Best-effort heuristic deny for shell writes / appends to .ai/deps-approved.txt only
    # Intercepts: >, >>, tee (with or without -a), sed -i, cp, mv, dd of=
    # A target may carry a path prefix (./, /abs/path/) and quotes. No single quotes here:
    # this Python source is wrapped in a single-quoted bash string.
    target = r"[^\s;&|]*\.ai/deps-approved\.txt"
    shell_write_patterns = [
        r">>?\s*" + target,
        r"\btee(\s+-[a-zA-Z0-9]+)*\s+" + target,
        r"\bsed\s+-[a-zA-Z0-9]*i.*\.ai/deps-approved\.txt",
        r"\bcp\s+.*\s" + target + r"\S*\s*($|[;&|])",
        r"\bmv\s+.*\.ai/deps-approved\.txt",
        r"\bdd\s+.*of=" + target
    ]
    shell_write_deps = any(re.search(p, cmd) for p in shell_write_patterns)
    if shell_write_deps:
        allow_override = os.environ.get("AI_OS_ALLOW_GOVERNANCE_EDIT") == "1"
        if not allow_override:
            reason = "Shell write redirection to .ai/deps-approved.txt detected (heuristic). Direct modification blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
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
    # Fallback when Python is unavailable: bash builtins only (no cat/grep/sed on PATH required).
    INPUT_JSON=$(</dev/stdin)
    deny() {
        printf '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "%s"
  }
}
' "$1"
        exit 0
    }
    TOOL_RE='"tool_name"[[:space:]]*:[[:space:]]*"([A-Za-z]+)"'
    TOOL=""
    [[ "$INPUT_JSON" =~ $TOOL_RE ]] && TOOL="${BASH_REMATCH[1]}"
    GOV_PATH_RE='"(file_path|notebook_path|path)"[[:space:]]*:[[:space:]]*"([^"]*/)?(AGENTS\.md|\.ai/rules/[^"]*|\.githooks/[^"]*|scripts/[^"]*|\.ai/deps-approved\.txt)"'
    if [[ "$TOOL" =~ ^(Write|Edit|NotebookEdit)$ ]] && [[ "$INPUT_JSON" =~ $GOV_PATH_RE ]]; then
        [ "${AI_OS_ALLOW_GOVERNANCE_EDIT:-0}" = "1" ] || deny "Direct edits to AI-OS governance files (AGENTS.md, .ai/rules/, .githooks/, scripts/, .ai/deps-approved.txt) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
    fi
    if [[ "$TOOL" =~ ^(Bash|PowerShell)$ ]]; then
        NO_VERIFY_RE='git[[:space:]]+commit.*--no-verify'
        FORCE_RE='git[[:space:]]+push.*(--force|[[:space:]]-f([[:space:]"]|$))'
        if [[ "$INPUT_JSON" =~ $NO_VERIFY_RE ]] || [[ "$INPUT_JSON" =~ $FORCE_RE ]]; then
            deny "Subversive git commands (--no-verify, --force) are blocked by AI-OS governance."
        fi
        T='[^[:space:];&|]*\.ai/deps-approved\.txt'
        WRITE_RE=">>?[[:space:]]*['\\\"]*${T}|tee([[:space:]]+-[[:alnum:]]+)*[[:space:]]+['\\\"]*${T}|sed[[:space:]]+-[[:alnum:]]*i.*\.ai/deps-approved\.txt|cp[[:space:]].*[[:space:]]['\\\"]*${T}['\\\"]*[[:space:]]*(\"|$|[;&|])|mv[[:space:]].*\.ai/deps-approved\.txt|dd[[:space:]].*of=['\\\"]*${T}"
        if [[ "$INPUT_JSON" =~ $WRITE_RE ]]; then
            [ "${AI_OS_ALLOW_GOVERNANCE_EDIT:-0}" = "1" ] || deny "Shell write redirection to .ai/deps-approved.txt detected (heuristic). Direct modification blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
        fi
    fi
fi

exit 0
