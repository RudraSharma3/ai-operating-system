#!/usr/bin/env bash
# AI-OS Dependabot Cooldown Table Test Suite (doctor.sh & doctor.ps1 Check 24)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

TABLE_FILE="$REPO_ROOT/docs/dependabot-cooldown-keys.json"
DOCUMENTED_ECOSYSTEM_COUNT=34

echo "============================================================"
echo " 🧪 Testing Dependabot Cooldown Table (Doctor Check 24)"
echo "============================================================"

write_dependabot_config() {
    local sandbox="$1" ecosystem="$2" extra_key="$3"
    mkdir -p "$sandbox/.github"
    cat << EOF > "$sandbox/.github/dependabot.yml"
version: 2
updates:
  - package-ecosystem: "$ecosystem"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14
EOF
    if [ -n "$extra_key" ]; then
        echo "      $extra_key: 14" >> "$sandbox/.github/dependabot.yml"
    fi
}

assert_check24() {
    local out="$1" level="$2" detail="$3" label="$4"
    assert_contains "$out" "$level] GitHub Actions workflow" "$label must report $level" || return 1
    if [ -n "$detail" ]; then
        assert_contains "$out" "$detail" "$label must explain: $detail" || return 1
    fi
}

check_ecosystem() {
    local ecosystem="$1" extra_key="$2" level="$3" detail="$4"
    local sandbox out
    sandbox=$(create_sandbox_repo)
    write_dependabot_config "$sandbox" "$ecosystem" "$extra_key"

    out=$("$REPO_ROOT/scripts/doctor.sh" "$sandbox" 2>&1) || true
    assert_check24 "$out" "$level" "$detail" "doctor.sh on '$ecosystem'" || { cleanup_sandbox "$sandbox"; return 1; }

    if command -v powershell.exe >/dev/null 2>&1; then
        local win_sb win_doc
        win_sb=$(cygpath -w "$sandbox" 2>/dev/null || echo "$sandbox")
        win_doc=$(cygpath -w "$REPO_ROOT/scripts/doctor.ps1" 2>/dev/null || echo "$REPO_ROOT/scripts/doctor.ps1")
        out=$(powershell.exe -ExecutionPolicy Bypass -File "$win_doc" -ProjectPath "$win_sb" 2>&1) || true
        assert_check24 "$out" "$level" "$detail" "doctor.ps1 on '$ecosystem'" || { cleanup_sandbox "$sandbox"; return 1; }
    fi
    cleanup_sandbox "$sandbox"
}

test_table_matches_documented_ecosystem_count() {
    local count
    count=$(grep -cE '^    "[a-z-]+": \[' "$TABLE_FILE")
    assert_eq "$DOCUMENTED_ECOSYSTEM_COUNT" "$count" "Cooldown table must list every documented package-ecosystem value"
}

test_apm_accepts_semver_keys() {
    check_ecosystem "apm" "semver-major-days" "PASS" ""
}

test_mix_accepts_semver_keys() {
    check_ecosystem "mix" "semver-minor-days" "PASS" ""
}

test_nix_accepts_default_days() {
    check_ecosystem "nix" "" "PASS" ""
}

test_nix_rejects_semver_keys() {
    check_ecosystem "nix" "semver-major-days" "FAIL" "unsupported cooldown key 'semver-major-days' for package ecosystem 'nix'"
}

test_hex_is_unknown_yaml_value() {
    check_ecosystem "hex" "" "WARN" "unknown package ecosystem 'hex'"
}

test_nix_flakes_is_unknown_yaml_value() {
    check_ecosystem "nix-flakes" "" "WARN" "unknown package ecosystem 'nix-flakes'"
}

run_test "cooldown table: Lists all $DOCUMENTED_ECOSYSTEM_COUNT documented ecosystems" test_table_matches_documented_ecosystem_count
run_test "doctor: apm accepts semver cooldown keys" test_apm_accepts_semver_keys
run_test "doctor: mix accepts semver cooldown keys" test_mix_accepts_semver_keys
run_test "doctor: nix accepts default-days" test_nix_accepts_default_days
run_test "doctor: nix rejects semver cooldown keys" test_nix_rejects_semver_keys
run_test "doctor: hex is reported as an unknown YAML value" test_hex_is_unknown_yaml_value
run_test "doctor: nix-flakes is reported as an unknown YAML value" test_nix_flakes_is_unknown_yaml_value

echo "------------------------------------------------------------"
echo "Dependabot Cooldown Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
echo "------------------------------------------------------------"

[ "$FAILED_TESTS" -eq 0 ]
