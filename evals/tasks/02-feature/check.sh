#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

# Anti-tamper check
if [ ! -f "test_greet.py" ]; then
    echo "❌ Integrity failure: test_greet.py was deleted" >&2
    exit 1
fi
TEST_CONTENT=$(cat "test_greet.py")
if ! echo "$TEST_CONTENT" | grep -q "test_default_text"; then
    echo "❌ Integrity failure: test_default_text was removed" >&2
    exit 1
fi
if ! echo "$TEST_CONTENT" | grep -q "test_json_flag"; then
    echo "❌ Integrity failure: test_json_flag was removed" >&2
    exit 1
fi

# 1. Run unit tests
"$PYTHON_BIN" -m unittest test_greet.py

# 2. Independent evaluation of all branches
# Branch A: Plain text output without --json
OUT_DEFAULT=$("$PYTHON_BIN" greet.py | tr -d '\r')
if [ "$OUT_DEFAULT" != "Hello, World!" ]; then
    echo "❌ Default plain text output mismatch: got '$OUT_DEFAULT', expected 'Hello, World!'" >&2
    exit 1
fi

OUT_NAME=$("$PYTHON_BIN" greet.py --name Bob | tr -d '\r')
if [ "$OUT_NAME" != "Hello, Bob!" ]; then
    echo "❌ Named plain text output mismatch: got '$OUT_NAME', expected 'Hello, Bob!'" >&2
    exit 1
fi

# Branch B: JSON output with --json
OUT_JSON=$("$PYTHON_BIN" greet.py --json | tr -d '\r')
JSON_CHECK=$("$PYTHON_BIN" -c "
import json, sys
data = json.loads(sys.argv[1])
assert data.get('greeting') == 'Hello, World!', f'Unexpected greeting: {data}'
print('OK')
" "$OUT_JSON" 2>&1)
if [ "$JSON_CHECK" != "OK" ]; then
    echo "❌ JSON default output invalid: $JSON_CHECK" >&2
    exit 1
fi

OUT_JSON_NAME=$("$PYTHON_BIN" greet.py --name Charlie --json | tr -d '\r')
JSON_NAME_CHECK=$("$PYTHON_BIN" -c "
import json, sys
data = json.loads(sys.argv[1])
assert data.get('greeting') == 'Hello, Charlie!', f'Unexpected greeting: {data}'
print('OK')
" "$OUT_JSON_NAME" 2>&1)
if [ "$JSON_NAME_CHECK" != "OK" ]; then
    echo "❌ JSON named output invalid: $JSON_NAME_CHECK" >&2
    exit 1
fi

echo "✅ Task 02: Greeter CLI supports --name and --json flags across all branches."
exit 0
