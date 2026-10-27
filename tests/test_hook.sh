#!/usr/bin/env bash
# AI-OS Pre-Commit Guard Test Suite (Reproducing F2 Findings & Phase 1.5 Hardening)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_UNDER_TEST="${1:-$REPO_ROOT/templates/project/.githooks/pre-commit}"

echo "============================================================"
echo " 🧪 Testing Pre-Commit Hook: $HOOK_UNDER_TEST"
echo "============================================================"

# Helper function to generate mock secrets at runtime (no literal keys committed)
make_key() {
    local pfx="$1"
    local sfx="$2"
    printf '%s%s' "$pfx" "$sfx"
}

run_hook_on_staged() {
    local sandbox="$1"
    cd "$sandbox" || return 1
    
    # Copy hook and secret patterns into sandbox
    mkdir -p .githooks .ai
    cp "$HOOK_UNDER_TEST" .githooks/pre-commit
    cp "$REPO_ROOT/.ai/secret-patterns.txt" .ai/secret-patterns.txt
    [ -f "$REPO_ROOT/.ai/secret-allowlist.txt" ] && cp "$REPO_ROOT/.ai/secret-allowlist.txt" .ai/secret-allowlist.txt
    chmod +x .githooks/pre-commit
    
    # Run the hook directly
    .githooks/pre-commit
}

# --- 1. Baseline Blocked Cases ---

test_blocked_plain_openai_sk() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-" "1234567890123456789012345")
    echo "OPENAI_KEY=$k" > "$sandbox/app.js"
    git -C "$sandbox" add app.js
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Plain sk- key should be blocked by hook"
}

test_blocked_root_env() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    echo "SECRET=123" > "$sandbox/.env"
    git -C "$sandbox" add .env
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Root .env should be blocked by hook"
}

test_blocked_private_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local hdr
    local ftr
    hdr=$(printf '%s %s %s' "-----BEGIN" "RSA PRIVATE" "KEY-----")
    ftr=$(printf '%s %s %s' "-----END" "RSA PRIVATE" "KEY-----")
    cat << EOF > "$sandbox/server.pem"
$hdr
MIIEowIBAAKCAQEA0Y...
$ftr
EOF
    git -C "$sandbox" add server.pem
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Private key should be blocked by hook"
}

# --- 2. Gaps & NOT Blocked Cases (F2 Findings) ---

test_blocked_aws_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "AKIA" "IOSFODNN7EXAMPLE")
    echo "AWS_KEY=$k" > "$sandbox/aws.js"
    git -C "$sandbox" add aws.js
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "AWS AKIA key should be blocked by hook"
}

test_blocked_github_pat() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "ghp_" "1234567890abcdefghijklmnopqrstuvwxyz12")
    echo "GH_TOKEN=$k" > "$sandbox/deploy.sh"
    git -C "$sandbox" add deploy.sh
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "GitHub ghp_ token should be blocked by hook"
}

test_blocked_stripe_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk_live_" "51Abcd1234efgh5678ijkl9012345678")
    echo "STRIPE_SECRET=$k" > "$sandbox/payment.js"
    git -C "$sandbox" add payment.js
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Stripe sk_live_ key should be blocked by hook"
}

test_blocked_google_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "AIza" "SyD-1234567890abcdefghijklmnopqrst")
    echo "GOOGLE_KEY=$k" > "$sandbox/maps.js"
    git -C "$sandbox" add maps.js
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Google AIza key should be blocked by hook"
}

test_blocked_anthropic_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-ant-" "api03-1234567890abcdefghijklmnopqrstuvwxyz-ABCD")
    echo "ANTHROPIC_API_KEY=$k" > "$sandbox/agent.py"
    git -C "$sandbox" add agent.py
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Anthropic sk-ant- key with hyphens should be blocked by hook"
}

test_blocked_openai_proj_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-proj-" "1234567890abcdefghijklmnopqrstuvwxyz1234567890ABCD")
    echo "OPENAI_API_KEY=$k" > "$sandbox/agent.py"
    git -C "$sandbox" add agent.py
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "OpenAI sk-proj- key with hyphens should be blocked by hook"
}

test_blocked_db_url_password() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local p1
    local p2
    local p3
    p1="postgres://admin:"
    p2="secretpassword123@"
    p3="db.example.com:5432/mydb"
    echo "DATABASE_URL=${p1}${p2}${p3}" > "$sandbox/config.ts"
    git -C "$sandbox" add config.ts
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Database URL with password should be blocked by hook"
}

test_blocked_nested_env() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/apps/web"
    echo "SECRET=nested_secret" > "$sandbox/apps/web/.env"
    git -C "$sandbox" add apps/web/.env
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Nested .env in apps/web/.env should be blocked by hook"
}

test_blocked_githooks_secret() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/.githooks"
    local k
    k=$(make_key "ghp_" "1234567890abcdefghijklmnopqrstuvwxyz12")
    echo "TOKEN=$k" > "$sandbox/.githooks/custom_script.sh"
    git -C "$sandbox" add .githooks/custom_script.sh
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Secrets inside .githooks/ must NOT be exempted"
}

# --- 3. False Positives (Should NOT be blocked) ---

test_allowed_env_example() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    echo "API_KEY=your_key_here" > "$sandbox/.env.example"
    echo "DATABASE_HOST=localhost" > "$sandbox/.env.sample"
    echo "PORT=3000" > "$sandbox/.env.template"
    git -C "$sandbox" add .env.example .env.sample .env.template
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "0" "$status" ".env.example / .sample / .template should be allowed"
}

test_allowed_delete_leaked_key() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-" "1234567890123456789012345")
    # Commit a leaked key first without hook
    echo "LEAKED=$k" > "$sandbox/app.js"
    git -C "$sandbox" add app.js
    git -C "$sandbox" commit -q -m "Initial commit with accidental leak"
    
    # Now fix it by removing the leaked key
    echo "LEAKED=process.env.API_KEY" > "$sandbox/app.js"
    git -C "$sandbox" add app.js
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "0" "$status" "Deleting a leaked key should be ALLOWED"
}

# --- 4. Phase 1.5 Hardening: C++ / Pre-increment '++' Syntax Tests ---

test_regression_plus_plus_syntax_with_secret() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-proj-" "1234567890abcdefghijklmnopqrstuvwxyz1234567890ABCD")
    cat << EOF > "$sandbox/counter.cpp"
int main() {
    int i = 0;
    ++i; // token: $k
    return 0;
}
EOF
    git -C "$sandbox" add counter.cpp
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Line starting with ++ containing secret MUST be caught"
}

test_regression_plus_plus_syntax_clean() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    cat << 'EOF' > "$sandbox/counter.cpp"
int main() {
    int i = 0;
    ++i;
    +++i; // triple plus or C++ statement
    return 0;
}
EOF
    git -C "$sandbox" add counter.cpp
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "0" "$status" "Line starting with ++ without secret MUST be allowed"
}

# --- 5. Phase 1.5 Hardening: Gitleaks Present-but-Failing Tests ---

test_gitleaks_present_and_blocking() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/bin"
    # Create mock gitleaks that detects a leak (exits 1)
    cat << 'EOF' > "$sandbox/bin/gitleaks"
#!/usr/bin/env bash
echo "Mock Gitleaks found a leak!"
exit 1
EOF
    chmod +x "$sandbox/bin/gitleaks"
    
    echo "SAFE_CODE=true" > "$sandbox/safe.js"
    git -C "$sandbox" add safe.js
    
    local old_path="$PATH"
    export PATH="$sandbox/bin:$PATH"
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    export PATH="$old_path"
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Hook must block when gitleaks detects leak"
}

test_gitleaks_present_but_misses_pattern() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/bin"
    # Create mock gitleaks that falsely passes (exits 0)
    cat << 'EOF' > "$sandbox/bin/gitleaks"
#!/usr/bin/env bash
# Mock gitleaks misses this token and exits 0
exit 0
EOF
    chmod +x "$sandbox/bin/gitleaks"
    
    local k
    k=$(make_key "sk-ant-" "api03-1234567890abcdefghijklmnopqrstuvwxyz-ABCD")
    echo "ANTHROPIC_KEY=$k" > "$sandbox/agent.py"
    git -C "$sandbox" add agent.py
    
    local old_path="$PATH"
    export PATH="$sandbox/bin:$PATH"
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    export PATH="$old_path"
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Hook must fallback to built-in patterns and block even if gitleaks misses"
}

test_gitleaks_present_with_runtime_error() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    mkdir -p "$sandbox/bin"
    # Create mock gitleaks that crashes (exits 127)
    cat << 'EOF' > "$sandbox/bin/gitleaks"
#!/usr/bin/env bash
echo "gitleaks: internal error: segment fault" >&2
exit 127
EOF
    chmod +x "$sandbox/bin/gitleaks"
    
    echo "SAFE_CODE=true" > "$sandbox/safe.js"
    git -C "$sandbox" add safe.js
    
    local old_path="$PATH"
    export PATH="$sandbox/bin:$PATH"
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    export PATH="$old_path"
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Hook must block when gitleaks fails with runtime error"
}

# --- 6. Placeholder-Aware Secret Scanning Tests ---

test_allowed_placeholder_db_url() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local s="://"
    local at="@"
    cat << EOF > "$sandbox/.env.example"
# Standard template database URLs with obvious placeholders
DATABASE_URL=postgresql${s}user:password${at}localhost:5432/mydb
CHANGEME_URL=postgres${s}admin:changeme${at}db.internal:5432/test
XXX_URL=mysql${s}root:xxx${at}db-host:3306/dev
YOUR_URL=postgres${s}user:your_password${at}db-host/mydb
TEMPLATE_URL=postgresql${s}<user>:<password>${at}<host>/<dbname>
ENV_VAR_URL=postgresql${s}\${DB_USER}:\${DB_PASSWORD}${at}\${DB_HOST}/\${DB_NAME}
LOCAL_URL=postgres${s}user:pass${at}localhost:5432/mydb
EOF
    cat << EOF > "$sandbox/README.md"
### Quickstart
Run with \`DATABASE_URL=postgresql${s}user:password${at}localhost:5432/mydb\`
EOF
    git -C "$sandbox" add .env.example README.md
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "0" "$status" "Obvious placeholder database URLs in .env.example and README.md must be allowed"
}

test_blocked_realistic_db_url() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local s="://"
    local at="@"
    # A realistic database URL with a random-looking password assembled at runtime
    echo "DATABASE_URL=postgres${s}prod_app:qK9_xM2_8vL9_R7p${at}db.production.internal:5432/orders_live" > "$sandbox/config.ts"
    git -C "$sandbox" add config.ts
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Realistic database URL with random-looking password must be blocked"
}

test_blocked_vendor_token_in_env_example() {
    local sandbox
    sandbox=$(create_sandbox_repo)
    local k
    k=$(make_key "sk-proj-" "1234567890abcdefghijklmnopqrstuvwxyz1234567890ABCD")
    echo "OPENAI_API_KEY=$k" > "$sandbox/.env.example"
    git -C "$sandbox" add .env.example
    
    local output
    output=$(run_hook_on_staged "$sandbox")
    local status=$?
    cleanup_sandbox "$sandbox"
    
    assert_eq "1" "$status" "Vendor token inside .env.example must still be blocked"
}

# Run all hook tests
run_test "Blocked: Plain OpenAI sk- key" test_blocked_plain_openai_sk
run_test "Blocked: Root .env file" test_blocked_root_env
run_test "Blocked: RSA/EC Private key header" test_blocked_private_key
run_test "Blocked (F2): AWS AKIA Access Key" test_blocked_aws_key
run_test "Blocked (F2): GitHub PAT ghp_ token" test_blocked_github_pat
run_test "Blocked (F2): Stripe Secret sk_live_ token" test_blocked_stripe_key
run_test "Blocked (F2): Google AIza API key" test_blocked_google_key
run_test "Blocked (F2): Anthropic sk-ant- token" test_blocked_anthropic_key
run_test "Blocked (F2): OpenAI sk-proj- token" test_blocked_openai_proj_key
run_test "Blocked (F2): Database URL with password" test_blocked_db_url_password
run_test "Blocked (F2): Nested apps/web/.env file" test_blocked_nested_env
run_test "Blocked (F2): Secret inside .githooks/ folder" test_blocked_githooks_secret
run_test "Allowed (F2): .env.example / sample / template" test_allowed_env_example
run_test "Allowed (F2): Deletion diff of a leaked key" test_allowed_delete_leaked_key
run_test "Hardening (P1.5): ++ prefix line with secret is blocked" test_regression_plus_plus_syntax_with_secret
run_test "Hardening (P1.5): ++ prefix line without secret is allowed" test_regression_plus_plus_syntax_clean
run_test "Hardening (P1.5): Gitleaks present and blocking" test_gitleaks_present_and_blocking
run_test "Hardening (P1.5): Gitleaks present but misses -> built-in blocks" test_gitleaks_present_but_misses_pattern
run_test "Hardening (P1.5): Gitleaks present with runtime error -> blocks" test_gitleaks_present_with_runtime_error
run_test "Hardening (Step 2): Obvious placeholder database URLs allowed" test_allowed_placeholder_db_url
run_test "Hardening (Step 2): Realistic database URL with random password blocked" test_blocked_realistic_db_url
run_test "Hardening (Step 2): Vendor token inside .env.example still blocked" test_blocked_vendor_token_in_env_example

echo ""
echo "Hook Test Summary: $PASSED_TESTS Passed | $FAILED_TESTS Failed"
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
fi
exit 0
