#!/usr/bin/env bash
# AI Operating System Project Integrator (by Rudra Sharma) - macOS/Linux

set -e

WITH_CLAUDE_HOOKS=false
TARGET_PATH="."
OWNER_HANDLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-claude-hooks)
            WITH_CLAUDE_HOOKS=true
            shift
            ;;
        --owner)
            OWNER_HANDLE="$2"
            shift 2
            ;;
        --owner=*)
            OWNER_HANDLE="${1#*=}"
            shift
            ;;
        *)
            TARGET_PATH="$1"
            shift
            ;;
    esac
done

validate_owner_handle() {
    local h="$1"
    if [[ "$h" =~ ^@[a-zA-Z0-9]([a-zA-Z0-9._-]*)(/[a-zA-Z0-9._-]+)?$ ]]; then
        return 0
    fi
    if [[ "$h" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

DERIVED_FROM_REMOTE=false
if [ -n "$OWNER_HANDLE" ]; then
    if ! validate_owner_handle "$OWNER_HANDLE"; then
        echo "Error: Invalid CODEOWNERS handle '$OWNER_HANDLE'. Must be a GitHub username (@user), team (@org/team), or valid email address." >&2
        exit 1
    fi
else
    REMOTE_URL=$(git -C "$TARGET_PATH" remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE_URL" ]; then
        DERIVED_OWNER=$(echo "$REMOTE_URL" | sed -E -e 's#(https?://[^/]+/|git@[^:]+:|ssh://git@[^/]+/)##' -e 's#/.*##' -e 's#\.git$##')
        if [ -n "$DERIVED_OWNER" ]; then
            if [[ ! "$DERIVED_OWNER" =~ ^@ ]]; then
                CANDIDATE_OWNER="@$DERIVED_OWNER"
            else
                CANDIDATE_OWNER="$DERIVED_OWNER"
            fi
            if validate_owner_handle "$CANDIDATE_OWNER"; then
                OWNER_HANDLE="$CANDIDATE_OWNER"
                DERIVED_FROM_REMOTE=true
                echo ""
                echo "  ℹ️  [AI-OS Installer Notice]: Owner handle derived from origin remote: $OWNER_HANDLE. For organization repositories, replace with @org/team. Verify with: gh api repos/OWNER/REPO/codeowners/errors"
            fi
        fi
    fi
fi

TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd || echo "$TARGET_PATH")"
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
    if [ "$rel_path" = ".github/CODEOWNERS" ]; then
        continue
    fi
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
        {
            echo ""
            echo "# --- AI-OS START ---"
            echo ".env"
            echo ".env.*"
            echo "!.env.example"
            echo "!.env.sample"
            echo "!.env.template"
            echo "!.env.dist"
            echo ".ai/private-names.txt"
            echo ".ai/evidence/"
            echo "# --- AI-OS END ---"
        } >> "$GITIGNORE_DEST"
        echo "  + Merged AI-OS secret rules into existing .gitignore"
    else
        echo "  = Existing .gitignore already contains AI-OS rules"
    fi
else
    cp "$GITIGNORE_SRC" "$GITIGNORE_DEST"
    echo "  + Created .gitignore with AI-OS rules"
fi

# Non-destructive CODEOWNERS configuration
EXISTING_CO=""
for co_loc in "$TARGET_PATH/.github/CODEOWNERS" "$TARGET_PATH/CODEOWNERS" "$TARGET_PATH/docs/CODEOWNERS"; do
    if [ -f "$co_loc" ]; then
        EXISTING_CO="$co_loc"
        break
    fi
done

if [ -n "$EXISTING_CO" ]; then
    if ! grep -q "\.ai/deps-approved\.txt" "$EXISTING_CO" 2>/dev/null; then
        if [ -n "$OWNER_HANDLE" ]; then
            echo ".ai/deps-approved.txt $OWNER_HANDLE" >> "$EXISTING_CO"
            echo "  + Appended .ai/deps-approved.txt to existing $(basename "$EXISTING_CO")"
        else
            echo "  = Preserved existing $(basename "$EXISTING_CO") without unowned pattern (no owner derived)"
        fi
    else
        echo "  = Existing $(basename "$EXISTING_CO") already covers .ai/deps-approved.txt"
    fi
else
    mkdir -p "$TARGET_PATH/.github"
    DEST_CO="$TARGET_PATH/.github/CODEOWNERS"
    SRC_CO="$TEMPLATE_DIR/.github/CODEOWNERS"
    if [ -n "$OWNER_HANDLE" ]; then
        {
            if [ "$DERIVED_FROM_REMOTE" = "true" ]; then
                echo "# owner derived from origin remote; for organization repositories replace with @org/team; verify with: gh api repos/OWNER/REPO/codeowners/errors"
            fi
            while IFS= read -r line || [ -n "$line" ]; do
                if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                    echo "$line"
                else
                    echo "$line $OWNER_HANDLE"
                fi
            done < "$SRC_CO"
        } > "$DEST_CO"
        echo "  + Created .github/CODEOWNERS assigned to $OWNER_HANDLE"
    else
        cat << 'EOF' > "$DEST_CO"
# AI Operating System Code Owners
# Core AI-OS security boundary: requires human CODEOWNER review for rule promotion, hook modification, or harness changes.
# Any pull request modifying these critical infrastructure paths requires an approving review from a human CODEOWNER.
#
# To activate CODEOWNERS protection, add '@your-handle' to each path below:
# AGENTS.md @your-handle
# .ai/rules/ @your-handle
# .githooks/ @your-handle
# scripts/ @your-handle
# .github/workflows/ @your-handle
# .ai/deps-approved.txt @your-handle
EOF
        echo "  + Created .github/CODEOWNERS with comments only (no owner derived)"
    fi
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
                {
                    echo ""
                    echo "# AI-OS Pre-Commit Guard Chained Delegation"
                    echo "$CHAIN_CMD"
                } >> "$TARGET_HOOK"
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

# Step 2.5: Optional Claude Code Hooks (Opt-In)
if [ "$WITH_CLAUDE_HOOKS" = true ]; then
    echo ""
    echo "[2.5/3] Configuring optional Claude Code hooks..."
    mkdir -p "$TARGET_PATH/.claude/hooks"
    HOOKS_SRC="$REPO_ROOT/.ai-os/optional/claude-hooks"
    if [ ! -d "$HOOKS_SRC" ]; then
        HOOKS_SRC="$TEMPLATE_DIR/.ai-os/optional/claude-hooks"
    fi
    if [ -d "$HOOKS_SRC" ]; then
        cp "$HOOKS_SRC"/*.sh "$TARGET_PATH/.claude/hooks/" 2>/dev/null || true
        cp "$HOOKS_SRC"/*.ps1 "$TARGET_PATH/.claude/hooks/" 2>/dev/null || true
        chmod +x "$TARGET_PATH/.claude/hooks"/*.sh 2>/dev/null || true
        cp "$HOOKS_SRC/settings.json" "$TARGET_PATH/.claude/settings.json"
        echo "  + Installed optional Claude Code hooks into .claude/hooks/"
        echo "  + Configured Claude Code settings in .claude/settings.json"
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
