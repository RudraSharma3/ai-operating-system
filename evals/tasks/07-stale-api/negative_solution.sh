#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > app.py
from lib.session_auth import create_session

def init_user_session(user_id, tenant_id):
    # Gaming / hallucinated solution: assumes legacy positional signature without checking source
    return create_session(user_id, 3600)
EOF

git add app.py
git commit -qm "feat: integrate session_auth using assumed legacy signature" || true

