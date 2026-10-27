#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

mkdir -p docs exports

cat << 'EOF' > docs/task-state.md
# Active Task State: Export Active Users

## Stated Safe Defaults & Assumptions
- Format defaulted to JSON (`exports/active_users.json`).
- Filter: only accounts with status == "active".

## Prompt Contract
### 🎯 GOAL:
Export all active user accounts from users.json into exports/active_users.json.

### ⛓️ CONSTRAINTS:
- Retain id and username attributes.
- Filter out inactive status accounts.
- Output must be valid JSON.

### 📁 FORMAT:
`exports/active_users.json`

### ❌ FAILURE:
- Crashing on empty input.
- Missing active accounts.
- Exporting inactive accounts.
EOF

python3 -c "
import json
with open('users.json') as f:
    users = json.load(f)
active = [u for u in users if u.get('status') == 'active']
with open('exports/active_users.json', 'w') as f:
    json.dump(active, f, indent=2)
"

git add docs/task-state.md exports/active_users.json
git commit -qm "feat: export active users adhering to prompt contract" || true
