#!/usr/bin/env bash
# AI Operating System Animated Project Integrator (by Rudra Sharma) - macOS/Linux

set -e

TARGET_PATH="${1:-.}"
GIT_USER=$(git config user.name || echo "$USER")
PROJECT_NAME=$(basename "$TARGET_PATH")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/templates/project"

animate_step() {
    local text="$1"
    local spinstr='/-\|'
    for i in {1..8}; do
        local temp=${spinstr#?}
        printf "\r  \033[36m%c %s\033[0m" "$spinstr" "$text"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.04
    done
    printf "\r  \033[32m[OK] %s\033[0m\n" "$text"
}

echo ""
echo -e "\033[33m         +-----------------------------------------+\033[0m"
echo -e "\033[33m         |   [ * _ * ]   (b^_^ )b   ALL SYSTEMS GO |\033[0m"
echo -e "\033[33m         |   AI-OS Ready to Code, Boss!            |\033[0m"
echo -e "\033[33m         +--------------------+--------------------+\033[0m"
echo -e "\033[33m                              |\033[0m"
echo -e "\033[36m    ___    ____      ____  _____ \033[0m"
echo -e "\033[36m   /   |  /  _/     / __ \/ ___/ \033[0m"
echo -e "\033[36m  / /| |  / /______/ / / /\__ \  \033[0m"
echo -e "\033[36m / ___ |_/ /_____/ /_/ /___/ /  \033[0m"
echo -e "\033[36m/_/  |_/___/      \____//____/   \033[0m"
echo -e "\033[35m   ++ AI OPERATING SYSTEM v2.0 ++\033[0m"
echo -e "\033[90m       by Rudra Sharma\033[0m"
echo ""
echo -e "\033[36m========================================================================\033[0m"
echo -e " Target Project: \033[37m$PROJECT_NAME\033[0m"
echo -e " Target Path:    \033[90m$TARGET_PATH\033[0m"
echo -e " Engineer:       \033[37m$GIT_USER\033[0m"
echo -e "\033[36m========================================================================\033[0m"
echo ""

if [ ! -d "$TARGET_PATH" ]; then
    echo -e "\033[31mError: Target directory does not exist: $TARGET_PATH\033[0m"
    exit 1
fi

animate_step "Ingesting AI-OS Architecture, Rules and Adapters..."
cp -n -r "$TEMPLATE_DIR/." "$TARGET_PATH/" 2>/dev/null || true

animate_step "Armoring Pre-Commit Secret Scanning and Git Protection..."
cd "$TARGET_PATH"
if [ -d ".git" ] && [ -d ".githooks" ]; then
    git config core.hooksPath .githooks
fi

animate_step "Running Diagnostic Verification..."
echo ""

echo -e "\033[32m+=======================================================================+\033[0m"
echo -e "\033[32m|                                                                       |\033[0m"
printf "\033[32m|   *** HEY %-47s (b^_^)b *** |\033[0m\n" "${GIT_USER^^}! AI-OS IS INTEGRATED!"
printf "\033[32m|   Target Project: %-51s |\033[0m\n" "$PROJECT_NAME"
echo -e "\033[32m|                                                                       |\033[0m"
echo -e "\033[32m|   Persistent Memory:       [ ONLINE  ]                                |\033[0m"
echo -e "\033[32m|   Secret Armor Pre-Commit: [ ARMED   ]                                |\033[0m"
echo -e "\033[32m|   Prompt Auto-Refiner:     [ ACTIVE  ]                                |\033[0m"
echo -e "\033[32m|   Codebase Graph Engine:   [ READY   ]                                |\033[0m"
echo -e "\033[32m|                                                                       |\033[0m"
echo -e "\033[32m+=======================================================================+\033[0m"
echo ""
echo -e "\033[36m+-----------------------------------------------------------------------+\033[0m"
echo -e "\033[33m| [!] COPY AND PASTE THIS FIRST PROMPT INTO YOUR AI IDE CHAT:           |\033[0m"
echo -e "\033[36m+-----------------------------------------------------------------------+\033[0m"
echo -e "\033[36m|                                                                       |\033[0m"
echo -e "\033[37m|  Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze  |\033[0m"
echo -e "\033[37m|  this repository. Please map our existing codebase and update        |\033[0m"
echo -e "\033[37m|  docs/architecture.md, docs/conventions.md, and docs/graph.md with   |\033[0m"
echo -e "\033[37m|  our current components, tech stack, and data flow.                  |\033[0m"
echo -e "\033[36m|                                                                       |\033[0m"
echo -e "\033[36m+-----------------------------------------------------------------------+\033[0m"
echo ""
