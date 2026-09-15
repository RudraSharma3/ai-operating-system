#!/usr/bin/env bash
# AI Operating System Project Integrator (by Rudra Sharma) - macOS/Linux

set -e

TARGET_PATH="${1:-.}"
GIT_USER=$(git config user.name || echo "$USER")
PROJECT_NAME=$(basename "$TARGET_PATH")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/templates/project"

echo "========================================================================"
echo " 🚀 AI Operating System (AI-OS by Rudra Sharma) - Project Integrator"
echo " Target Project: $PROJECT_NAME ($TARGET_PATH)"
echo " User:           $GIT_USER"
echo "========================================================================"

if [ ! -d "$TARGET_PATH" ]; then
    echo "Error: Directory '$TARGET_PATH' does not exist!"
    exit 1
fi

echo "[1/3] Copying AI-OS architecture and rule files..."
cp -n -r "$TEMPLATE_DIR/." "$TARGET_PATH/" 2>/dev/null || true

echo "[2/3] Configuring secret protection and Git hooks..."
cd "$TARGET_PATH"
if [ -d ".git" ] && [ -d ".githooks" ]; then
    git config core.hooksPath .githooks
fi

echo ""
echo "========================================================================"
echo " 🎉 Hey $GIT_USER! AI-OS by Rudra is successfully integrated"
echo "    into your project '$PROJECT_NAME'!"
echo "========================================================================"
echo ""
echo "📌 NEXT STEP: Open '$PROJECT_NAME' in your AI IDE and paste this prompt:"
echo "------------------------------------------------------------------------"
echo "Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze this repository."
echo "Please map our existing codebase and update docs/architecture.md, docs/conventions.md,"
echo "and docs/graph.md with our current components, tech stack, and data flow."
echo "------------------------------------------------------------------------"
echo ""
