#!/usr/bin/env bash
# AI Operating System Project Health & Integrity Doctor (macOS/Linux)
# Comprehensive 14-point verification engine with CI and JSON support.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

CI_MODE=false
JSON_MODE=false
PROJECT_PATH="."

for arg in "$@"; do
    case "$arg" in
        --ci|-Ci) CI_MODE=true ;;
        --json|-Json) JSON_MODE=true ;;
        -*) ;;
        *) PROJECT_PATH="$arg" ;;
    esac
done

cd "$PROJECT_PATH" || exit 1
PROJECT_PATH="$(pwd)"

PASSED=0
WARNINGS=0
FAILURES=0
CHECKS_JSON=()

record_check() {
    local id="$1"
    local name="$2"
    local status="$3" # PASS, WARN, FAIL
    local details="$4"
    
    if [ "$status" = "PASS" ]; then
        PASSED=$((PASSED + 1))
        [ "$JSON_MODE" = false ] && echo " [PASS] $name"
    elif [ "$status" = "WARN" ]; then
        WARNINGS=$((WARNINGS + 1))
        [ "$JSON_MODE" = false ] && echo " [WARN] $name - $details"
    else
        FAILURES=$((FAILURES + 1))
        [ "$JSON_MODE" = false ] && echo " [FAIL] $name - $details"
    fi
    
    local safe_details
    safe_details=$(echo "$details" | tr '"' "'")
    CHECKS_JSON+=("{\"id\":$id,\"name\":\"$name\",\"status\":\"$status\",\"details\":\"$safe_details\"}")
}

if [ "$JSON_MODE" = false ]; then
    echo "===================================================="
    echo " 🩺 Running AI-OS Project Health Doctor"
    echo " Target: $PROJECT_PATH"
    echo "===================================================="
fi

# 1. Canonical AGENTS.md
if [ -f "$PROJECT_PATH/AGENTS.md" ]; then
    record_check 1 "Canonical AGENTS.md exists" "PASS" ""
else
    record_check 1 "Canonical AGENTS.md exists" "FAIL" "Missing AGENTS.md at project root"
fi

# 2. Provider adapters point to AGENTS.md
ADAPTERS_OK=true
ADAPTER_ERR=""
for ad in "CLAUDE.md" "GEMINI.md" "CODEX.md" ".cursor/rules/agents.mdc" ".github/copilot-instructions.md"; do
    if [ ! -f "$PROJECT_PATH/$ad" ]; then
        ADAPTERS_OK=false
        ADAPTER_ERR="Missing $ad adapter"
        break
    elif ! grep -q "AGENTS.md" "$PROJECT_PATH/$ad" 2>/dev/null; then
        ADAPTERS_OK=false
        ADAPTER_ERR="$ad does not point to AGENTS.md"
        break
    fi
done
if [ "$ADAPTERS_OK" = true ]; then
    record_check 2 "Provider adapters point to AGENTS.md" "PASS" ""
else
    record_check 2 "Provider adapters point to AGENTS.md" "FAIL" "$ADAPTER_ERR"
fi

# 3. Core architecture documentation exists
DOCS_OK=true
DOCS_ERR=""
for doc in "architecture.md" "conventions.md" "task-state.md" "graph.md"; do
    if [ ! -f "$PROJECT_PATH/docs/$doc" ]; then
        DOCS_OK=false
        DOCS_ERR="Missing docs/$doc"
        break
    fi
done
if [ "$DOCS_OK" = true ]; then
    record_check 3 "Core architecture documentation exists" "PASS" ""
else
    record_check 3 "Core architecture documentation exists" "FAIL" "$DOCS_ERR"
fi

# 4. Learning engine structure exists
if [ -d "$PROJECT_PATH/.ai" ] && [ -f "$PROJECT_PATH/.ai/mistakes-candidates.md" ] && [ -f "$PROJECT_PATH/docs/lessons.md" ]; then
    record_check 4 "Learning engine structure exists" "PASS" ""
else
    record_check 4 "Learning engine structure exists" "FAIL" "Missing .ai/ directory, mistakes-candidates.md, or docs/lessons.md"
fi

# 5. Pre-commit hook installed and executable
HOOK_FILE="$PROJECT_PATH/.githooks/pre-commit"
if [ -f "$HOOK_FILE" ]; then
    if [ -x "$HOOK_FILE" ] || [ "$(git ls-files --stage .githooks/pre-commit 2>/dev/null | awk '{print $1}')" = "100755" ]; then
        record_check 5 "Pre-commit secret guard is installed and executable" "PASS" ""
    else
        record_check 5 "Pre-commit secret guard is installed and executable" "FAIL" ".githooks/pre-commit is missing executable permissions (+x)"
    fi
else
    record_check 5 "Pre-commit secret guard is installed and executable" "FAIL" "Missing .githooks/pre-commit"
fi

# 6. Active git hook configuration
HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || true)
if [ -n "$HOOKS_PATH" ]; then
    record_check 6 "Git hook is active in core.hooksPath" "PASS" ""
else
    record_check 6 "Git hook is active in core.hooksPath" "FAIL" "core.hooksPath is not configured in git (run 'bash scripts/bootstrap.sh' or 'powershell scripts/bootstrap.ps1' to initialize)"
fi

# 7. Secret scan of tracked files
PATTERNS_FILE="$PROJECT_PATH/.ai/secret-patterns.txt"
LEAKS_FOUND=0
if [ -f "$PATTERNS_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        preg="${line#*|}"
        if git grep -E -q -e "$preg" -- ':!.ai/secret-patterns.txt' ':!templates/project/.ai/secret-patterns.txt' ':!templates/project/.githooks/pre-commit' ':!.githooks/pre-commit' 2>/dev/null; then
            LEAKS_FOUND=$((LEAKS_FOUND + 1))
        fi
    done < "$PATTERNS_FILE"
fi

if [ "$LEAKS_FOUND" -eq 0 ]; then
    record_check 7 "Zero secrets detected in tracked files" "PASS" ""
else
    record_check 7 "Zero secrets detected in tracked files" "FAIL" "Detected $LEAKS_FOUND file(s) containing secret signatures"
fi

# 8. No .env files tracked by git
TRACKED_ENV=$(git ls-files 2>/dev/null | grep -E '(^|/)\.env($|\..*)' | grep -v -E '\.(example|sample|template|dist)$' || true)
if [ -z "$TRACKED_ENV" ]; then
    record_check 8 "No environment (.env) files tracked by git" "PASS" ""
else
    record_check 8 "No environment (.env) files tracked by git" "FAIL" "Sensitive env file(s) tracked in git index: $TRACKED_ENV"
fi

# 9. Referenced playbooks and prompts exist
PLAYBOOKS_OK=true
if [ -d "$PROJECT_PATH/playbooks" ]; then
    [ -f "$PROJECT_PATH/playbooks/codebase-analysis.md" ] && [ -f "$PROJECT_PATH/playbooks/prompt-refinement.md" ] || PLAYBOOKS_OK=false
elif [ -d "$PROJECT_PATH/.ai-os/playbooks" ]; then
    [ -f "$PROJECT_PATH/.ai-os/playbooks/codebase-analysis.md" ] && [ -f "$PROJECT_PATH/.ai-os/playbooks/prompt-refinement.md" ] || PLAYBOOKS_OK=false
else
    PLAYBOOKS_OK=false
fi
if [ "$PLAYBOOKS_OK" = true ]; then
    record_check 9 "Referenced playbooks and prompts paths exist" "PASS" ""
else
    record_check 9 "Referenced playbooks and prompts paths exist" "FAIL" "Referenced playbooks directory or files missing"
fi

# 10. Unique learned rule IDs in AGENTS.md (no collisions)
RULES_OK=true
RULE_ERROR=""
if [ -f "$PROJECT_PATH/AGENTS.md" ]; then
    IN_LEARNED=false
    SEEN_RULES=" "
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^##.*Learned[[:space:]]+Rules ]]; then
            IN_LEARNED=true
            continue
        fi
        if [ "$IN_LEARNED" = true ]; then
            if [[ "$line" =~ ^([a-zA-Z0-9_-]+)\.[[:space:]]*\[[A-Z]+\] ]]; then
                rid="${BASH_REMATCH[1]}"
                if [[ "$SEEN_RULES" == *" $rid "* ]]; then
                    RULES_OK=false
                    RULE_ERROR="Duplicate rule ID '$rid' detected"
                    break
                fi
                SEEN_RULES="${SEEN_RULES}${rid} "
            fi
        fi
    done < "$PROJECT_PATH/AGENTS.md"
fi
if [ "$RULES_OK" = true ]; then
    record_check 10 "Learned rule IDs are unique" "PASS" ""
else
    record_check 10 "Learned rule IDs are unique" "FAIL" "$RULE_ERROR"
fi

# 11. Active task state is maintained
if [ -s "$PROJECT_PATH/docs/task-state.md" ]; then
    record_check 11 "Active task state tracker is non-empty" "PASS" ""
else
    record_check 11 "Active task state tracker is non-empty" "FAIL" "docs/task-state.md is missing or empty"
fi

# 12. AGENTS.md size under budget
AGENTS_SIZE=$(wc -c < "$PROJECT_PATH/AGENTS.md" 2>/dev/null || echo 0)
if [ "$AGENTS_SIZE" -lt 8192 ]; then
    record_check 12 "AGENTS.md size within token budget (<8KB)" "PASS" ""
else
    record_check 12 "AGENTS.md size within token budget (<8KB)" "WARN" "AGENTS.md is ${AGENTS_SIZE} bytes (exceeds recommended budget)"
fi

# 13. Line ending attributes (.gitattributes)
if [ -f "$PROJECT_PATH/.gitattributes" ] && grep -q "eol=lf" "$PROJECT_PATH/.gitattributes" 2>/dev/null; then
    record_check 13 "Line ending hygiene enforced (.gitattributes)" "PASS" ""
else
    record_check 13 "Line ending hygiene enforced (.gitattributes)" "FAIL" "Missing .gitattributes enforcing LF line endings"
fi

# 14. Pattern registry and allowlist integrity
if [ -f "$PROJECT_PATH/.ai/secret-patterns.txt" ] && [ -f "$PROJECT_PATH/.ai/secret-allowlist.txt" ]; then
    record_check 14 "Secret pattern registry and allowlist exist" "PASS" ""
else
    record_check 14 "Secret pattern registry and allowlist exist" "FAIL" "Missing .ai/secret-patterns.txt or .ai/secret-allowlist.txt"
fi

# 15. Worker tools in multi-agent playbook match mcp.json
MCP_OK=true
MCP_ERROR=""
PLAYBOOK_FILE=""
if [ -f "$PROJECT_PATH/playbooks/multi-agent-orchestration.md" ]; then
    PLAYBOOK_FILE="$PROJECT_PATH/playbooks/multi-agent-orchestration.md"
elif [ -f "$PROJECT_PATH/.ai-os/playbooks/multi-agent-orchestration.md" ]; then
    PLAYBOOK_FILE="$PROJECT_PATH/.ai-os/playbooks/multi-agent-orchestration.md"
fi

MCP_JSON="$PROJECT_PATH/mcp.json"
if [ -n "$PLAYBOOK_FILE" ] && [ -f "$MCP_JSON" ]; then
    # shellcheck disable=SC2016 # sed backreference
    tools=$(grep -E '^\- \*\*`[a-zA-Z0-9_-]+`\*\*' "$PLAYBOOK_FILE" | sed -E 's/^- \*\*`([a-zA-Z0-9_-]+)`\*\*.*$/\1/' || true)
    for tool in $tools; do
        if ! grep -q "\"$tool\":" "$MCP_JSON"; then
            MCP_OK=false
            MCP_ERROR="Tool '$tool' declared in playbook is missing from mcp.json"
            break
        fi
    done

    if [ "$MCP_OK" = true ]; then
        PY_CMD="python3"
        command -v python3 >/dev/null 2>&1 || PY_CMD="python"
        PIN_CHECK=$(cat "$MCP_JSON" | $PY_CMD -c "
import json, sys
try:
    data = json.load(sys.stdin)
    servers = data.get('mcpServers', {})
    if not servers:
        print('No mcpServers defined in mcp.json')
        sys.exit(1)
    for name, srv in servers.items():
        args = srv.get('args', [])
        pinned = False
        for a in args:
            if '@' in a:
                parts = a[1:].split('@', 1) if a.startswith('@') else a.split('@', 1)
                if len(parts) == 2:
                    ver = parts[1]
                    if any(ver.startswith(op) for op in ('^', '~', '>', '<', '*', '=')) or ver == 'latest':
                        print(f'Server \"{name}\" in mcp.json has range version specification \"{ver}\" (exact pins required)')
                        sys.exit(1)
                    if any(c.isdigit() for c in ver):
                        pinned = True
            elif '==' in a:
                parts = a.split('==', 1)
                if len(parts) == 2:
                    ver = parts[1]
                    if any(ver.startswith(op) for op in ('^', '~', '>', '<', '*', '=')) or ver == 'latest':
                        print(f'Server \"{name}\" in mcp.json has range version specification \"{ver}\" (exact pins required)')
                        sys.exit(1)
                    if any(c.isdigit() for c in ver):
                        pinned = True
        if not pinned:
            print(f'Server \"{name}\" in mcp.json has unpinned version specification')
            sys.exit(1)
    sys.exit(0)
except Exception as e:
    print(f'mcp.json validation error: {e}')
    sys.exit(1)
" 2>&1) || PIN_STATUS=$?
        if [ "${PIN_STATUS:-0}" -ne 0 ]; then
            MCP_OK=false
            MCP_ERROR="$PIN_CHECK"
        fi
    fi
fi

if [ "$MCP_OK" = true ]; then
    record_check 15 "Playbook MCP worker tools exist in mcp.json" "PASS" ""
else
    record_check 15 "Playbook MCP worker tools exist in mcp.json" "FAIL" "$MCP_ERROR"
fi

# 16. Pending *.ai-os-update conflict files
CONFLICT_FILES=$(find "$PROJECT_PATH" -name "*.ai-os-update" 2>/dev/null || true)
if [ -n "$CONFLICT_FILES" ]; then
    CONFLICT_COUNT=$(echo "$CONFLICT_FILES" | grep -c . || true)
    record_check 16 "Side-by-side upgrade conflict files" "WARN" "$CONFLICT_COUNT pending *.ai-os-update file(s) found. Review preserved differences."
else
    record_check 16 "Side-by-side upgrade conflict files" "PASS" ""
fi

# 17. PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)
PS1_OK=true
PS1_ERR=""
while IFS= read -r psfile; do
    [ -z "$psfile" ] && continue
    if ! python3 -c '
import sys
data = open(sys.argv[1], "rb").read()
if data.startswith(b"\xef\xbb\xbf") or all(b < 128 for b in data):
    sys.exit(0)
sys.exit(1)
' "$psfile" 2>/dev/null; then
        PS1_OK=false
        PS1_ERR="Non-ASCII without UTF-8 BOM: $(basename "$psfile")"
        break
    fi
done < <(find "$PROJECT_PATH" -name "*.ps1" 2>/dev/null || true)

if [ "$PS1_OK" = true ]; then
    record_check 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "PASS" ""
else
    record_check 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "FAIL" "$PS1_ERR"
fi

# 18. No hardcoded local user paths in tracked files
LOCAL_HITS=$(git -C "$PROJECT_PATH" grep -iE "C:[/\\]Users" -- ":!scripts/doctor.*" 2>/dev/null || true)
if [ -n "$LOCAL_HITS" ]; then
    record_check 18 "No hardcoded local user paths in tracked files" "FAIL" "Found hardcoded local user path: $LOCAL_HITS"
else
    record_check 18 "No hardcoded local user paths in tracked files" "PASS" ""
fi

# 19. Documentation counts synchronicity
DOC_COUNTS_OK=true
DOC_ERR=""
README_PATH="$PROJECT_PATH/README.md"
UG_PATH="$PROJECT_PATH/docs/AI-OS-USER-GUIDE.md"
PB_DIR="$PROJECT_PATH/playbooks"
[ ! -d "$PB_DIR" ] && PB_DIR="$PROJECT_PATH/.ai-os/playbooks"

if [ -f "$README_PATH" ]; then
    actual_pb=0
    [ -d "$PB_DIR" ] && actual_pb=$(find "$PB_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | grep -c . || true)
    claimed_pb=$(grep -E 'playbooks/[[:space:]]*\([0-9]+[[:space:]]+Playbooks\)' "$README_PATH" | sed -E 's/.*playbooks\/[[:space:]]*\(([0-9]+)[[:space:]]+Playbooks\).*/\1/' || true)
    if [ -n "$claimed_pb" ] && [ "$claimed_pb" -ne "$actual_pb" ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="README claims $claimed_pb playbooks, but $actual_pb exist"
    fi
    claimed_doc=$(grep -oE '[0-9]+-point diagnostic doctor' "$README_PATH" | grep -oE '[0-9]+' || true)
    if [ -n "$claimed_doc" ] && [ "$claimed_doc" -ne 27 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="README claims $claimed_doc-point doctor, expected 27"
    fi
fi

if [ -f "$UG_PATH" ]; then
    ug_claimed_doc=$(grep -oE '[0-9]+-point diagnostic' "$UG_PATH" | head -n1 | grep -oE '[0-9]+' || true)
    if [ -n "$ug_claimed_doc" ] && [ "$ug_claimed_doc" -ne 27 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="User Guide claims $ug_claimed_doc-point doctor, expected 27"
    fi
    ug_claimed_chk=$(grep -oE 'tests[[:space:]]+[0-9]+[[:space:]]+key integrity checks' "$UG_PATH" | grep -oE '[0-9]+' || true)
    if [ -n "$ug_claimed_chk" ] && [ "$ug_claimed_chk" -ne 27 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="User Guide claims $ug_claimed_chk integrity checks, expected 27"
    fi
fi

if [ "$DOC_COUNTS_OK" = true ]; then
    record_check 19 "Documentation counts match reality (playbooks, doctor checks)" "PASS" ""
else
    record_check 19 "Documentation counts match reality (playbooks, doctor checks)" "FAIL" "$DOC_ERR"
fi

# 20. Private names deny-list check (.ai/private-names.txt)
PRIV_NAMES_FILE="$PROJECT_PATH/.ai/private-names.txt"
PRIV_MATCHES=0
if [ -f "$PRIV_NAMES_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$trimmed" ] && continue
        case "$trimmed" in \#*) continue ;; esac
        HITS=$(git -C "$PROJECT_PATH" grep -iF "$trimmed" -- ":!.ai/private-names.txt" 2>/dev/null || true)
        if [ -n "$HITS" ]; then
            HIT_COUNT=$(echo "$HITS" | grep -c . || true)
            PRIV_MATCHES=$((PRIV_MATCHES + HIT_COUNT))
        fi
    done < "$PRIV_NAMES_FILE"
fi

if [ "$PRIV_MATCHES" -gt 0 ]; then
    record_check 20 "No private deny-listed names in tracked files" "FAIL" "Found $PRIV_MATCHES match(es) for private deny-listed names in tracked files"
else
    record_check 20 "No private deny-listed names in tracked files" "PASS" ""
fi

# 21. Optional Claude Code hooks installed check
CLAUDE_SETTINGS="$PROJECT_PATH/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    record_check 21 "Optional Claude Code hooks status" "WARN" "Opt-in Claude Code hooks are active (.claude/settings.json)"
else
    record_check 21 "Optional Claude Code hooks status" "PASS" ""
fi

# 22. Headless agent command documentation verification
SOURCES_FILE="$PROJECT_PATH/docs/sources.md"
UNVERIFIED_CMD_ERR=""

DOC_FILES=()
[ -f "$PROJECT_PATH/README.md" ] && DOC_FILES+=("$PROJECT_PATH/README.md")
while IFS= read -r f; do
    [ -n "$f" ] && [ "$f" != "$SOURCES_FILE" ] && DOC_FILES+=("$f")
done < <(find "$PROJECT_PATH/docs" "$PROJECT_PATH/evals" -type f -name "*.md" 2>/dev/null || true)

if [ ${#DOC_FILES[@]} -gt 0 ]; then
    # shellcheck disable=SC2016 # literal backtick matching in markdown regex
    while IFS= read -r match_line; do
        [ -z "$match_line" ] && continue
        df="${match_line%%:*}"
        raw_cmd="${match_line#*:}"
        cmd="${raw_cmd//[\`\"]/}"
        if [ -n "$cmd" ]; then
            if [ ! -f "$SOURCES_FILE" ]; then
                UNVERIFIED_CMD_ERR="docs/sources.md missing; unverified command '$cmd' found in $(basename "$df")"
                break
            fi
            flags=$(echo "$cmd" | grep -oE '\-\-[a-zA-Z0-9_-]+|\-[a-zA-Z0-9]' || true)
            for fl in $flags; do
                if ! grep -F -q -e "$fl" "$SOURCES_FILE"; then
                    UNVERIFIED_CMD_ERR="Unverified flag '$fl' in '$cmd' in $(basename "$df") (not listed in docs/sources.md)"
                    break 2
                fi
            done
            if echo "$cmd" | grep -qE -- '--non-interactive'; then
                UNVERIFIED_CMD_ERR="Unverified command '$cmd' in $(basename "$df") (flag marked invalid/unverified in docs/sources.md)"
                break
            fi
        fi
    done < <(grep -H -oE '`claude [^`]+`|"claude [^"]+"|\bclaude[[:space:]]+-[a-zA-Z0-9_ -]+' "${DOC_FILES[@]}" 2>/dev/null || true)

    if [ -z "$UNVERIFIED_CMD_ERR" ]; then
        while IFS= read -r match_line; do
            [ -z "$match_line" ] && continue
            df="${match_line%%:*}"
            raw_val="${match_line#*:}"
            mode=$(echo "$raw_val" | sed -E 's/.*--permission-mode[[:space:]=]+([a-zA-Z0-9_-]+).*/\1/' || true)
            if [ -n "$mode" ]; then
                if [ ! -f "$SOURCES_FILE" ]; then
                    UNVERIFIED_CMD_ERR="docs/sources.md missing; unverified permission-mode '$mode' found in $(basename "$df")"
                    break
                fi
                if ! grep -E -q "(\`|'|\(|,\s*|\b)$mode(\`|'|\)|,|\b)" "$SOURCES_FILE"; then
                    UNVERIFIED_CMD_ERR="Unverified permission-mode '$mode' in $(basename "$df") (not listed in docs/sources.md)"
                    break
                fi
            fi
        done < <(grep -H -E '\-\-permission-mode[[:space:]=]+[a-zA-Z0-9_-]+' "${DOC_FILES[@]}" 2>/dev/null || true)
    fi
fi

if [ -n "$UNVERIFIED_CMD_ERR" ]; then
    record_check 22 "Headless agent command documentation verification" "WARN" "$UNVERIFIED_CMD_ERR"
else
    record_check 22 "Headless agent command documentation verification" "PASS" ""
fi

# 23. MCP pin maturity and freshness (reads docs/mcp-pins.json offline)
MCP_PINS_FILE="$PROJECT_PATH/docs/mcp-pins.json"
if [ -f "$MCP_PINS_FILE" ]; then
    PY_CMD="python"
    command -v python3 >/dev/null 2>&1 && PY_CMD="python3"
    PIN_RESULT=$($PY_CMD - "$MCP_PINS_FILE" << 'EOF'
import sys, json
from datetime import datetime, timezone
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    now = datetime.now(timezone.utc)
    warns = []
    for item in data:
        pkg = item.get('package', 'unknown')
        ver = item.get('version', '')
        pub_str = item.get('published_at', '')
        chk_str = item.get('checked_at', '')
        if not pub_str or not chk_str:
            continue
        pub_dt = datetime.fromisoformat(pub_str.replace('Z', '+00:00'))
        chk_dt = datetime.fromisoformat(chk_str.replace('Z', '+00:00'))
        age_at_chk = (chk_dt - pub_dt).total_seconds() / 86400.0
        if age_at_chk < 14.0:
            warns.append(f'{pkg}@{ver} was younger than 14 days ({age_at_chk:.1f}d) when recorded')
        rec_age = (now - chk_dt).total_seconds() / 86400.0
        if rec_age > 90.0:
            warns.append(f'Record for {pkg}@{ver} is older than 90 days ({rec_age:.1f}d stale)')
    if warns:
        print('WARN:' + '; '.join(warns))
    else:
        print('PASS')
except Exception as e:
    print('WARN:Error reading mcp-pins.json: ' + str(e))
EOF
)

    if [[ "$PIN_RESULT" == WARN:* ]]; then
        record_check 23 "MCP pin maturity and freshness" "WARN" "${PIN_RESULT#WARN:}"
    else
        record_check 23 "MCP pin maturity and freshness" "PASS" ""
    fi
else
    record_check 23 "MCP pin maturity and freshness" "PASS" ""
fi

# 24. GitHub Actions workflow security (pinned action SHAs and permissions block)
WORKFLOWS_DIR="$PROJECT_PATH/.github/workflows"
WORKFLOW_WARN=""
if [ -d "$WORKFLOWS_DIR" ]; then
    while IFS= read -r wf; do
        [ ! -f "$wf" ] && continue
        wf_name="$(basename "$wf")"
        
        # Check 1: Top-level permissions block
        if ! grep -qE '^permissions:' "$wf"; then
            WORKFLOW_WARN="Workflow '$wf_name' lacks a top-level permissions block"
            break
        fi
        
        # Check 2: All third-party action 'uses:' must be pinned to full 40-hex commit SHA
        while IFS= read -r uses_line; do
            [ -z "$uses_line" ] && continue
            clean_uses=$(echo "$uses_line" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*//' | tr -d '"'"'")
            case "$clean_uses" in
                ./*|docker://*) continue ;;
            esac
            if [[ "$clean_uses" == *"@"* ]]; then
                ref="${clean_uses##*@}"
                if ! [[ "$ref" =~ ^[0-9a-fA-F]{40}$ ]]; then
                    WORKFLOW_WARN="Workflow '$wf_name' uses unpinned action '$clean_uses' (expected 40-character commit SHA)"
                    break 2
                fi
            else
                WORKFLOW_WARN="Workflow '$wf_name' uses unpinned action '$clean_uses' (missing @<commit-sha>)"
                break 2
            fi
        done < <(grep -E '^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*' "$wf" 2>/dev/null || true)
    done < <(find "$WORKFLOWS_DIR" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null || true)
fi

# Check 3: Dependabot 14-day cooldown enforcement (table-driven from docs/dependabot-cooldown-keys.json)
DEPENDABOT_FILE="$PROJECT_PATH/.github/dependabot.yml"
COOLDOWN_TABLE_FILE="$PROJECT_PATH/docs/dependabot-cooldown-keys.json"
[ ! -f "$COOLDOWN_TABLE_FILE" ] && COOLDOWN_TABLE_FILE="$SCRIPT_DIR/../docs/dependabot-cooldown-keys.json"

WORKFLOW_ERR=""
if [ -z "$WORKFLOW_WARN" ] && [ -f "$DEPENDABOT_FILE" ]; then
    PY_CMD="python"
    command -v python3 >/dev/null 2>&1 && PY_CMD="python3"
    
    DEP_VALIDATION=$($PY_CMD - "$DEPENDABOT_FILE" "$COOLDOWN_TABLE_FILE" << 'EOF'
import sys, json, re

dep_file = sys.argv[1]
table_file = sys.argv[2]

ecosystems_table = {}
try:
    with open(table_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    ecosystems_table = data.get('ecosystems', {})
except Exception:
    pass

try:
    with open(dep_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
except Exception as e:
    print(f"WARN:Cannot read dependabot file: {e}")
    sys.exit(0)

current_eco = None
in_cooldown = False
cooldown_indent = 0
has_cooldown = False
has_14day = False
unknown_eco = None
unsupported_key_err = None

for raw_line in lines:
    clean_line = raw_line.split('#')[0].rstrip()
    if not clean_line.strip():
        continue

    m_eco = re.search(r'package-ecosystem:\s*"?([a-zA-Z0-9_-]+)"?', clean_line)
    if m_eco:
        current_eco = m_eco.group(1)
        in_cooldown = False
        continue

    m_cd = re.match(r'^(\s*)cooldown:\s*$', clean_line)
    if m_cd:
        in_cooldown = True
        has_cooldown = True
        cooldown_indent = len(m_cd.group(1))
        continue

    if in_cooldown:
        m_key = re.match(r'^(\s+)([a-zA-Z0-9_-]+):', clean_line)
        if m_key:
            k_indent = len(m_key.group(1))
            ckey = m_key.group(2)
            if k_indent <= cooldown_indent:
                in_cooldown = False
            else:
                if ckey == 'default-days':
                    m_days = re.search(r'default-days:\s*([0-9]+)', clean_line)
                    if m_days and int(m_days.group(1)) >= 14:
                        has_14day = True

                if ecosystems_table:
                    if current_eco not in ecosystems_table:
                        if not unknown_eco:
                            unknown_eco = current_eco
                    else:
                        allowed = ecosystems_table[current_eco]
                        if ckey not in allowed:
                            unsupported_key_err = f"Dependabot configuration '.github/dependabot.yml' uses unsupported cooldown key '{ckey}' for package ecosystem '{current_eco}'"
                            break
        else:
            in_cooldown = False

if unsupported_key_err:
    print("FAIL:" + unsupported_key_err)
elif unknown_eco:
    print(f"WARN:Dependabot configuration '.github/dependabot.yml' uses unknown package ecosystem '{unknown_eco}'")
elif not has_cooldown or not has_14day:
    print("WARN:Dependabot configuration '.github/dependabot.yml' lacks a minimum 14-day cooldown")
else:
    print("PASS")
EOF
)

    if [[ "$DEP_VALIDATION" == FAIL:* ]]; then
        WORKFLOW_ERR="${DEP_VALIDATION#FAIL:}"
    elif [[ "$DEP_VALIDATION" == WARN:* ]]; then
        WORKFLOW_WARN="${DEP_VALIDATION#WARN:}"
    fi
fi

if [ -n "$WORKFLOW_ERR" ]; then
    record_check 24 "GitHub Actions workflow action pinning and permissions" "FAIL" "$WORKFLOW_ERR"
elif [ -n "$WORKFLOW_WARN" ]; then
    record_check 24 "GitHub Actions workflow action pinning and permissions" "WARN" "$WORKFLOW_WARN"
else
    record_check 24 "GitHub Actions workflow action pinning and permissions" "PASS" ""
fi

# 25. Python 3.9+ runtime availability (warn if missing)
PY_AVAIL=false
if command -v python3 >/dev/null 2>&1; then
    PY_AVAIL=true
elif command -v python >/dev/null 2>&1; then
    PY_AVAIL=true
fi

if [ "$PY_AVAIL" = true ]; then
    record_check 25 "Python 3.9+ runtime availability" "PASS" ""
else
    record_check 25 "Python 3.9+ runtime availability" "WARN" "Python 3.9+ not found in PATH; verification layer features will be disabled"
fi

# 26. Dependency approval list and CODEOWNERS coverage
DEPS_FILE="$PROJECT_PATH/.ai/deps-approved.txt"
if [ ! -f "$DEPS_FILE" ]; then
    record_check 26 "Dependency approval list and CODEOWNERS coverage" "FAIL" "Missing required .ai/deps-approved.txt file"
else
    CO_HAS_OWNER=false
    CO_HAS_UNOWNED_PATTERN=false
    for co in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
        if [ -f "$PROJECT_PATH/$co" ]; then
            while IFS= read -r line || [ -n "$line" ]; do
                clean_l=$(echo "$line" | sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                [ -z "$clean_l" ] && continue
                if [[ ! "$clean_l" =~ @[a-zA-Z0-9_\-]+ ]]; then
                    CO_HAS_UNOWNED_PATTERN=true
                fi
            done < "$PROJECT_PATH/$co"

            if grep -E '^\s*\.ai/deps-approved\.txt\s+@[a-zA-Z0-9_\-]+' "$PROJECT_PATH/$co" >/dev/null 2>&1; then
                CO_HAS_OWNER=true
                break
            fi
        fi
    done

    IS_ROOT_REPO=false
    if [ "$PROJECT_PATH" = "$REPO_ROOT" ]; then
        IS_ROOT_REPO=true
    fi

    if [ "$CO_HAS_OWNER" = true ] && [ "$CO_HAS_UNOWNED_PATTERN" = false ]; then
        record_check 26 "Dependency approval list and CODEOWNERS coverage" "PASS" ""
    else
        if [ "$IS_ROOT_REPO" = true ]; then
            if [ "$CO_HAS_UNOWNED_PATTERN" = true ]; then
                record_check 26 "Dependency approval list and CODEOWNERS coverage" "FAIL" "CODEOWNERS contains unowned pattern line without an owner handle"
            else
                record_check 26 "Dependency approval list and CODEOWNERS coverage" "FAIL" ".github/CODEOWNERS must cover .ai/deps-approved.txt with a valid owner handle"
            fi
        else
            if [ "$CO_HAS_UNOWNED_PATTERN" = true ]; then
                record_check 26 "Dependency approval list and CODEOWNERS coverage" "WARN" "CODEOWNERS contains unowned pattern line; add '@your-handle' to each pattern line"
            else
                record_check 26 "Dependency approval list and CODEOWNERS coverage" "WARN" "CODEOWNERS lacks owner coverage for .ai/deps-approved.txt; fix: echo '.ai/deps-approved.txt @your-handle' >> .github/CODEOWNERS"
            fi
        fi
    fi
fi

# 27. Pre-commit verification configuration
VCONF_FILE="$PROJECT_PATH/.ai/verify.conf"
VCONF_ERR=""
if [ ! -f "$VCONF_FILE" ]; then
    VCONF_ERR="Missing .ai/verify.conf configuration file"
else
    while IFS='=' read -r k v || [ -n "$k" ]; do
        k=$(echo "$k" | tr -d '[:space:]')
        v=$(echo "$v" | tr -d '[:space:]')
        [[ "$k" =~ ^# ]] && continue
        [ -z "$k" ] && continue
        case "$k" in
            deps)
                [[ "$v" =~ ^(block|warn|off)$ ]] || VCONF_ERR="Invalid verify.conf setting for deps: '$v'"
                ;;
            imports)
                [[ "$v" =~ ^(block|warn|off)$ ]] || VCONF_ERR="Invalid verify.conf setting for imports: '$v'"
                ;;
            on_missing_python)
                [[ "$v" =~ ^(warn|block)$ ]] || VCONF_ERR="Invalid verify.conf setting for on_missing_python: '$v'"
                ;;
            approvals_changed)
                [[ "$v" =~ ^(warn|block)$ ]] || VCONF_ERR="Invalid verify.conf setting for approvals_changed: '$v'"
                ;;
        esac
    done < "$VCONF_FILE"
fi

if [ -n "$VCONF_ERR" ]; then
    record_check 27 "Pre-commit verification configuration" "FAIL" "$VCONF_ERR"
else
    record_check 27 "Pre-commit verification configuration" "PASS" ""
fi

if [ "$JSON_MODE" = true ]; then
    echo "{"
    echo "  \"passed\": $PASSED,"
    echo "  \"warnings\": $WARNINGS,"
    echo "  \"failures\": $FAILURES,"
    echo "  \"armor\": \"$( [ $FAILURES -eq 0 ] && echo 'ARMED' || echo 'UNARMED' )\","
    echo "  \"checks\": ["
    IFS=,; echo "${CHECKS_JSON[*]}"
    echo "  ]"
    echo "}"
else
    echo ""
    echo "===================================================="
    echo " 📊 Health Summary: $PASSED Passed | $WARNINGS Warnings | $FAILURES Failures"
    if [ "$FAILURES" -eq 0 ]; then
        echo " EXCELLENT! Project health is in pristine operational order."
        echo " ARMOR STATUS: Git Secret Guard [ARMED]"
    else
        echo " ATTENTION: Please address the failed checks above."
        echo " ARMOR STATUS: Git Secret Guard [UNARMED]"
    fi
    echo "===================================================="
fi

if [ "$FAILURES" -gt 0 ]; then
    [ "$CI_MODE" = true ] && exit 1
    exit 1
fi
exit 0
