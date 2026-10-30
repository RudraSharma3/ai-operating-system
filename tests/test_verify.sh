#!/usr/bin/env bash
# AI-OS Verification Layer Unit & Integration Tests
# Asserts that scripts/ai_os_verify.py and its wrappers enforce dependencies, imports, and evidence.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "============================================================"
echo " 🧪 Testing AI-OS Verifier Layer: ai_os_verify.py & wrappers"
echo "============================================================"

VERIFIER_PY="$REPO_ROOT/scripts/ai_os_verify.py"
VERIFIER_SH="$REPO_ROOT/scripts/ai-os-verify.sh"
VERIFIER_PS1="$REPO_ROOT/scripts/ai-os-verify.ps1"
RUN_SH="$REPO_ROOT/scripts/ai-os-run"
RUN_PS1="$REPO_ROOT/scripts/ai-os-run.ps1"

test_approved_dep_passes() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "python|requests|HTTP library|2026-10-29|@tester" > .ai/deps-approved.txt
    echo "requests==2.31.0" > requirements.txt
    git add .ai/deps-approved.txt requirements.txt
    git commit -q -m "initial commit with approved dep"

    # Add another approved dep
    echo "npm|express|Web framework|2026-10-29|@tester" >> .ai/deps-approved.txt
    cat << 'EOF' > package.json
{
  "name": "test-pkg",
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF
    git add .ai/deps-approved.txt package.json

    local status=0
    python3 "$VERIFIER_PY" deps --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Approved dependencies must PASS deps check"
}

test_unapproved_dep_fails() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    touch .ai/deps-approved.txt
    git add .ai/deps-approved.txt
    git commit -q -m "empty initial commit"

    # Add unapproved package to requirements.txt
    echo "phantom-malicious-pkg==1.0.0" > requirements.txt
    git add requirements.txt

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" deps --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: Unapproved dependency must exit non-zero" >&2
        return 1
    fi
    assert_contains "$output" "Unapproved dependency" "Must report unapproved dependency"
    assert_contains "$output" "phantom-malicious-pkg" "Must name the unapproved dependency"
    assert_contains "$output" "deps-approved.txt" "Must instruct how to approve in .ai/deps-approved.txt"
}

test_removal_of_dep_passes() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "python|requests|HTTP|2026-10-29|@tester" > .ai/deps-approved.txt
    echo "requests==2.31.0" > requirements.txt
    echo "flask==3.0.0" >> requirements.txt
    echo "python|flask|Web|2026-10-29|@tester" >> .ai/deps-approved.txt
    git add .ai/deps-approved.txt requirements.txt
    git commit -q -m "initial commit"

    # Remove flask
    echo "requests==2.31.0" > requirements.txt
    git add requirements.txt

    local status=0
    python3 "$VERIFIER_PY" deps --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Removing a dependency must PASS deps check"
}

test_undeclared_python_import_flagged() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "python|requests|HTTP|2026-10-29|@tester" > .ai/deps-approved.txt
    echo "requests==2.31.0" > requirements.txt
    git add .ai/deps-approved.txt requirements.txt
    git commit -q -m "initial commit"

    # Create Python file with undeclared import
    cat << 'EOF' > app.py
import sys
import os
import requests
import phantom_unknown_module
print("hello")
EOF
    git add app.py

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" imports --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: Undeclared Python import must exit non-zero" >&2
        return 1
    fi
    assert_contains "$output" "phantom_unknown_module" "Must report undeclared Python import"
}

test_undeclared_js_import_flagged() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "npm|express|Web|2026-10-29|@tester" > .ai/deps-approved.txt
    cat << 'EOF' > package.json
{
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF
    git add .ai/deps-approved.txt package.json
    git commit -q -m "initial commit"

    # Create JS file importing unlisted package
    cat << 'EOF' > server.js
const fs = require('fs');
const path = require('path');
const express = require('express');
const axios = require('axios'); // undeclared!
EOF
    git add server.js

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" imports --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: Undeclared JS import must exit non-zero" >&2
        return 1
    fi
    assert_contains "$output" "axios" "Must report undeclared JS package"
}

test_import_aliases_handled() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "python|pyyaml|YAML parser|2026-10-29|@tester" > .ai/deps-approved.txt
    echo "python|pillow|Image library|2026-10-29|@tester" >> .ai/deps-approved.txt
    echo "python-dotenv" >> requirements.txt
    echo "pyyaml==6.0" >> requirements.txt
    echo "pillow==10.0" >> requirements.txt
    git add .ai/deps-approved.txt requirements.txt
    git commit -q -m "initial commit"

    # Python code uses import yaml, PIL, dotenv
    cat << 'EOF' > app.py
import yaml
from PIL import Image
import dotenv
EOF
    git add app.py

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Common import aliases (yaml, PIL, dotenv) must resolve to their package names"
}

test_stdlib_builtins_and_relative_ignored() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai src/subpkg
    touch requirements.txt package.json .ai/deps-approved.txt
    git add requirements.txt package.json .ai/deps-approved.txt
    git commit -q -m "initial commit"

    cat << 'EOF' > src/subpkg/helper.py
def help_me():
    return 42
EOF
    cat << 'EOF' > src/main.py
import sys
import os
import json
import ast
import typing
from .subpkg import helper
EOF
    cat << 'EOF' > index.js
const fs = require('fs');
const path = require('node:path');
const crypto = require('crypto');
const helper = require('./src/helper.js');
EOF
    git add src/ index.js

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Stdlib, Node builtins, and relative imports must pass without warning"
}

test_malformed_manifest_handled_gracefully() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    touch .ai/deps-approved.txt
    echo "not valid json {{{ ::::" > package.json
    git add .ai/deps-approved.txt package.json
    git commit -q -m "initial commit"

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" deps --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    # Should report error gracefully without python unhandled traceback
    if echo "$output" | grep -qi "Traceback (most recent call last)"; then
        echo "ASSERTION FAILED: Malformed manifest must not trigger raw Python crash traceback" >&2
        return 1
    fi
    assert_contains "$output" "package.json" "Must mention malformed file gracefully"
}

test_offline_policy_refuses_network_in_default_paths() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "python|requests|HTTP|2026-10-29|@tester" > .ai/deps-approved.txt
    touch requirements.txt
    git add .ai/deps-approved.txt requirements.txt
    git commit -q -m "initial commit"

    # Running registry-check without --online must refuse to execute
    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" registry-check --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: registry-check without --online must fail" >&2
        return 1
    fi
    assert_contains "$output" "--online" "Must require explicit --online flag"
}

test_evidence_run_and_require() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    touch file.txt
    git add file.txt
    git commit -q -m "clean commit"

    # Run command through ai_os_verify.py run
    local status=0
    python3 "$VERIFIER_PY" run --target "$sandbox" -- echo "test run successful" || status=$?
    assert_eq "0" "$status" "ai_os_verify.py run must return the command exit code"

    # Verify evidence file created in .ai/evidence/
    local count
    count=$(find "$sandbox/.ai/evidence" -type f -name "*.json" | wc -l)
    if [ "$count" -lt 1 ]; then
        echo "ASSERTION FAILED: ai_os_verify.py run must record evidence json" >&2
        cleanup_sandbox "$sandbox"
        return 1
    fi

    # Require evidence for command pattern
    python3 "$VERIFIER_PY" evidence --target "$sandbox" --require "echo" || status=$?
    if [ "$status" -ne 0 ]; then
        echo "ASSERTION FAILED: evidence --require must exit 0 for matching clean HEAD command" >&2
        cleanup_sandbox "$sandbox"
        return 1
    fi

    # Stale test: create uncommitted file change
    echo "dirty" > file.txt
    status=0
    python3 "$VERIFIER_PY" evidence --target "$sandbox" --require "echo" >/dev/null 2>&1 || status=$?
    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: evidence --require must reject stale evidence after working tree modified" >&2
        cleanup_sandbox "$sandbox"
        return 1
    fi

    cleanup_sandbox "$sandbox"
    return 0
}

test_bash_and_powershell_wrappers() {
    if [ ! -f "$VERIFIER_SH" ] || [ ! -x "$VERIFIER_SH" ]; then
        echo "ASSERTION FAILED: $VERIFIER_SH must exist and be executable" >&2
        return 1
    fi
    if [ ! -f "$VERIFIER_PS1" ]; then
        echo "ASSERTION FAILED: $VERIFIER_PS1 must exist" >&2
        return 1
    fi
    if [ ! -f "$RUN_SH" ] || [ ! -x "$RUN_SH" ]; then
        echo "ASSERTION FAILED: $RUN_SH must exist and be executable" >&2
        return 1
    fi
    if [ ! -f "$RUN_PS1" ]; then
        echo "ASSERTION FAILED: $RUN_PS1 must exist" >&2
        return 1
    fi
    return 0
}

test_imports_namespace_package() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    echo "google-genai==0.1.0" > requirements.txt
    cat << 'EOF' > app.py
from google import genai
import google
EOF
    git add requirements.txt app.py
    git commit -q -m "namespace pkg setup"

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Namespace package (google from google-genai) must resolve without undeclared import error"
}

test_imports_src_layout() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p src/my_pkg tests
    touch src/my_pkg/__init__.py
    echo "def get_data(): return 123" > src/my_pkg/core.py
    cat << 'EOF' > tests/test_core.py
from my_pkg import core
assert core.get_data() == 123
EOF
    git add src tests
    git commit -q -m "src layout setup"

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Src-layout internal modules (src/my_pkg) must resolve as internal packages"
}

test_imports_tsconfig_paths() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    cat << 'EOF' > package.json
{
  "name": "my-app"
}
EOF
    cat << 'EOF' > tsconfig.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@components/*": ["components/*"]
    }
  }
}
EOF
    mkdir -p components
    echo "export const Button = () => null;" > components/Button.tsx
    cat << 'EOF' > App.tsx
import { Button } from '@components/Button';
export function App() { return null; }
EOF
    git add package.json tsconfig.json components App.tsx
    git commit -q -m "tsconfig paths setup"

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "tsconfig path alias imports (@components/*) must not be flagged as external npm packages"
}

test_imports_optional_conditional() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    touch requirements.txt
    cat << 'EOF' > app.py
try:
    import optional_accelerator
except ImportError:
    optional_accelerator = None
EOF
    git add requirements.txt app.py
    git commit -q -m "optional conditional import setup"

    local status=0
    python3 "$VERIFIER_PY" imports --target "$sandbox" || status=$?
    cleanup_sandbox "$sandbox"
    assert_eq "0" "$status" "Imports guarded by try/except ImportError must be treated as optional"
}

test_registry_check_offline_fixture_flags() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1
    mkdir -p .ai
    # Define packages:
    # 1. requests (real package, but mock says published yesterday -> must trigger age-under-14-days)
    # 2. definitely-nonexistent-xyz-987 (mock says 404 -> nonexistent package error)
    # 3. reqeusts (close edit distance to requests -> typosquat heuristic alert)
    cat << 'EOF' > .ai/deps-approved.txt
python|requests|HTTP library|2026-10-29|@tester
python|definitely-nonexistent-xyz-987|Missing library|2026-10-29|@tester
python|reqeusts|Typo library|2026-10-29|@tester
EOF
    cat << 'EOF' > "$sandbox/mock_registry.json"
{
  "python:requests": {
    "publish_date": "2026-10-28",
    "exists": true
  },
  "python:definitely-nonexistent-xyz-987": {
    "exists": false,
    "error": "HTTP 404: package not found"
  },
  "python:reqeusts": {
    "publish_date": "2020-01-01",
    "exists": true
  }
}
EOF
    git add .ai/deps-approved.txt
    git commit -q -m "deps setup for registry check"

    local output
    local status=0
    output=$(AI_OS_REGISTRY_MOCK_FILE="$sandbox/mock_registry.json" python3 "$VERIFIER_PY" registry-check --online --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    # Nonexistent package must cause exit code 1
    if [ "$status" -eq 0 ]; then
        echo "ASSERTION FAILED: registry-check with nonexistent package must exit non-zero" >&2
        return 1
    fi
    assert_contains "$output" "requests: age" "Must inspect requests" || return 1
    assert_contains "$output" "Package is younger than 14-day threshold" "Must flag requests as younger than 14 days from mock fixture" || return 1
    assert_contains "$output" "HTTP 404" "Must flag nonexistent package error from mock fixture" || return 1
    assert_contains "$output" "Heuristic: Potential typosquat" "Must flag edit-distance typosquat heuristic" || return 1
    assert_contains "$output" "requests" "Must identify close popular package requests" || return 1
}

test_deps_approvals_changed_warn_notice() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1

    mkdir -p .ai
    echo "flask==3.0.0" > requirements.txt
    echo "python|flask|web-framework|2026-10-30|@owner" > .ai/deps-approved.txt
    git add requirements.txt .ai/deps-approved.txt
    git commit -q -m "initial commit"

    # Modify approvals file and add matching dep in working tree
    echo "requests==2.31.0" >> requirements.txt
    echo "python|requests|http-client|2026-10-30|@owner" >> .ai/deps-approved.txt

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" deps --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    assert_eq "0" "$status" "deps with approvals_changed=warn should pass when dependencies are approved" || return 1
    assert_contains "$output" "approval file changed in this commit; require a human code-owner review" "Must print distinct notice when approvals file is changed" || return 1
}

test_deps_approvals_changed_block() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cd "$sandbox" || return 1

    mkdir -p .ai
    echo "flask==3.0.0" > requirements.txt
    echo "python|flask|web-framework|2026-10-30|@owner" > .ai/deps-approved.txt
    cat << 'EOF' > .ai/verify.conf
deps=block
imports=warn
on_missing_python=warn
approvals_changed=block
EOF
    git add requirements.txt .ai/deps-approved.txt .ai/verify.conf
    git commit -q -m "initial commit"

    # Modify approvals file and add matching dep in working tree
    echo "requests==2.31.0" >> requirements.txt
    echo "python|requests|http-client|2026-10-30|@owner" >> .ai/deps-approved.txt

    local output
    local status=0
    output=$(python3 "$VERIFIER_PY" deps --target "$sandbox" 2>&1) || status=$?
    cleanup_sandbox "$sandbox"

    assert_eq "1" "$status" "deps with approvals_changed=block must exit non-zero when approvals file is changed" || return 1
    assert_contains "$output" "approval file changed in this commit; require a human code-owner review" "Must print notice when approvals file changed in block mode" || return 1
}

run_test "Verifier: Approved dependency passes" test_approved_dep_passes
run_test "Verifier: Unapproved dependency fails with instructions" test_unapproved_dep_fails
run_test "Verifier: Removal of dependency passes" test_removal_of_dep_passes
run_test "Verifier: Undeclared Python import is flagged" test_undeclared_python_import_flagged
run_test "Verifier: Undeclared JS/TS import is flagged" test_undeclared_js_import_flagged
run_test "Verifier: Common package import aliases are resolved" test_import_aliases_handled
run_test "Verifier: Stdlib, Node builtins, and relative imports are ignored" test_stdlib_builtins_and_relative_ignored
run_test "Verifier: Malformed manifest handled gracefully without traceback" test_malformed_manifest_handled_gracefully
run_test "Verifier: Registry check strictly requires --online flag" test_offline_policy_refuses_network_in_default_paths
run_test "Verifier: Evidence run records metadata and evidence --require validates clean HEAD" test_evidence_run_and_require
run_test "Verifier: Bash and PowerShell wrappers exist and are executable" test_bash_and_powershell_wrappers
run_test "Verifier: Namespace package resolves to declared manifest dependency" test_imports_namespace_package
run_test "Verifier: Src layout package resolves as internal workspace package" test_imports_src_layout
run_test "Verifier: tsconfig path alias is recognized as internal module" test_imports_tsconfig_paths
run_test "Verifier: Optional conditional import in try/except is ignored" test_imports_optional_conditional
run_test "Verifier: Registry check offline fixture tests age, nonexistent, and edit-distance flags" test_registry_check_offline_fixture_flags
run_test "Verifier: Notice printed when approvals file is changed (warn)" test_deps_approvals_changed_warn_notice
run_test "Verifier: Commit blocked when approvals file changed and policy is block" test_deps_approvals_changed_block

echo ""
echo "Verifier Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0

