#!/usr/bin/env bash
# AI-OS Claude Code Hook: PreCompact
# Writes a durable state checkpoint into docs/task-state.md prior to context compaction.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TASK_STATE="$PROJECT_DIR/docs/task-state.md"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if [ -f "$TASK_STATE" ]; then
    cat << EOF >> "$TASK_STATE"

### Compaction Checkpoint: $TIMESTAMP
- Context window compaction initiated by Claude Code.
- Active task-state preserved across compaction boundary.
EOF
    echo "💾 [AI-OS Hook] Pre-compaction checkpoint recorded into docs/task-state.md ($TIMESTAMP)"
else
    mkdir -p "$(dirname "$TASK_STATE")"
    cat << EOF > "$TASK_STATE"
# Active Task State

### Compaction Checkpoint: $TIMESTAMP
- Context window compaction initiated by Claude Code.
- Task-state initialized before compaction.
EOF
    echo "💾 [AI-OS Hook] Pre-compaction checkpoint initialized in docs/task-state.md"
fi

exit 0
