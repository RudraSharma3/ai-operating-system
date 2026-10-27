#!/usr/bin/env bash
# AI-OS Proposal Promotion Engine
# Promotes a validated proposal from proposals/ into canonical .ai/rules/
# and triggers compilation into AGENTS.md and templates/project.
#
# SECURITY GATE: Enforces mandatory human confirmation. Cannot be run silently
# by automated agents in non-interactive mode without explicit --pr-review approval.

set -euo pipefail

PR_REVIEW_MODE=false
PROPOSAL_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pr-review)
            PR_REVIEW_MODE=true
            shift
            ;;
        *)
            if [ -z "$PROPOSAL_FILE" ]; then
                PROPOSAL_FILE="$1"
                shift
            else
                echo "Unknown argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

if [ -z "$PROPOSAL_FILE" ]; then
    echo "Usage: approve-proposal.sh [--pr-review] <proposals/proposal-file.md>" >&2
    exit 1
fi

if [ ! -f "$PROPOSAL_FILE" ]; then
    echo "❌ Error: Proposal file not found: $PROPOSAL_FILE" >&2
    exit 1
fi

PROPOSAL_BASENAME=$(basename "$PROPOSAL_FILE" .md)

# HUMAN CONFIRMATION GATE
# Note: A pseudo-terminal (PTY) wrapper can satisfy [ -t 0 ]. The true security boundary is server-side branch protection.
if [ "$PR_REVIEW_MODE" = true ]; then
    # Must only be runnable inside CI environments
    if [ "${GITHUB_ACTIONS:-}" != "true" ] && [ -z "${CI:-}" ]; then
        echo "❌ Error: --pr-review flag can only be used inside CI automation with verified pull request reviews." >&2
        echo "   Local agents cannot bypass human confirmation by passing --pr-review." >&2
        exit 1
    fi

    # In CI PR workflows, verify approvals if event payload is present
    if [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
        AUTHOR=$(python3 -c "import json, sys; d=json.load(open(sys.argv[1])); print(d.get('pull_request',{}).get('user',{}).get('login',''))" "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
        REVIEWER=$(python3 -c "import json, sys; d=json.load(open(sys.argv[1])); print(d.get('review',{}).get('user',{}).get('login',''))" "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
        
        if [ -n "$AUTHOR" ] && [ -n "$REVIEWER" ] && [ "$AUTHOR" = "$REVIEWER" ]; then
            echo "❌ Error: Proposal author '$AUTHOR' cannot approve their own rule promotion." >&2
            exit 1
        fi
    fi
    echo "✅ Proposal approved via verified GitHub PR review in CI."
else
    if [ ! -t 0 ]; then
        echo "❌ Error: approve-proposal requires interactive human confirmation in a terminal." >&2
        echo "   Automated / non-interactive agents cannot approve proposals silently without human verification." >&2
        exit 1
    fi
    
    echo "===================================================="
    echo " 🚨 PROPOSAL PROMOTION HUMAN APPROVAL GATE"
    echo " Proposal File: $PROPOSAL_FILE"
    echo " Proposal ID:   $PROPOSAL_BASENAME"
    echo " (Notice: Terminal PTY can be spoofed; server-side PR review is the real security gate)"
    echo "===================================================="
    read -r -p "Type '$PROPOSAL_BASENAME' to confirm promotion: " CONFIRM_INPUT
    
    if [ "$CONFIRM_INPUT" != "$PROPOSAL_BASENAME" ]; then
        echo "❌ Error: Confirmation string did not match '$PROPOSAL_BASENAME'. Promotion rejected." >&2
        exit 1
    fi
    echo "✅ Human confirmation verified."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_DIR="$MASTER_ROOT/.ai/rules"
mkdir -p "$RULES_DIR"

# Extract rule content from proposal
PROPOSED_LINE=$(grep -E '^`\[[A-Z]+\]' "$PROPOSAL_FILE" | head -n 1 | tr -d '`' || true)

if [ -z "$PROPOSED_LINE" ]; then
    echo "❌ Error: Could not locate proposed rule definition in $PROPOSAL_FILE" >&2
    exit 1
fi

# Generate timestamp/slug ID to avoid collision
TIMESTAMP=$(date +"%Y%m%d")
SLUG=$(echo "$PROPOSED_LINE" | sed -E 's/^\[[A-Z]+\][[:space:]]+//' | sed -E 's/—.*//' | sed -E 's/-.*//' | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-//;s/-$//' | cut -c 1-30)
RULE_ID="${TIMESTAMP}-${SLUG}"
NEW_RULE_FILENAME="${RULE_ID}.md"
NEW_RULE_PATH="$RULES_DIR/$NEW_RULE_FILENAME"

# Full rule line: <ID>. [CATEGORY] Description — rationale.
FULL_RULE_LINE="${RULE_ID}. ${PROPOSED_LINE}"

echo "📝 Promoting proposal to Rule ${RULE_ID}: $FULL_RULE_LINE"
echo "$FULL_RULE_LINE" > "$NEW_RULE_PATH"

# Archive proposal
ARCHIVE_DIR="$MASTER_ROOT/proposals/approved"
mkdir -p "$ARCHIVE_DIR"
mv "$PROPOSAL_FILE" "$ARCHIVE_DIR/"
echo "📦 Archived proposal to proposals/approved/"

# Trigger rule compiler and template builder
echo "🔄 Recompiling canonical AGENTS.md..."
"$SCRIPT_DIR/compile-rules.sh" --project "$MASTER_ROOT"

echo "🔄 Rebuilding templates..."
"$SCRIPT_DIR/build-templates.sh"

echo "🎉 Proposal $PROPOSAL_BASENAME successfully approved and promoted to canonical rule $RULE_ID!"
