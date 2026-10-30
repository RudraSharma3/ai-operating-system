#!/usr/bin/env bash
# Test Doctor Check 26 unowned pattern line detection

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/test_helpers.sh"

test_doctor_check26_unowned_pattern_fails() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1

    mkdir -p "$sandbox/.ai" "$sandbox/.github"
    touch "$sandbox/.ai/deps-approved.txt"
    # Create CODEOWNERS with an unowned pattern line
    cat << 'EOF' > "$sandbox/.github/CODEOWNERS"
# Unowned pattern
/src/
.ai/deps-approved.txt @alice
EOF

    # In sandbox repo, an unowned pattern line must produce WARN and flag unowned pattern
    local doc_out doc_status=0
    doc_out=$("$REPO_ROOT/scripts/doctor.sh" --ci "$sandbox" 2>&1) || doc_status=$?
    assert_contains "$doc_out" "unowned pattern line" "doctor.sh must flag unowned pattern line" || return 1

    # In PowerShell
    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sb win_doc
        win_sb=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        win_doc=$(cygpath -w "$REPO_ROOT/scripts/doctor.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/doctor.ps1")
        local doc_ps1_out
        doc_ps1_out=$(powershell.exe -ExecutionPolicy Bypass -File "$win_doc" -Ci -ProjectPath "$win_sb" 2>&1) || true
        assert_contains "$doc_ps1_out" "unowned pattern line" "doctor.ps1 must flag unowned pattern line" || return 1
    fi

    cleanup_sandbox "$sandbox"
}

run_test "doctor: Unowned pattern in CODEOWNERS is flagged" test_doctor_check26_unowned_pattern_fails
