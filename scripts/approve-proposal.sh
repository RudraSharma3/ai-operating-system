#!/usr/bin/env bash
# AI-OS Proposal Promotion Engine
# Promotes a validated proposal from proposals/ into canonical .ai/rules/
# and triggers compilation into AGENTS.md and templates/project.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: approve-proposal.sh <proposals/proposal-file.md>" >&2
    exit 1
fi

PROPOSAL_FILE="$1"

if [ ! -f "$PROPOSAL_FILE" ]; then
    echo "❌ Error: Proposal file not found: $PROPOSAL_FILE" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_DIR="$MASTER_ROOT/.ai/rules"
mkdir -p "$RULES_DIR"

# Extract rule content from proposal
# Looks for line starting with `[CATEGORY] ...`
PROPOSED_LINE=$(grep -E '^`\[[A-Z]+\]' "$PROPOSAL_FILE" | head -n 1 | tr -d '`' || true)

if [ -z "$PROPOSED_LINE" ]; then
    echo "❌ Error: Could not locate proposed rule definition in $PROPOSAL_FILE" >&2
    exit 1
fi

# Find next sequential rule number
MAX_NUM=0
for rf in "$RULES_DIR"/*.md; do
    if [ -f "$rf" ]; then
        bname=$(basename "$rf")
        if [[ "$bname" =~ ^([0-9]+)- ]]; then
            num=$((10#${BASH_REMATCH[1]}))
            if [ "$num" -gt "$MAX_NUM" ]; then
                MAX_NUM="$num"
            fi
        fi
    fi
done

NEXT_NUM=$((MAX_NUM + 1))
NEXT_PADDED=$(printf "%04d" "$NEXT_NUM")

# Generate slug
SLUG=$(echo "$PROPOSED_LINE" | sed -E 's/^\[[A-Z]+\][[:space:]]+//' | sed -E 's/—.*//' | sed -E 's/-.*//' | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-//;s/-$//' | cut -c 1-35)
NEW_RULE_FILENAME="${NEXT_PADDED}-${SLUG}.md"
NEW_RULE_PATH="$RULES_DIR/$NEW_RULE_FILENAME"

# Full rule line: N. [CATEGORY] Description — rationale.
FULL_RULE_LINE="${NEXT_NUM}. ${PROPOSED_LINE}"

echo "📝 Promoting proposal to Rule ${NEXT_NUM}: $FULL_RULE_LINE"
echo "$FULL_RULE_LINE" > "$NEW_RULE_PATH"

# Recompile canonical AGENTS.md
echo "🔄 Compiling rules into AGENTS.md..."
"$SCRIPT_DIR/compile-rules.sh" --project "$MASTER_ROOT"

# Rebuild templates/project
echo "🔨 Synchronizing template package..."
"$SCRIPT_DIR/build-templates.sh"

# Mark proposal as approved
sed -i.bak -E 's/\*\*Status\*\*:[[:space:]]*PENDING/**Status**: APPROVED/' "$PROPOSAL_FILE"
rm -f "${PROPOSAL_FILE}.bak"
echo "" >> "$PROPOSAL_FILE"
echo "## Approval Record" >> "$PROPOSAL_FILE"
echo "- **Approved Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$PROPOSAL_FILE"
echo "- **Canonical Rule**: Rule ${NEXT_NUM} (\`.ai/rules/${NEW_RULE_FILENAME}\`)" >> "$PROPOSAL_FILE"

echo "===================================================="
echo " [SUCCESS] Proposal approved into Rule ${NEXT_NUM}!"
echo " Location: .ai/rules/${NEW_RULE_FILENAME}"
echo " AGENTS.md and templates/project are fully synchronized."
echo "===================================================="
