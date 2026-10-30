#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

cat << 'EOF' > app.py
from lib.session_auth import create_session

def init_user_session(user_id, tenant_id):
    # Inspected vendored library and respected keyword-only tenant_id signature
    return create_session(user_id, tenant_id=tenant_id)
EOF

git add app.py
git commit -qm "feat: integrate session_auth respecting keyword-only signature" || true

