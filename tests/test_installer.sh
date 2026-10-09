#!/usr/bin/env bash
# AI-OS Installer Test Suite (Verifying F3 Fixes & Cross-Platform Parity)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing AI-OS Installer: install.sh & install.ps1"
echo "============================================================"

# --- 1. Bash Installer Tests (install.sh) ---

test_sh_preserves_and_chains_hookspath() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.husky"
    git -C "$sandbox" config core.hooksPath ".husky"
    echo "#!/bin/sh" > "$sandbox/.husky/pre-commit"
    chmod +x "$sandbox/.husky/pre-commit"
    
    # Run install.sh
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    local hookspath
    hookspath=$(git -C "$sandbox" config core.hooksPath)
    local husky_hook
    husky_hook=$(cat "$sandbox/.husky/pre-commit" 2>/dev/null || true)
    cleanup_sandbox "$sandbox"
    
    assert_eq ".husky" "$hookspath" "Existing core.hooksPath must be preserved"
    assert_contains "$husky_hook" ".githooks/pre-commit" "AI-OS guard must be chained into existing husky hook"
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
    
    assert_contains "$gitignore_content" "custom-secret.txt" "Existing .gitignore rules must be preserved"
    assert_contains "$gitignore_content" "# --- AI-OS START ---" "AI-OS marker must be present in .gitignore"
    assert_contains "$gitignore_content" ".env" ".gitignore must include AI-OS environment file ignore rules"
}

test_sh_copies_into_existing_docs_dir() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/docs"
    echo "# Existing Project Doc" > "$sandbox/docs/existing_manual.md"
    
    # Run install.sh
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    local has_existing=0
    local has_architecture=0
    [ -f "$sandbox/docs/existing_manual.md" ] && has_existing=1
    [ -f "$sandbox/docs/architecture.md" ] && has_architecture=1
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$has_existing" "Existing user docs must be preserved"
    assert_eq "1" "$has_architecture" "AI-OS docs/architecture.md must be installed into existing docs/"
}

test_sh_installs_aios_playbooks() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    local has_playbook=0
    local has_prompt=0
    [ -f "$sandbox/.ai-os/playbooks/feature.md" ] && has_playbook=1
    [ -f "$sandbox/.ai-os/prompts/architect.md" ] && has_prompt=1
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$has_playbook" ".ai-os/playbooks/feature.md must be installed downstream"
    assert_eq "1" "$has_prompt" ".ai-os/prompts/architect.md must be installed downstream"
}

# --- 2. PowerShell Installer Tests (install.ps1) ---

test_ps1_copies_into_existing_docs_dir() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/docs"
    echo "# Existing Project Doc" > "$sandbox/docs/existing_manual.md"
    
    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sandbox
        local win_script
        win_sandbox=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        win_script=$(cygpath -w "$REPO_ROOT/scripts/install.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/install.ps1")
        powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sandbox" >/dev/null 2>&1
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

test_ps1_merges_gitignore() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cat << 'EOF' > "$sandbox/.gitignore"
# Custom project ignores
node_modules/
dist/
custom-secret.txt
EOF
    
    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sandbox
        local win_script
        win_sandbox=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        win_script=$(cygpath -w "$REPO_ROOT/scripts/install.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/install.ps1")
        powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sandbox" >/dev/null 2>&1
    else
        echo "powershell.exe not found, skipping ps1 test"
        cleanup_sandbox "$sandbox"
        return 0
    fi
    
    local gitignore_content
    gitignore_content=$(cat "$sandbox/.gitignore" 2>/dev/null || true)
    cleanup_sandbox "$sandbox"
    
    assert_contains "$gitignore_content" "custom-secret.txt" "Existing .gitignore rules must be preserved"
    assert_contains "$gitignore_content" "# --- AI-OS START ---" "AI-OS marker must be present in .gitignore"
    assert_contains "$gitignore_content" ".env" ".gitignore must include AI-OS environment file ignore rules"
}

test_ps1_preserves_and_chains_hookspath() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.husky"
    git -C "$sandbox" config core.hooksPath ".husky"
    echo "#!/bin/sh" > "$sandbox/.husky/pre-commit"
    
    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sandbox
        local win_script
        win_sandbox=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        win_script=$(cygpath -w "$REPO_ROOT/scripts/install.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/install.ps1")
        powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sandbox" >/dev/null 2>&1
    else
        echo "powershell.exe not found, skipping ps1 test"
        cleanup_sandbox "$sandbox"
        return 0
    fi
    
    local hookspath
    hookspath=$(git -C "$sandbox" config core.hooksPath)
    local husky_hook
    husky_hook=$(cat "$sandbox/.husky/pre-commit" 2>/dev/null || true)
    cleanup_sandbox "$sandbox"
    
    assert_eq ".husky" "$hookspath" "install.ps1: Existing core.hooksPath must be preserved"
    assert_contains "$husky_hook" ".githooks/pre-commit" "install.ps1: AI-OS guard must be chained into existing husky hook"
}

# Run installer tests
run_test "install.sh: Preserves and chains existing core.hooksPath" test_sh_preserves_and_chains_hookspath
run_test "install.sh: Merges .gitignore without overwriting" test_sh_merges_gitignore
run_test "install.sh: Installs template docs into existing docs/ dir" test_sh_copies_into_existing_docs_dir
run_test "install.sh: Installs .ai-os/playbooks/ and prompts/" test_sh_installs_aios_playbooks
run_test "install.ps1: Installs template docs into existing docs/ dir" test_ps1_copies_into_existing_docs_dir
run_test "install.ps1: Merges .gitignore without overwriting" test_ps1_merges_gitignore
run_test "install.ps1: Preserves and chains existing core.hooksPath" test_ps1_preserves_and_chains_hookspath

echo ""
echo "Installer Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0
