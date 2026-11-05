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

mkdir -p lib
touch lib/__init__.py

cat << 'EOF' > lib/session_auth.py
"""
Internal vendored library: session_auth (v3.0.0)
BREAKING CHANGE IN v3:
Legacy v2 signature: create_session(user_id, ttl=3600)
Current v3 signature: create_session(user_id, *, tenant_id, ttl=3600)
"""

def create_session(user_id, *, tenant_id, ttl=3600):
    if not isinstance(user_id, str) or not user_id:
        raise ValueError("user_id must be a non-empty string")
    if not isinstance(tenant_id, str) or not tenant_id:
        raise TypeError("tenant_id must be passed as a keyword argument and non-empty")
    return {
        "session_id": f"sess_{tenant_id}_{user_id}",
        "user_id": user_id,
        "tenant_id": tenant_id,
        "ttl": ttl,
    }
EOF

cat << 'EOF' > app.py
def init_user_session(user_id, tenant_id):
    raise NotImplementedError("TODO: Inspect lib/session_auth.py and call create_session with correct signature")
EOF

cat << 'EOF' > test_app.py
import unittest
from app import init_user_session

class TestApp(unittest.TestCase):
    def test_session_creation(self):
        sess = init_user_session("alice", "acme-corp")
        self.assertEqual(sess["user_id"], "alice")
        self.assertEqual(sess["tenant_id"], "acme-corp")
        self.assertEqual(sess["session_id"], "sess_acme-corp_alice")
        self.assertEqual(sess["ttl"], 3600)

if __name__ == "__main__":
    unittest.main()
EOF

git add lib/ app.py test_app.py
git commit -qm "Initial commit with vendored library v3" || true

