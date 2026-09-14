#!/usr/bin/env bash
# AI Operating System: Project Health & Integrity Doctor (macOS/Linux)

PROJECT_PATH="${1:-.}"

echo "===================================================="
echo " 🩺 Running AI-OS Project Health Doctor"
echo " Target: $PROJECT_PATH"
echo "===================================================="

PASSED=0
WARNINGS=0
FAILURES=0

check_item() {
    local name="$1"
    local condition="$2"
    local failure_msg="$3"
    local is_warn="${4:-false}"

    if [ "$condition" = "true" ]; then
        echo " [PASS] $name"
        PASSED=$((PASSED + 1))
    else
        if [ "$is_warn" = "true" ]; then
            echo " [WARN] $name - $failure_msg"
            WARNINGS=$((WARNINGS + 1))
        else
            echo " [FAIL] $name - $failure_msg"
            FAILURES=$((FAILURES + 1))
        fi
    fi
}

# 1. Core Instruction Files
echo ""
echo "1. Core Instruction Files:"
[ -f "$PROJECT_PATH/AGENTS.md" ] && C="true" || C="false"
check_item "Canonical AGENTS.md exists" "$C" "Missing AGENTS.md in project root!"
[ -f "$PROJECT_PATH/CLAUDE.md" ] && C="true" || C="false"
check_item "CLAUDE.md adapter exists" "$C" "Missing CLAUDE.md adapter."
[ -f "$PROJECT_PATH/GEMINI.md" ] && C="true" || C="false"
check_item "GEMINI.md adapter exists" "$C" "Missing GEMINI.md adapter."
[ -f "$PROJECT_PATH/CODEX.md" ] && C="true" || C="false"
check_item "CODEX.md adapter exists" "$C" "Missing CODEX.md adapter."

# 2. Documentation Suite
echo ""
echo "2. Documentation Integrity:"
[ -d "$PROJECT_PATH/docs" ] && C="true" || C="false"
check_item "docs/ directory exists" "$C" "Missing docs/ directory."
[ -f "$PROJECT_PATH/docs/architecture.md" ] && C="true" || C="false"
check_item "docs/architecture.md exists" "$C" "Missing architecture document."
[ -f "$PROJECT_PATH/docs/conventions.md" ] && C="true" || C="false"
check_item "docs/conventions.md exists" "$C" "Missing conventions guide."
[ -f "$PROJECT_PATH/docs/task-state.md" ] && C="true" || C="false"
check_item "docs/task-state.md exists" "$C" "Missing active task state tracker."
[ -f "$PROJECT_PATH/docs/graph.md" ] && C="true" || C="false"
check_item "docs/graph.md exists" "$C" "Missing dependency graph."

# 3. Learning Engine
echo ""
echo "3. Learning Engine:"
[ -d "$PROJECT_PATH/.ai" ] && C="true" || C="false"
check_item ".ai/ directory exists" "$C" "Missing .ai directory."
[ -f "$PROJECT_PATH/.ai/mistakes-candidates.md" ] && C="true" || C="false"
check_item ".ai/mistakes-candidates.md exists" "$C" "Missing candidate lessons log."
[ -f "$PROJECT_PATH/docs/lessons.md" ] && C="true" || C="false"
check_item "docs/lessons.md exists" "$C" "Missing verified lessons log."

echo ""
echo "===================================================="
echo " 📊 Health Summary: $PASSED Passed | $WARNINGS Warnings | $FAILURES Failures"
echo "===================================================="
