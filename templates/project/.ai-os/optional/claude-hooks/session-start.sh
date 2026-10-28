#!/usr/bin/env bash
# AI-OS Claude Code Hook: SessionStart
# Displays active project task-state summary and token budget status on session start/resume.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TASK_STATE="$PROJECT_DIR/docs/task-state.md"
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"
BUDGET=8192

echo "===================================================="
echo " 🤖 AI-OS Claude Code Session Active"
echo " Project Root: $PROJECT_DIR"
echo "===================================================="

# 1. Budget Status
if [ -f "$AGENTS_FILE" ]; then
    size=$(wc -c < "$AGENTS_FILE" | tr -d ' ')
    if [ "$size" -le "$BUDGET" ]; then
        echo " 📊 Token Budget: AGENTS.md is $size / $BUDGET bytes [PASS]"
    else
        echo " ⚠️ Token Budget: AGENTS.md is $size / $BUDGET bytes [EXCEEDED]"
    fi
else
    echo " ℹ️ Token Budget: AGENTS.md not found in project root"
fi

# 2. Task State Summary
if [ -f "$TASK_STATE" ]; then
    echo " 📋 Task State Summary (docs/task-state.md):"
    head -n 25 "$TASK_STATE" | sed 's/^/    /'
else
    echo " ℹ️ Task State: docs/task-state.md not initialized"
fi

echo "===================================================="
exit 0
