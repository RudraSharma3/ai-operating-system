#!/usr/bin/env bash
# AI Operating System Verifier CLI Wrapper (Bash)
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${AI_OS_PYTHON_BIN:-python3}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    if command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    else
        echo "[AI-OS Verifier] ⚠️  Python (3.9+) is required but was not found in PATH." >&2
        echo "Please install Python or configure AI_OS_PYTHON_BIN." >&2
        exit 1
    fi
fi

exec "$PYTHON_BIN" "$SCRIPT_DIR/ai_os_verify.py" "$@"

