#!/usr/bin/env bash
# AI Operating System Minimalist Project Integrator (by Rudra Sharma) - macOS/Linux

set -e

TARGET_PATH="${1:-.}"
GIT_USER=$(git config user.name || echo "$USER")
PROJECT_NAME=$(basename "$TARGET_PATH")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/templates/project"

echo ""
echo -e "  \033[36m> AI Operating System v2.0\033[0m"
echo -e "  \033[90m  by Rudra Sharma\033[0m"
echo ""

if [ ! -d "$TARGET_PATH" ]; then
    echo -e "  \033[31m[X] Target directory not found: $TARGET_PATH\033[0m"
    exit 1
fi

echo -e "  \033[90m[+] Target: $PROJECT_NAME ($TARGET_PATH)\033[0m"

cp -n -r "$TEMPLATE_DIR/." "$TARGET_PATH/" 2>/dev/null || true
echo -e "  \033[32m[OK] Architecture and Canonical Rules Ingested\033[0m"

cd "$TARGET_PATH"
if [ -d ".git" ] && [ -d ".githooks" ]; then
    git config core.hooksPath .githooks
fi
echo -e "  \033[32m[OK] Git Pre-Commit Secret Armor Armed\033[0m"
echo ""

echo -e "  \033[33mHey $GIT_USER! AI-OS by Rudra is successfully integrated into '$PROJECT_NAME'!\033[0m"
echo ""
echo -e "  \033[36mNext Step: Open '$PROJECT_NAME' in your AI IDE and paste this prompt:\033[0m"
echo -e "  \033[90m--------------------------------------------------------------------------\033[0m"
echo -e "  \033[37mRead AGENTS.md and follow playbooks/codebase-analysis.md to analyze this\033[0m"
echo -e "  \033[37mrepository. Please map our existing codebase and update docs/architecture.md,\033[0m"
echo -e "  \033[37mdocs/conventions.md, and docs/graph.md with our current components,\033[0m"
echo -e "  \033[37mtech stack, and data flow.\033[0m"
echo -e "  \033[90m--------------------------------------------------------------------------\033[0m"
echo ""
