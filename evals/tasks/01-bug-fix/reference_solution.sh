#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > calculator.py
def divide(a, b):
    if b == 0:
        return None
    return a / b
EOF

git add calculator.py
git commit -qm "fix: handle zero division safely by returning None" || true
