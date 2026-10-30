#!/usr/bin/env bash
# AI-OS Interactive & Automated Demonstration Script
# Demonstrates secret blocking, phantom dependency blocking, and clean commit execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================================"
echo " 🛡️ AI-OS LIVE CAPABILITY DEMONSTRATION"
echo "============================================================"

SYS_TMP="${TMPDIR:-/tmp}"
[ ! -d "$SYS_TMP" ] && SYS_TMP="/tmp"
DEMO_DIR=$(mktemp -d "$SYS_TMP/aios_demo_XXXXXX" 2>/dev/null || mktemp -d -t 'aios_demo')

cleanup() {
    if [ -d "$DEMO_DIR" ]; then
        rm -rf "$DEMO_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "📁 Created scratch demonstration repository at $DEMO_DIR"
cd "$DEMO_DIR"

git init -q
git config user.name "AI-OS Demo User"
git config user.email "demo@ai-os.dev"

# Initial base commit
echo "# Demo Project" > README.md
git add README.md
git commit -qm "Initial commit"

echo "⚙️ Installing AI-OS..."
bash "$ROOT_DIR/scripts/install.sh" "$DEMO_DIR" >/dev/null 2>&1
git add -A
git commit -qm "chore: initialize AI-OS baseline"

echo ""
echo "--- Scenario 1: Attempting to commit a leaked secret token ---"
KEY_PREFIX="sk_live_"
KEY_BODY="51Abcd1234efgh5678ijkl9012345678"
FAKE_KEY="${KEY_PREFIX}${KEY_BODY}"
cat << EOF > app_config.py
# Inadvertent secret leak
SERVICE_KEY = "$FAKE_KEY"
EOF

git add app_config.py
if git commit -m "feat: add service credentials" >/dev/null 2>&1; then
    echo "❌ ERROR: Secret commit was permitted!" >&2
    exit 1
else
    echo " [BLOCKED] Secret leak commit rejected by AI-OS pre-commit guard."
fi
git reset --hard HEAD >/dev/null 2>&1
git clean -fd >/dev/null 2>&1

echo ""
echo "--- Scenario 2: Attempting to commit an unapproved phantom dependency ---"
echo "phantom-ai-query-parser==1.0.0" >> requirements.txt
git add requirements.txt
if git commit -m "feat: add query parser package" >/dev/null 2>&1; then
    echo "❌ ERROR: Phantom dependency commit was permitted!" >&2
    exit 1
else
    echo " [BLOCKED] Unapproved dependency rejected by AI-OS dependency verifier."
fi
git reset --hard HEAD >/dev/null 2>&1
git clean -fd >/dev/null 2>&1

echo ""
echo "--- Scenario 3: Committing a clean, harmless change ---"
cat << 'EOF' > math_utils.py
import math

def calculate_circle_area(radius):
    """Calculates the area of a circle using stdlib math."""
    if radius < 0:
        raise ValueError("radius cannot be negative")
    return math.pi * radius * radius
EOF

git add math_utils.py
if git commit -m "feat: add circular area utility" >/dev/null 2>&1; then
    echo " [ALLOWED] Clean change committed successfully through verification hooks."
else
    echo "❌ ERROR: Harmless commit was unexpectedly blocked!" >&2
    exit 1
fi

echo ""
echo "============================================================"
echo " Demo Summary: 2 Blocked (Secret, Phantom Dep) | 1 Allowed (Clean)"
echo "============================================================"
exit 0
