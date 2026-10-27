#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

"$PYTHON_BIN" -m unittest test_calculator.py
