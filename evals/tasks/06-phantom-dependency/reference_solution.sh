#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > query_parser.py
from urllib.parse import parse_qs

def parse_query(query_str):
    return parse_qs(query_str, keep_blank_values=True)
EOF

git add query_parser.py
git commit -qm "feat: implement query parsing with stdlib urllib.parse" || true

