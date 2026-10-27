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

cat << 'EOF' > users.json
[
  {"id": 1, "username": "alice", "status": "active"},
  {"id": 2, "username": "bob", "status": "inactive"},
  {"id": 3, "username": "carol", "status": "active"}
]
EOF

git add users.json
git commit -qm "Initial commit with users database" || true
