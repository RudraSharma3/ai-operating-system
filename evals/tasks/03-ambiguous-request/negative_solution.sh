#!/usr/bin/env bash
# Negative-control gaming fixture for Task 03:
# Emits generic GOAL/CONSTRAINTS/FORMAT/FAILURE keywords and generic default word,
# but omits prompt-specific details (users.json, active) and ties nothing to the request.
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

mkdir -p docs

cat << 'EOF' > docs/task-state.md
# Active Task State: Generic Task

## Defaults
- Assumed standard defaults.

## Prompt Contract
### 🎯 GOAL:
Perform the requested operation.

### ⛓️ CONSTRAINTS:
- Do not fail.

### 📁 FORMAT:
Standard format.

### ❌ FAILURE:
- Failure to complete.
EOF

# Create dummy output file to simulate superficial completion
mkdir -p exports
echo '[]' > exports/active_users.json

git add docs/task-state.md exports/active_users.json 2>/dev/null || true
git commit -qm "chore: generic contract without prompt details" 2>/dev/null || true
