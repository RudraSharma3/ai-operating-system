#!/usr/bin/env bash
# AI-OS Installer Test Suite (Reproducing F3 Findings)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing AI-OS Installer: install.sh & install.ps1"
echo "============================================================"

test_sh_preserves_existing_hookspath() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    # Simulate an existing Husky setup
    git -C "$sandbox" config core.hooksPath ".husky"
    
    # Run install.sh
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    local hookspath
    hookspath=$(git -C "$sandbox" config core.hooksPath)
    cleanup_sandbox "$sandbox"
    
    # In the flawed install.sh, hookspath is silently overwritten to '.githooks'
    assert_eq ".husky" "$hookspath" "Existing core.hooksPath (.husky) must be preserved or chained, not overwritten to .githooks"
}

test_sh_merges_gitignore() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cat << 'EOF' > "$sandbox/.gitignore"
# Custom project ignores
node_modules/
dist/
custom-secret.txt
EOF
    
    # Run install.sh
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    local gitignore_content
    gitignore_content=$(cat "$sandbox/.gitignore" 2>/dev/null || true)
    cleanup_sandbox "$sandbox"
    
    # Must preserve custom ignores and include AI-OS .env ignores
    assert_contains "$gitignore_content" "custom-secret.txt" "Existing .gitignore rules must be preserved"
    assert_contains "$gitignore_content" ".env" ".gitignore must include AI-OS environment file ignore rules"
}

test_ps1_copies_into_existing_docs_dir() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/docs"
    echo "# Existing Project Doc" > "$sandbox/docs/existing_manual.md"
    
    # Run install.ps1 via powershell if available
    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sandbox
        win_sandbox=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        powershell.exe -ExecutionPolicy Bypass -File "$REPO_ROOT/scripts/install.ps1" -TargetPath "$win_sandbox" >/dev/null 2>&1
    else
        echo "powershell.exe not found, skipping ps1 test"
        cleanup_sandbox "$sandbox"
        return 0
    fi
    
    local has_existing=0
    local has_architecture=0
    [ -f "$sandbox/docs/existing_manual.md" ] && has_existing=1
    [ -f "$sandbox/docs/architecture.md" ] && has_architecture=1
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$has_existing" "Existing user docs must be preserved"
    assert_eq "1" "$has_architecture" "install.ps1 must copy template docs/ into existing docs/ folder"
}

# Run installer tests
run_test "F3 (install.sh): Preserves existing core.hooksPath" test_sh_preserves_existing_hookspath
run_test "F3 (install.sh): Merges .gitignore without overwriting" test_sh_merges_gitignore
run_test "F3 (install.ps1): Installs template docs into existing docs/ dir" test_ps1_copies_into_existing_docs_dir

echo ""
echo "Installer Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0
