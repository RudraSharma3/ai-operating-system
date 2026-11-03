#!/usr/bin/env bash
# AI-OS CODEOWNERS Owner Validation Test Suite (install.sh & install.ps1)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing AI-OS Installer Owner Validation"
echo "============================================================"

VALID_OWNERS=("@alice" "@my-org/team" "user@example.com")
INVALID_OWNERS=("alice" "@" "@org/team/extra" "bad!user" "invalid owner with spaces" "@-alice")

test_sh_owner_validation() {
    local sandbox owner status out
    sandbox=$(create_sandbox_repo)
    for owner in "${VALID_OWNERS[@]}"; do
        rm -rf "$sandbox/.github"
        status=0
        out=$("$REPO_ROOT/scripts/install.sh" "$sandbox" --owner "$owner" 2>&1) || status=$?
        assert_eq 0 "$status" "install.sh must accept '$owner'" || { echo "$out"; cleanup_sandbox "$sandbox"; return 1; }
        assert_contains "$(cat "$sandbox/.github/CODEOWNERS")" "AGENTS.md $owner" "CODEOWNERS must assign '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
    done
    for owner in "${INVALID_OWNERS[@]}"; do
        status=0
        out=$("$REPO_ROOT/scripts/install.sh" "$sandbox" --owner "$owner" 2>&1) || status=$?
        assert_eq 1 "$status" "install.sh must reject '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
        assert_contains "$out" "Invalid CODEOWNERS handle" "install.sh must explain rejection of '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
    done
    cleanup_sandbox "$sandbox"
}

test_sh_git_user_name_never_becomes_owner() {
    local sandbox out
    sandbox=$(create_sandbox_repo)
    git -C "$sandbox" config user.name "mallory"
    out=$("$REPO_ROOT/scripts/install.sh" "$sandbox" 2>&1)
    assert_not_contains "$(cat "$sandbox/.github/CODEOWNERS")" "@mallory" "git config user.name must not be used as a CODEOWNERS owner" || { echo "$out"; cleanup_sandbox "$sandbox"; return 1; }
    assert_contains "$out" "comments only (no owner derived)" "install.sh must report that no owner was derived" || { cleanup_sandbox "$sandbox"; return 1; }
    cleanup_sandbox "$sandbox"
}

test_ps1_owner_validation() {
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "SKIP: powershell.exe not available"
        return 0
    fi
    local sandbox win_sb win_script owner status out
    sandbox=$(create_sandbox_repo)
    win_sb=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
    win_script=$(cygpath -w "$REPO_ROOT/scripts/install.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/install.ps1")
    for owner in "${VALID_OWNERS[@]}"; do
        rm -rf "$sandbox/.github"
        status=0
        out=$(powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sb" -Owner "$owner" 2>&1) || status=$?
        assert_eq 0 "$status" "install.ps1 must accept '$owner'" || { echo "$out"; cleanup_sandbox "$sandbox"; return 1; }
        assert_contains "$(cat "$sandbox/.github/CODEOWNERS")" "AGENTS.md $owner" "CODEOWNERS must assign '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
    done
    for owner in "${INVALID_OWNERS[@]}"; do
        status=0
        out=$(powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sb" -Owner "$owner" 2>&1) || status=$?
        assert_eq 1 "$status" "install.ps1 must reject '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
        assert_contains "$out" "Invalid CODEOWNERS handle" "install.ps1 must explain rejection of '$owner'" || { cleanup_sandbox "$sandbox"; return 1; }
    done
    cleanup_sandbox "$sandbox"
}

test_ps1_git_user_name_never_becomes_owner() {
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "SKIP: powershell.exe not available"
        return 0
    fi
    local sandbox win_sb win_script out
    sandbox=$(create_sandbox_repo)
    git -C "$sandbox" config user.name "mallory"
    win_sb=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
    win_script=$(cygpath -w "$REPO_ROOT/scripts/install.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/install.ps1")
    out=$(powershell.exe -ExecutionPolicy Bypass -File "$win_script" -TargetPath "$win_sb" 2>&1)
    assert_not_contains "$(cat "$sandbox/.github/CODEOWNERS")" "@mallory" "git config user.name must not be used as a CODEOWNERS owner" || { echo "$out"; cleanup_sandbox "$sandbox"; return 1; }
    cleanup_sandbox "$sandbox"
}

run_test "install.sh: --owner accepts @user, @org/team, email and rejects all else" test_sh_owner_validation
run_test "install.sh: git config user.name is never used as owner" test_sh_git_user_name_never_becomes_owner
run_test "install.ps1: -Owner accepts @user, @org/team, email and rejects all else" test_ps1_owner_validation
run_test "install.ps1: git config user.name is never used as owner" test_ps1_git_user_name_never_becomes_owner

echo "------------------------------------------------------------"
echo "Owner Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
echo "------------------------------------------------------------"

[ "$FAILED_TESTS" -eq 0 ]
