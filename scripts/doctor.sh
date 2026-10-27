#!/usr/bin/env bash
# AI Operating System Project Health & Integrity Doctor (macOS/Linux)
# Comprehensive 14-point verification engine with CI and JSON support.

set -o pipefail

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
    record_check 6 "Git hook is active in core.hooksPath" "FAIL" "core.hooksPath is not configured in git"
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
    tools=$(grep -E '^\- \*\*`[a-zA-Z0-9_-]+`\*\*' "$PLAYBOOK_FILE" | sed -E 's/^- \*\*`([a-zA-Z0-9_-]+)`\*\*.*$/\1/' || true)
    for tool in $tools; do
        if ! grep -q "\"$tool\":" "$MCP_JSON"; then
            MCP_OK=false
            MCP_ERROR="Tool '$tool' declared in playbook is missing from mcp.json"
            break
        fi
    done
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
    if [ -n "$claimed_doc" ] && [ "$claimed_doc" -ne 21 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="README claims $claimed_doc-point doctor, expected 21"
    fi
fi

if [ -f "$UG_PATH" ]; then
    ug_claimed_doc=$(grep -oE '[0-9]+-point diagnostic' "$UG_PATH" | head -n1 | grep -oE '[0-9]+' || true)
    if [ -n "$ug_claimed_doc" ] && [ "$ug_claimed_doc" -ne 21 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="User Guide claims $ug_claimed_doc-point doctor, expected 21"
    fi
    ug_claimed_chk=$(grep -oE 'tests[[:space:]]+[0-9]+[[:space:]]+key integrity checks' "$UG_PATH" | grep -oE '[0-9]+' || true)
    if [ -n "$ug_claimed_chk" ] && [ "$ug_claimed_chk" -ne 21 ]; then
        DOC_COUNTS_OK=false
        DOC_ERR="User Guide claims $ug_claimed_chk integrity checks, expected 21"
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
    exit 1
fi
exit 0
