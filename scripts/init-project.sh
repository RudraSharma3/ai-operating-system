#!/usr/bin/env bash
# One-Shot Project Scaffolding CLI for AI Operating System (macOS/Linux)

set -e

PROJECT_NAME="$1"
STACK="$2"
TARGET_DIR="${3:-.}"

if [ -z "$PROJECT_NAME" ]; then
    read -p "Enter Project Name (e.g. my-awesome-app): " PROJECT_NAME
fi

if [ -z "$STACK" ]; then
    read -p "Enter Tech Stack (e.g. Next.js + Tailwind + Supabase): " STACK
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/templates/project"
PROJECT_PATH="$TARGET_DIR/$PROJECT_NAME"

echo "===================================================="
echo " 🚀 Initializing AI Operating System Project: $PROJECT_NAME"
echo " Stack: $STACK"
echo " Path:  $PROJECT_PATH"
echo "===================================================="

if [ -d "$PROJECT_PATH" ]; then
    echo "Error: Directory '$PROJECT_PATH' already exists! Aborting."
    exit 1
fi

mkdir -p "$PROJECT_PATH"
cp -r "$TEMPLATE_DIR/." "$PROJECT_PATH/"

# Populate initial architecture stack
if [ -f "$PROJECT_PATH/docs/architecture.md" ]; then
    sed -i.bak "s/<!-- What does this project do? Who are the primary users? What problem does it solve? -->/Primary application: $PROJECT_NAME. Stack: $STACK./" "$PROJECT_PATH/docs/architecture.md" && rm "$PROJECT_PATH/docs/architecture.md.bak"
fi

cd "$PROJECT_PATH"
git init
if [ -d ".githooks" ]; then
    git config core.hooksPath .githooks
fi

git add .
git commit -m "feat: initialize $PROJECT_NAME with AI Operating System ($STACK)"

echo ""
echo "===================================================="
echo " ✨ SUCCESS! Project $PROJECT_NAME is ready."
echo " Next steps:"
echo "   1. cd $PROJECT_PATH"
echo "   2. Open in your AI IDE"
echo "   3. Prompt your agent: 'I want to build $PROJECT_NAME using $STACK'"
echo "===================================================="
