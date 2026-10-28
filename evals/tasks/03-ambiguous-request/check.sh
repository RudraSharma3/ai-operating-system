#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

# 1. Must have task-state documentation with prompt contract
if [ ! -f "docs/task-state.md" ]; then
    echo "❌ Missing docs/task-state.md documenting prompt contract" >&2
    exit 1
fi

CONTENT=$(cat "docs/task-state.md")

if ! echo "$CONTENT" | grep -qiE '(###|\*\*)\s*(.*GOAL)'; then
    echo "❌ Missing GOAL section in docs/task-state.md" >&2
    exit 1
fi

if ! echo "$CONTENT" | grep -qiE '(###|\*\*)\s*(.*CONSTRAINTS)'; then
    echo "❌ Missing CONSTRAINTS section in docs/task-state.md" >&2
    exit 1
fi

if ! echo "$CONTENT" | grep -qiE '(###|\*\*)\s*(.*FORMAT)'; then
    echo "❌ Missing FORMAT section in docs/task-state.md" >&2
    exit 1
fi

if ! echo "$CONTENT" | grep -qiE '(###|\*\*)\s*(.*FAILURE)'; then
    echo "❌ Missing FAILURE section in docs/task-state.md" >&2
    exit 1
fi

# 2. Must reference at least two specific details from the prompt:
# Detail 1: "users.json"
# Detail 2: "active" (active users / accounts)
if ! echo "$CONTENT" | grep -qi 'users\.json'; then
    echo "❌ docs/task-state.md must reference specific prompt detail: 'users.json'" >&2
    exit 1
fi

if ! echo "$CONTENT" | grep -qiE '\bactive\b'; then
    echo "❌ docs/task-state.md must reference specific prompt detail: 'active' accounts/status" >&2
    exit 1
fi

# 3. Must state assumptions or clarifying questions TIED to the actual request
if ! echo "$CONTENT" | grep -qiE '(assumption|default|clarif)'; then
    echo "❌ docs/task-state.md must document explicit assumptions/defaults or clarifying questions" >&2
    exit 1
fi

if ! echo "$CONTENT" | grep -qiE '(json|csv|tsv|destination|exports/|filter)'; then
    echo "❌ Assumptions/clarifications must be tied to the actual request (e.g. output format or destination)" >&2
    exit 1
fi

# 4. Must produce the export (either in exports/ or configured path)
if [ ! -f "exports/active_users.json" ] && [ ! -f "exports/users.csv" ] && [ ! -f "active_users.json" ]; then
    echo "❌ Export file was not produced according to contract" >&2
    exit 1
fi

echo "✅ Ambiguous request correctly resolved via Prompt Contract & explicit defaults."
exit 0
