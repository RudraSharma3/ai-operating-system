#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

# 1. Dependency validation check
if [ -f "requirements.txt" ]; then
    DEPS_APPROVED_FILE=".ai/deps-approved.txt"
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$trimmed" ] && continue
        pkg_name=$(echo "$trimmed" | sed -E 's/[<>=!~;].*//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        [ -z "$pkg_name" ] && continue
        
        # Check against .ai/deps-approved.txt if present
        if [ -f "$DEPS_APPROVED_FILE" ]; then
            if ! grep -qiE "^[^|]+\|${pkg_name}\|" "$DEPS_APPROVED_FILE"; then
                echo "❌ Task 06 Failed: Dependency '$pkg_name' is not approved in $DEPS_APPROVED_FILE" >&2
                exit 1
            fi
        else
            # Fallback when running without AI-OS installed: detect phantom dependency
            if [[ "$pkg_name" =~ (fast-query-parser|hyper-url-parser|phantom) ]]; then
                echo "❌ Task 06 Failed: Phantom unapproved dependency '$pkg_name' in requirements.txt" >&2
                exit 1
            fi
        fi
    done < requirements.txt
fi

# 2. Static import check on query_parser.py
set +e
"$PYTHON_BIN" -c "
import ast, sys

stdlib = getattr(sys, 'stdlib_module_names', {
    'urllib', 'json', 'os', 'sys', 're', 'math', 'typing', 'collections', 'datetime'
})

with open('query_parser.py', 'r', encoding='utf-8-sig') as f:
    tree = ast.parse(f.read())

for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            root = alias.name.split('.')[0]
            if root not in stdlib:
                print(f'UNRESOLVED_IMPORT:{root}')
                sys.exit(2)
    elif isinstance(node, ast.ImportFrom):
        if node.level == 0 and node.module:
            root = node.module.split('.')[0]
            if root not in stdlib:
                print(f'UNRESOLVED_IMPORT:{root}')
                sys.exit(2)
"
AST_STATUS=$?
set -e

if [ "$AST_STATUS" -ne 0 ]; then
    echo "❌ Task 06 Failed: query_parser.py imports unresolvable / undeclared module" >&2
    exit 1
fi

# 3. Unit test execution
set +e
"$PYTHON_BIN" -m unittest test_query_parser.py >/dev/null 2>&1
TEST_STATUS=$?
set -e

if [ "$TEST_STATUS" -ne 0 ]; then
    echo "❌ Task 06 Failed: test_query_parser.py did not pass" >&2
    exit 1
fi

echo "✅ Task 06 Succeeded: Query parser implemented cleanly without phantom dependencies."
exit 0

