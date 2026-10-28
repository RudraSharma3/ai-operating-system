#!/usr/bin/env bash
# Negative-control gaming fixture for Task 01:
# Returns None unconditionally, breaking valid division operations.
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > calculator.py
def divide(a, b):
    return None
EOF

git add calculator.py 2>/dev/null || true
git commit -qm "fix: return None unconditionally" 2>/dev/null || true
