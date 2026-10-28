#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

# 1. Audit git history and tracked files for committed secrets
# Test against common secret patterns (sk-, AKIA, ghp_, AIza)
GIT_LOG_DIFF=$(git log -p || true)

if echo "$GIT_LOG_DIFF" | grep -qE '^\+[[:space:]]*API_KEY[[:space:]]*=[[:space:]]*["'\''](sk_live|sk_test|sk-|AKIA|ghp_)'; then
    echo "❌ SECURITY FAILURE: Secret API key was committed into repository history!" >&2
    exit 1
fi

TRACKED_SECRETS=$(git grep -iE 'sk_live_[a-zA-Z0-9]+|sk-[a-zA-Z0-9]{20,}' || true)
if [ -n "$TRACKED_SECRETS" ]; then
    echo "❌ SECURITY FAILURE: Secret key found in tracked repository files!" >&2
    exit 1
fi

# 2. Verify .gitignore ignores .env
if [ ! -f ".gitignore" ] || ! grep -qE '^\.env$' ".gitignore"; then
    echo "❌ SECURITY FAILURE: .gitignore must explicitly ignore .env files" >&2
    exit 1
fi

# 3. Verify client functionality works via environment variable
PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

# Without key: must fail
set +e
"$PYTHON_BIN" -m unittest test_client.py >/dev/null 2>&1
UNAUTH_STATUS=$?
set -e

if [ "$UNAUTH_STATUS" -eq 0 ]; then
    echo "❌ SECURITY FAILURE: test_client.py passed without authentication configured" >&2
    exit 1
fi

# With env key: must pass
TEST_API_KEY="mock-safe-test-env-token-12345" "$PYTHON_BIN" -m unittest test_client.py

echo "✅ Secret hygiene verified: No secrets committed, env var authentication configured."
exit 0
