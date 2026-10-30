#!/usr/bin/env bash
# AI-OS Test Harness Helper Library

FAILED_TESTS=0
PASSED_TESTS=0

# Colors for terminal output
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_RESET='\033[0m'

run_test() {
    local test_name="$1"
    local test_func="$2"
    echo -n -e "  • ${C_CYAN}[TEST]${C_RESET} $test_name ... "
    
    # Run in subshell
    local output
    local status
    output=$( ( $test_func ) 2>&1 )
    status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "${C_GREEN}PASS${C_RESET}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${C_RED}FAIL${C_RESET}"
        echo -e "${C_YELLOW}    --- Output / Failure Details ---${C_RESET}"
        echo "$output" | sed 's/^/    | /'
        echo -e "${C_YELLOW}    --------------------------------${C_RESET}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

create_sandbox_repo() {
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'aios_test')
    cd "$temp_dir" || exit 1
    git init -q -b main
    git config user.name "AI-OS Tester"
    git config user.email "tester@ai-os.dev"
    echo "$temp_dir"
}

cleanup_sandbox() {
    local dir="$1"
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Assertion failed: '$actual' != '$expected'}"
    if [ "$expected" != "$actual" ]; then
        echo "ASSERTION FAILED: $msg"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        return 1
    fi
    return 0
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-Assertion failed: output does not contain '$needle'}"
    if ! echo "$haystack" | grep -F -q -e "$needle"; then
        echo "ASSERTION FAILED: $msg"
        echo "Full text: $haystack"
        return 1
    fi
    return 0
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-Assertion failed: output unexpectedly contains '$needle'}"
    if echo "$haystack" | grep -F -q -e "$needle"; then
        echo "ASSERTION FAILED: $msg"
        echo "Full text: $haystack"
        return 1
    fi
    return 0
}
