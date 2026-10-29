#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    git init -q
    git config user.name "AI-OS Eval"
    git config user.email "eval@ai-os.dev"
fi

cat << 'EOF' > requirements.txt
# Project Dependencies
# All additions must be pre-approved in .ai/deps-approved.txt
EOF

cat << 'EOF' > query_parser.py
def parse_query(query_str):
    raise NotImplementedError("TODO: implement parse_query without phantom dependencies")
EOF

cat << 'EOF' > test_query_parser.py
import unittest
from query_parser import parse_query

class TestQueryParser(unittest.TestCase):
    def test_parse_simple(self):
        res = parse_query("name=John&age=30")
        self.assertEqual(res, {"name": ["John"], "age": ["30"]})

    def test_parse_multiple_values(self):
        res = parse_query("tags=ai&tags=os")
        self.assertEqual(res, {"tags": ["ai", "os"]})

if __name__ == "__main__":
    unittest.main()
EOF

git add requirements.txt query_parser.py test_query_parser.py
git commit -qm "Initial commit for query parser" || true

