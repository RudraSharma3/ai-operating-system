#!/usr/bin/env bash
# Deterministic Stub Agent for Eval Harness Verification
# Usage: stub_agent.sh --mode apply|noop <prompt-file>

set -euo pipefail

MODE="apply"
PROMPT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        *)
            PROMPT_FILE="$1"
            shift
            ;;
    esac
done

if [ "$MODE" = "noop" ]; then
    echo "StubAgent: No-op stub invoked on $PROMPT_FILE. Doing nothing."
    exit 0
fi

if [ -z "$PROMPT_FILE" ] || [ ! -f "$PROMPT_FILE" ]; then
    echo "StubAgent Error: Prompt file not found: '$PROMPT_FILE'" >&2
    exit 1
fi

TASK_DIR="$(cd "$(dirname "$PROMPT_FILE")" && pwd)"
REF_SCRIPT="$TASK_DIR/reference_solution.sh"

if [ -f "$REF_SCRIPT" ]; then
    echo "StubAgent: Applying reference solution from $REF_SCRIPT into $(pwd)..."
    bash "$REF_SCRIPT" .
    exit 0
else
    echo "StubAgent Error: Reference solution not found at $REF_SCRIPT" >&2
    exit 1
fi
