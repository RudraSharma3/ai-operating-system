#!/usr/bin/env bash
# AI Operating System Project Integrator (by Rudra Sharma) - macOS/Linux

set -e

TARGET_PATH="${1:-.}"
GIT_USER=$(git config user.name 2>/dev/null || echo "$USER")
[ -z "$GIT_USER" ] && GIT_USER="Developer"
PROJECT_NAME=$(basename "$TARGET_PATH")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/templates/project"

echo ""
echo -e "\033[36m    ___    ____      ____  _____ \033[0m"
echo -e "\033[36m   /   |  /  _/     / __ \/ ___/ \033[0m"
echo -e "\033[36m  / /| |  / /______/ / / /\__ \  \033[0m"
echo -e "\033[36m / ___ |_/ /_____/ /_/ /___/ /  \033[0m"
echo -e "\033[36m/_/  |_/___/      \____//____/   \033[0m"
echo -e "\033[35m   ++ AI OPERATING SYSTEM v2.0 ++\033[0m"
echo -e "\033[90m       by Rudra Sharma\033[0m"
echo ""

echo "========================================================================"
echo " 🚀 AI Operating System (AI-OS by Rudra Sharma) - Project Integrator"
echo " Target Project: $PROJECT_NAME ($TARGET_PATH)"
echo " User:           $GIT_USER"
echo "========================================================================"

if [ ! -d "$TARGET_PATH" ]; then
    echo "Error: Directory '$TARGET_PATH' does not exist!"
    exit 1
fi

echo ""
echo "[1/3] Copying AI-OS architecture, rule files, and playbooks..."
cd "$TEMPLATE_DIR"
find . -type f | while IFS= read -r rel_file; do
    rel_path="${rel_file#./}"
    dest_file="$TARGET_PATH/$rel_path"
    dest_dir="$(dirname "$dest_file")"
    mkdir -p "$dest_dir"
    if [ ! -f "$dest_file" ]; then
        cp "$rel_path" "$dest_file"
        echo "  + Added $rel_path"
    else
        echo "  = Preserved existing $rel_path"
    fi
done

# Non-destructive .gitignore merge
GITIGNORE_SRC="$TEMPLATE_DIR/.gitignore"
GITIGNORE_DEST="$TARGET_PATH/.gitignore"
if [ -f "$GITIGNORE_DEST" ]; then
    if ! grep -q "# --- AI-OS START ---" "$GITIGNORE_DEST" 2>/dev/null; then
        echo "" >> "$GITIGNORE_DEST"
        echo "# --- AI-OS START ---" >> "$GITIGNORE_DEST"
        echo ".env" >> "$GITIGNORE_DEST"
        echo ".env.*" >> "$GITIGNORE_DEST"
        echo "!.env.example" >> "$GITIGNORE_DEST"
        echo "!.env.sample" >> "$GITIGNORE_DEST"
        echo "!.env.template" >> "$GITIGNORE_DEST"
        echo "!.env.dist" >> "$GITIGNORE_DEST"
        echo ".ai/private-names.txt" >> "$GITIGNORE_DEST"
        echo "# --- AI-OS END ---" >> "$GITIGNORE_DEST"
        echo "  + Merged AI-OS secret rules into existing .gitignore"
    else
        echo "  = Existing .gitignore already contains AI-OS rules"
    fi
else
    cp "$GITIGNORE_SRC" "$GITIGNORE_DEST"
    echo "  + Created .gitignore with AI-OS rules"
fi

mkdir -p "$TARGET_PATH/.ai"
[ ! -f "$TARGET_PATH/.ai/private-names.txt" ] && touch "$TARGET_PATH/.ai/private-names.txt"

echo ""
echo "[2/3] Configuring secret protection and Git hooks..."
cd "$TARGET_PATH"
if [ -d ".git" ]; then
    [ -f ".githooks/pre-commit" ] && chmod +x .githooks/pre-commit 2>/dev/null || true
    
    EXISTING_HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || true)
    if [ -n "$EXISTING_HOOKS_PATH" ] && [ "$EXISTING_HOOKS_PATH" != ".githooks" ]; then
        echo "  ℹ️ Detected existing core.hooksPath='$EXISTING_HOOKS_PATH'."
        echo "     Preserving existing hook path and chaining AI-OS guard..."
        mkdir -p "$EXISTING_HOOKS_PATH"
        TARGET_HOOK="$EXISTING_HOOKS_PATH/pre-commit"
        CHAIN_CMD='[ -f .githooks/pre-commit ] && .githooks/pre-commit "$@"'
        if [ -f "$TARGET_HOOK" ]; then
            if ! grep -F -q ".githooks/pre-commit" "$TARGET_HOOK" 2>/dev/null; then
                echo "" >> "$TARGET_HOOK"
                echo "# AI-OS Pre-Commit Guard Chained Delegation" >> "$TARGET_HOOK"
                echo "$CHAIN_CMD" >> "$TARGET_HOOK"
                chmod +x "$TARGET_HOOK" 2>/dev/null || true
                echo "  + Chained AI-OS guard into $TARGET_HOOK"
            else
                echo "  = AI-OS guard already chained in $TARGET_HOOK"
            fi
        else
            cat << 'EOF' > "$TARGET_HOOK"
#!/usr/bin/env bash
# Chained pre-commit hook delegating to AI-OS guard
[ -f .githooks/pre-commit ] && .githooks/pre-commit "$@"
EOF
            chmod +x "$TARGET_HOOK" 2>/dev/null || true
            echo "  + Created $TARGET_HOOK with AI-OS guard delegation"
        fi
    else
        git config core.hooksPath .githooks
        echo "  + Set core.hooksPath to .githooks"
    fi
fi

echo ""
echo "[3/3] Running doctor diagnostic check..."
DOCTOR_SH="$REPO_ROOT/scripts/doctor.sh"
if [ -f "$DOCTOR_SH" ]; then
    bash "$DOCTOR_SH" "$TARGET_PATH" || true
fi

echo ""
echo "========================================================================"
echo " 🎉 Hey $GIT_USER! AI-OS by Rudra is successfully integrated"
echo "    into your project '$PROJECT_NAME'!"
echo "========================================================================"
echo ""
echo "📌 NEXT STEP: Open '$PROJECT_NAME' in your AI IDE and paste this prompt:"
echo "------------------------------------------------------------------------"
echo "Read AGENTS.md and follow .ai-os/playbooks/codebase-analysis.md to analyze this repository."
echo "Please map our existing codebase, update docs/architecture.md, docs/conventions.md,"
echo "and docs/graph.md with our current components, tech stack, and data flow,"
echo "and conclude with the AI-OS integration greeting and next steps menu."
echo "------------------------------------------------------------------------"
echo ""
