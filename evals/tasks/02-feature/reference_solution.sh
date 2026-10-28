#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > greet.py
import sys
import argparse
import json

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="World")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.json:
        print(json.dumps({"greeting": f"Hello, {args.name}!"}))
    else:
        print(f"Hello, {args.name}!")

if __name__ == "__main__":
    main()
EOF

git add greet.py
git commit -qm "feat: add --json and --name flag support to greeter" || true
