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

test_sh_upgrade_preserves_customizations() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    # 1. Install fresh AI-OS into sandbox
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    # 2. Modify one file to simulate customization (e.g. AGENTS.md)
    echo "## Custom User Rule" >> "$sandbox/AGENTS.md"
    
    # 3. Run upgrade.sh
    "$REPO_ROOT/scripts/upgrade.sh" --target "$sandbox" >/dev/null 2>&1
    
    local customized_content
    customized_content=$(cat "$sandbox/AGENTS.md")
    local manifest_exists=false
    [ -f "$sandbox/.ai-os/manifest.json" ] && manifest_exists=true
    cleanup_sandbox "$sandbox"
    
    assert_contains "$customized_content" "Custom User Rule" "upgrade.sh must preserve locally customized files"
    assert_eq "true" "$manifest_exists" "upgrade.sh must create/update .ai-os/manifest.json"
}

test_template_drift_check() {
    local output
    output=$("$REPO_ROOT/scripts/build-templates.sh" --check 2>&1)
    local ret=$?
    if [ "$ret" -ne 0 ]; then
        echo "$output" >&2
    fi
    assert_eq "0" "$ret" "build-templates.sh --check must verify zero drift between master and templates"
}

test_rule_compiler_check() {
    "$REPO_ROOT/scripts/compile-rules.sh" --check >/dev/null 2>&1
    local ret=$?
    assert_eq "0" "$ret" "compile-rules.sh --check must verify rules in AGENTS.md match .ai/rules/"
}

test_compile_rules_monorepo() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/packages/pkg-a/.ai/rules" "$sandbox/packages/pkg-b/.ai/rules"
    
    cat << 'EOF' > "$sandbox/packages/pkg-a/AGENTS.md"
# Package A
## Learned Rules
<!-- rules below -->
EOF
    cat << 'EOF' > "$sandbox/packages/pkg-b/AGENTS.md"
# Package B
## Learned Rules
<!-- rules below -->
EOF

    echo "20261026-01. [CODE] Use bun in Package A — package convention." > "$sandbox/packages/pkg-a/.ai/rules/01-bun.md"
    echo "20261026-02. [CODE] Use pnpm in Package B — package convention." > "$sandbox/packages/pkg-b/.ai/rules/01-pnpm.md"

    "$REPO_ROOT/scripts/compile-rules.sh" --project "$sandbox" --recursive >/dev/null 2>&1
    local ret=$?

    local pkg_a_content pkg_b_content
    pkg_a_content=$(cat "$sandbox/packages/pkg-a/AGENTS.md")
    pkg_b_content=$(cat "$sandbox/packages/pkg-b/AGENTS.md")
    cleanup_sandbox "$sandbox"

    assert_eq "0" "$ret" "compile-rules.sh --recursive must successfully compile nested monorepo packages"
    assert_contains "$pkg_a_content" "20261026-01. [CODE] Use bun in Package A" "Package A AGENTS.md must compile its scoped rule"
    assert_contains "$pkg_b_content" "20261026-02. [CODE] Use pnpm in Package B" "Package B AGENTS.md must compile its scoped rule"
}

test_upgrade_conflict_preserves_both() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    
    # User modifies an installed playbook
    local user_file="$sandbox/.ai-os/playbooks/review.md"
    echo "## Custom User Review Step" >> "$user_file"

    # Run upgrade
    local upgrade_output
    upgrade_output=$("$REPO_ROOT/scripts/upgrade.sh" --target "$sandbox" 2>&1)
    
    local user_content has_update_file=false
    user_content=$(cat "$user_file")
    [ -f "$user_file.ai-os-update" ] && has_update_file=true
    cleanup_sandbox "$sandbox"

    assert_contains "$user_content" "Custom User Review Step" "upgrade.sh must preserve user-modified file without data loss"
    assert_eq "true" "$has_update_file" "upgrade.sh must write upstream copy to .ai-os-update side-by-side"
    assert_contains "$upgrade_output" "Preserved customized" "upgrade.sh must output clear conflict/preserved message"
}

test_doctor_private_names_denylist() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1

    # Put a private name into tracked file
    echo "This is confidential_client_project_xyz internal" > "$sandbox/internal.txt"
    git -C "$sandbox" add internal.txt
    git -C "$sandbox" commit -qm "add internal file"

    # Add deny-list rule
    echo "confidential_client_project_xyz" > "$sandbox/.ai/private-names.txt"

    # Run doctor --ci
    local doc_output doc_status=0
    doc_output=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || doc_status=$?

    cleanup_sandbox "$sandbox"
    assert_eq 1 "$doc_status" "doctor.sh must fail when tracked files match .ai/private-names.txt"
    assert_contains "$doc_output" "private deny-listed names" "doctor.sh output must cite private deny-listed names check"
}

test_upgrade_legacy_pre_manifest() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    # Simulate a pre-manifest install: install files present, but no .ai-os/manifest.json
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    rm -rf "$sandbox/.ai-os/manifest.json"

    # Add custom user content to an existing file
    echo "# Custom User Legacy Architecture Notes" >> "$sandbox/docs/architecture.md"

    # Run upgrade.sh
    local upgrade_output upgrade_status=0
    upgrade_output=$("$REPO_ROOT/scripts/upgrade.sh" --target "$sandbox" 2>&1) || upgrade_status=$?

    local manifest_created=false
    [ -f "$sandbox/.ai-os/manifest.json" ] && manifest_created=true
    local content_after=""
    [ -f "$sandbox/docs/architecture.md" ] && content_after=$(cat "$sandbox/docs/architecture.md")

    cleanup_sandbox "$sandbox"

    assert_eq 0 "$upgrade_status" "upgrade.sh must succeed on legacy pre-manifest install"
    assert_contains "$upgrade_output" "pre-manifest legacy install detected" "upgrade.sh must output clear message when no manifest exists"
    assert_eq "true" "$manifest_created" "upgrade.sh must create .ai-os/manifest.json afterwards"
    assert_contains "$content_after" "Custom User Legacy Architecture Notes" "upgrade.sh must preserve existing files without data loss"
}

test_claude_hooks_opt_in_install() {
    local sandbox
    sandbox=$(create_sandbox_repo)

    # 1. Default install (without flag)
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1
    local default_has_hooks=false
    [ -f "$sandbox/.claude/settings.json" ] && default_has_hooks=true
    local doc_default_out
    doc_default_out=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || true

    # 2. Opt-in install with --with-claude-hooks
    "$REPO_ROOT/scripts/install.sh" --with-claude-hooks "$sandbox" >/dev/null 2>&1
    local optin_has_hooks=false
    [ -f "$sandbox/.claude/settings.json" ] && [ -f "$sandbox/.claude/hooks/pre-tool-use.sh" ] && optin_has_hooks=true
    local doc_optin_out
    doc_optin_out=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || true

    cleanup_sandbox "$sandbox"

    assert_eq "false" "$default_has_hooks" "install.sh without flag must not install .claude/settings.json"
    assert_contains "$doc_default_out" "Optional Claude Code hooks status" "doctor Check 21 runs on clean install"
    assert_eq "true" "$optin_has_hooks" "install.sh --with-claude-hooks must provision .claude/hooks and settings.json"
    assert_contains "$doc_optin_out" "Opt-in Claude Code hooks are active" "doctor Check 21 reports WARN when hooks are installed"
}

test_doctor_mcp_playbook_matching_and_pinning() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1

    local pb_file="$sandbox/.ai-os/playbooks/multi-agent-orchestration.md"
    [ ! -f "$pb_file" ] && pb_file="$sandbox/playbooks/multi-agent-orchestration.md"
    local mcp_file="$sandbox/mcp.json"

    # Backup clean playbook and mcp.json
    cp "$pb_file" "$pb_file.bak"
    cp "$mcp_file" "$mcp_file.bak"

    # 1. Test failure when playbook declares a tool missing from mcp.json
    echo "- **\`missing_worker_tool\`**: Missing tool test" >> "$pb_file"
    local doc_out_missing doc_status_missing=0
    doc_out_missing=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || doc_status_missing=$?
    assert_eq 1 "$doc_status_missing" "doctor.sh must fail when a playbook tool is missing from mcp.json"
    assert_contains "$doc_out_missing" "missing_worker_tool" "doctor.sh must report missing tool name"

    # Restore playbook
    cp "$pb_file.bak" "$pb_file"

    # 2. Test failure when a server in mcp.json has unpinned version
    cat << 'EOF' > "$mcp_file"
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem@latest", "./"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory@2.0.0"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git==2026.10.19", "--repository", "./"]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch==2026.10.24"]
    }
  }
}
EOF
    local doc_out_unpinned doc_status_unpinned=0
    doc_out_unpinned=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || doc_status_unpinned=$?

    # 3. Test success when all servers are pinned and tools match
    cp "$mcp_file.bak" "$mcp_file"
    local doc_out_clean doc_status_clean=0
    doc_out_clean=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || doc_status_clean=$?

    cleanup_sandbox "$sandbox"

    assert_eq 1 "$doc_status_unpinned" "doctor.sh must fail when an MCP server version is unpinned"
    assert_contains "$doc_out_unpinned" "unpinned" "doctor.sh must report unpinned server version in mcp.json"
    assert_eq 0 "$doc_status_clean" "doctor.sh must pass when all MCP servers are pinned and match playbook"
}

test_doctor_headless_command_verification() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    "$REPO_ROOT/scripts/install.sh" "$sandbox" >/dev/null 2>&1

    mkdir -p "$sandbox/docs"
    # Create sources.md with verified headless commands
    cat << 'EOF' > "$sandbox/docs/sources.md"
# Sources
## 5. Claude Code CLI Headless Mode Flags
- Verified Headless Command Strings:
  - `claude -p`
  - `claude --print`
EOF

    # 1. Test warning when doc contains unverified headless command
    echo 'Run: `claude --non-interactive -p`' > "$sandbox/docs/eval-guide.md"
    local doc_out_warn
    doc_out_warn=$("$REPO_ROOT/scripts/doctor.sh" "$sandbox" 2>&1) || true

    # 2. Test pass when doc contains verified headless command
    echo 'Run: `claude -p`' > "$sandbox/docs/eval-guide.md"
    local doc_out_pass
    doc_out_pass=$("$REPO_ROOT/scripts/doctor.sh" "$sandbox" 2>&1) || true

    cleanup_sandbox "$sandbox"

    assert_contains "$doc_out_warn" "WARN] Headless agent command documentation" "doctor.sh must warn when unverified headless command is in docs" || return 1
    assert_contains "$doc_out_warn" "claude --non-interactive" "doctor.sh must identify unverified command" || return 1
    assert_contains "$doc_out_pass" "PASS] Headless agent command documentation" "doctor.sh must pass when headless command matches verified sources" || return 1
}

# Run installer tests
run_test "install.sh: Preserves and chains existing core.hooksPath" test_sh_preserves_and_chains_hookspath
run_test "install.sh: Merges .gitignore without overwriting" test_sh_merges_gitignore
run_test "install.sh: Installs template docs into existing docs/ dir" test_sh_copies_into_existing_docs_dir
run_test "install.sh: Installs .ai-os/playbooks/ and prompts/" test_sh_installs_aios_playbooks
run_test "install.sh: Installs Claude Code hooks only when --with-claude-hooks is specified" test_claude_hooks_opt_in_install
run_test "install.ps1: Installs template docs into existing docs/ dir" test_ps1_copies_into_existing_docs_dir
run_test "install.ps1: Merges .gitignore without overwriting" test_ps1_merges_gitignore
run_test "install.ps1: Preserves and chains existing core.hooksPath" test_ps1_preserves_and_chains_hookspath
run_test "upgrade.sh: Upgrades template and preserves customizations" test_sh_upgrade_preserves_customizations
run_test "upgrade.sh: Preserves customized file on conflict with side-by-side update" test_upgrade_conflict_preserves_both
run_test "upgrade.sh: Upgrades legacy pre-manifest install without data loss" test_upgrade_legacy_pre_manifest
run_test "build-templates.sh: Zero drift between master and templates" test_template_drift_check
run_test "compile-rules.sh: Rules in AGENTS.md match .ai/rules/" test_rule_compiler_check
run_test "compile-rules.sh: Compiles nested packages in a monorepo" test_compile_rules_monorepo
run_test "doctor.sh: Enforces .ai/private-names.txt deny-list check" test_doctor_private_names_denylist
run_test "doctor.sh: Enforces MCP playbook matching and pinned versions" test_doctor_mcp_playbook_matching_and_pinning
run_test "doctor.sh: Warns if docs contain headless command not listed in docs/sources.md" test_doctor_headless_command_verification

echo ""
echo "Installer Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0


