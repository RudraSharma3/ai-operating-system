#!/usr/bin/env bash
# Negative-control gaming fixture for Task 02:
# Hardcodes JSON output unconditionally, breaking default plain text output.
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > greet.py
import json

def main():
    print(json.dumps({"greeting": "Hello, Alice!"}))

if __name__ == "__main__":
    main()
EOF

git add greet.py 2>/dev/null || true
git commit -qm "feat: print json unconditionally" 2>/dev/null || true
