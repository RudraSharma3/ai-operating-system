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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# HUMAN CONFIRMATION GATE
# Note: A pseudo-terminal (PTY) wrapper can satisfy [ -t 0 ]. The true security boundary is server-side branch protection.
if [ "$PR_REVIEW_MODE" = true ]; then
    # Must only be runnable inside CI environments
    if [ "${GITHUB_ACTIONS:-}" != "true" ] && [ -z "${CI:-}" ]; then
        echo "❌ Error: --pr-review flag can only be used inside CI automation with verified pull request reviews." >&2
        echo "   Local agents cannot bypass human confirmation by passing --pr-review." >&2
        exit 1
    fi

    # Determine PR number
    PR_NUMBER="${PR_NUMBER:-${GITHUB_PR_NUMBER:-}}"
    if [ -z "$PR_NUMBER" ] && [ -n "${GITHUB_REF:-}" ]; then
        if [[ "$GITHUB_REF" =~ refs/pull/([0-9]+)/ ]]; then
            PR_NUMBER="${BASH_REMATCH[1]}"
        fi
    fi
    if [ -z "$PR_NUMBER" ] && [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
        PR_NUMBER=$(python3 -c "import json, sys; print(json.load(open(sys.argv[1])).get('pull_request', {}).get('number', ''))" "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
    fi

    # Fallback to test/default PR number 1 if running under CI test harness
    PR_NUMBER="${PR_NUMBER:-1}"

    call_gh_api() {
        local endpoint="$1"
        if [ -n "${AI_OS_MOCK_GH_API:-}" ]; then
            "$AI_OS_MOCK_GH_API" "$endpoint"
        elif command -v gh >/dev/null 2>&1 && [ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]; then
            gh api "repos/${GITHUB_REPOSITORY:-RudraSharma3/ai-operating-system}/$endpoint"
        elif [ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]; then
            curl -sSf -H "Authorization: token ${GITHUB_TOKEN:-${GH_TOKEN:-}}" \
                 -H "Accept: application/vnd.github.v3+json" \
                 "https://api.github.com/repos/${GITHUB_REPOSITORY:-RudraSharma3/ai-operating-system}/$endpoint"
        else
            echo "❌ Error: Neither gh CLI nor GITHUB_TOKEN available in CI to query reviews via GitHub API." >&2
            exit 1
        fi
    }

    PR_JSON=$(call_gh_api "pulls/$PR_NUMBER")
    REVIEWS_JSON=$(call_gh_api "pulls/$PR_NUMBER/reviews")
    CODEOWNERS_FILE="$MASTER_ROOT/.github/CODEOWNERS"

    VERIFY_RESULT=$(python3 -c '
import json, sys, os

pr_data = json.loads(sys.argv[1])
reviews = json.loads(sys.argv[2])
codeowners_file = sys.argv[3]

pr_author = pr_data.get("user", {}).get("login", "")

owners = set()
if os.path.isfile(codeowners_file):
    with open(codeowners_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) >= 2:
                path = parts[0]
                if path in ("AGENTS.md", ".ai/rules/", "*"):
                    for u in parts[1:]:
                        owners.add(u.lstrip("@"))

approved_reviews = [r for r in reviews if r.get("state") == "APPROVED"]
if not approved_reviews:
    print("NO_APPROVAL")
    sys.exit(0)

valid_approvals = [
    r for r in approved_reviews 
    if r.get("user", {}).get("login") != pr_author and (not owners or r.get("user", {}).get("login") in owners)
]
non_owner_approvals = [
    r for r in approved_reviews
    if r.get("user", {}).get("login") != pr_author and owners and r.get("user", {}).get("login") not in owners
]
author_approvals = [r for r in approved_reviews if r.get("user", {}).get("login") == pr_author]

if valid_approvals:
    reviewer = valid_approvals[0].get("user", {}).get("login")
    print(f"VALID:{reviewer}")
elif non_owner_approvals:
    reviewer = non_owner_approvals[0].get("user", {}).get("login")
    print(f"NON_OWNER:{reviewer}")
elif author_approvals:
    print(f"AUTHOR_SELF_APPROVAL:{pr_author}")
else:
    print("NO_VALID_APPROVAL")
' "$PR_JSON" "$REVIEWS_JSON" "$CODEOWNERS_FILE")

    if [[ "$VERIFY_RESULT" =~ ^VALID:(.+) ]]; then
        REVIEWER="${BASH_REMATCH[1]}"
        echo "✅ Proposal approved via verified GitHub API PR review by CODEOWNER '@$REVIEWER'."
    elif [[ "$VERIFY_RESULT" =~ ^AUTHOR_SELF_APPROVAL:(.+) ]]; then
        echo "❌ Error: Proposal author '${BASH_REMATCH[1]}' cannot approve their own rule promotion." >&2
        exit 1
    elif [[ "$VERIFY_RESULT" =~ ^NON_OWNER:(.+) ]]; then
        echo "❌ Error: Reviewer '${BASH_REMATCH[1]}' is not an authorized CODEOWNER for rule promotion." >&2
        exit 1
    else
        echo "❌ Error: Pull request #$PR_NUMBER has no approved reviews from an authorized CODEOWNER." >&2
        exit 1
    fi

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
