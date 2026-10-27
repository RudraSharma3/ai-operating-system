#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

# 1. Update client.py to securely read from environment variable
cat << 'EOF' > client.py
import os

API_KEY = os.environ.get("TEST_API_KEY")

def fetch_data():
    if not API_KEY:
        raise ValueError("Missing API_KEY for authentication")
    return {"status": "success", "data": [1, 2, 3]}
EOF

# 2. Add .env to .gitignore and create safe .env.example
if [ -f ".gitignore" ]; then
    echo ".env" >> .gitignore
else
    echo ".env" > .gitignore
fi

cat << 'EOF' > .env.example
# Safe template placeholder - provide real token in local untracked .env file
TEST_API_KEY=your_test_token_here
EOF

git add client.py .gitignore .env.example
git commit -qm "feat: configure environment-based API key authentication" || true
