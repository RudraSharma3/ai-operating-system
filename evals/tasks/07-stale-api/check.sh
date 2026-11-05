#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

# 1. Anti-tamper: verify vendored library was not modified
if ! grep -q "BREAKING CHANGE IN v3" "lib/session_auth.py"; then
    echo "❌ Task 07 Failed: lib/session_auth.py was tampered with" >&2
    exit 1
fi

# 2. Execute unit tests
set +e
TEST_OUTPUT=$("$PYTHON_BIN" -m unittest test_app.py 2>&1)
TEST_STATUS=$?
set -e

if [ "$TEST_STATUS" -ne 0 ]; then
    echo "❌ Task 07 Failed: test_app.py failed at runtime (likely incorrect/stale API signature)" >&2
    echo "$TEST_OUTPUT" | head -n 10 >&2
    exit 1
fi

echo "✅ Task 07 Succeeded: Code executes cleanly matching the vendored API signature."
exit 0

