#!/usr/bin/env bash
# AI-OS MCP Package Registry Verification (Online)
# Verifies all pinned MCP servers against upstream npm and PyPI registries for >= 14 days maturity.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_JSON="$REPO_ROOT/mcp.json"

if [ ! -f "$MCP_JSON" ]; then
    echo "ERROR: mcp.json not found at $MCP_JSON"
    exit 1
fi

echo "============================================================"
echo " 🌐 AI-OS MCP Server Registry & Maturity Verification"
echo "============================================================"

# Compute 14-day cutoff
CUTOFF_SEC=$(python -c "import time; print(int(time.time()) - 14 * 86400)")
CUTOFF_ISO=$(python -c "from datetime import datetime, timezone, timedelta; print((datetime.now(timezone.utc) - timedelta(days=14)).isoformat())")
echo "  Cutoff date (14 days ago): $CUTOFF_ISO"
echo ""

FAILURES=0

check_npm() {
    local pkg="$1"
    local pinned_ver="$2"
    echo -n "Checking npm package $pkg@$pinned_ver ... "
    
    local pub_time
    pub_time=$(npm view "$pkg" time --json 2>/dev/null | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ver = '$pinned_ver'
    print(data.get(ver, ''))
except Exception:
    print('')
" 2>/dev/null || true)

    if [ -z "$pub_time" ]; then
        echo "FAIL: Version $pinned_ver not found in npm registry"
        FAILURES=$((FAILURES + 1))
        return
    fi

    local pub_sec
    pub_sec=$(python -c "from datetime import datetime; dt = datetime.fromisoformat('$pub_time'.replace('Z', '+00:00')); print(int(dt.timestamp()))" 2>/dev/null || echo 0)
    local age_days
    age_days=$(python -c "import time; print(round((time.time() - $pub_sec) / 86400.0, 1))" 2>/dev/null || echo 0)

    if [ "$pub_sec" -le "$CUTOFF_SEC" ]; then
        echo "PASS ($pub_time, ${age_days}d old)"
    else
        echo "FAIL: Package is too young! Published $pub_time (${age_days}d old < 14d)"
        FAILURES=$((FAILURES + 1))
    fi
}

check_pypi() {
    local pkg="$1"
    local pinned_ver="$2"
    echo -n "Checking PyPI package $pkg==$pinned_ver ... "

    local pub_time
    pub_time=$(curl -sSf "https://pypi.org/pypi/$pkg/json" 2>/dev/null | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    releases = data.get('releases', {}).get('$pinned_ver', [])
    if releases:
        print(releases[0].get('upload_time_iso_8601', ''))
    else:
        print('')
except Exception:
    print('')
" 2>/dev/null || true)

    if [ -z "$pub_time" ]; then
        echo "FAIL: Version $pinned_ver not found in PyPI registry"
        FAILURES=$((FAILURES + 1))
        return
    fi

    local pub_sec
    pub_sec=$(python -c "from datetime import datetime; dt = datetime.fromisoformat('$pub_time'.replace('Z', '+00:00')); print(int(dt.timestamp()))" 2>/dev/null || echo 0)
    local age_days
    age_days=$(python -c "import time; print(round((time.time() - $pub_sec) / 86400.0, 1))" 2>/dev/null || echo 0)

    if [ "$pub_sec" -le "$CUTOFF_SEC" ]; then
        echo "PASS ($pub_time, ${age_days}d old)"
    else
        echo "FAIL: Package is too young! Published $pub_time (${age_days}d old < 14d)"
        FAILURES=$((FAILURES + 1))
    fi
}

# Run checks
check_npm "@modelcontextprotocol/server-filesystem" "1.0.0"
check_npm "@modelcontextprotocol/server-memory" "1.0.0"
check_pypi "mcp-server-git" "2026.10.10"
check_pypi "mcp-server-fetch" "2026.10.10"

echo ""
echo "============================================================"
echo " 🔌 AI-OS MCP Server Stdio Smoke Test (Initialize Handshake)"
echo "============================================================"

PY_CMD="python3"
command -v python3 >/dev/null 2>&1 || PY_CMD="python"

SMOKE_STATUS=0
"$PY_CMD" - "$MCP_JSON" << 'EOF' || SMOKE_STATUS=$?
import json, os, subprocess, sys, time, shutil

mcp_path = sys.argv[1]
with open(mcp_path, 'r', encoding='utf-8') as f:
    config = json.load(f)

servers = config.get('mcpServers', {})
failures = 0

req = json.dumps({
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'initialize',
    'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'smoke-test', 'version': '1.0.0'}
    }
}) + '\n'

for name, srv in servers.items():
    cmd = [srv['command']] + srv.get('args', [])
    resolved_bin = shutil.which(cmd[0])
    if not resolved_bin:
        print(f"Server '{name}': NOT VERIFIED (binary '{cmd[0]}' not found)")
        failures += 1
        continue

    full_cmd = [resolved_bin] + cmd[1:]
    cmd_str = ' '.join(cmd)
    print(f"Starting {name} ({cmd_str}) ... ", end='', flush=True)
    start = time.time()
    try:
        p = subprocess.Popen(
            full_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        p.stdin.write(req)
        p.stdin.flush()

        resp_line = ''
        while time.time() - start < 20:
            line = p.stdout.readline()
            if line:
                resp_line = line
                break
            time.sleep(0.05)

        duration = round(time.time() - start, 2)
        try:
            p.terminate()
            p.wait(timeout=2)
        except Exception:
            p.kill()

        if resp_line:
            data = json.loads(resp_line)
            if 'result' in data:
                proto = data['result'].get('protocolVersion', 'unknown')
                srv_info = data['result'].get('serverInfo', {}).get('name', 'unknown')
                print(f"PASS ({duration}s, proto={proto}, server={srv_info})")
            else:
                print(f"FAIL (response missing result: {resp_line.strip()})")
                failures += 1
        else:
            _, err = p.communicate(timeout=2)
            print(f"FAIL (timed out after 20s; stderr: {err.strip()[:120]})")
            failures += 1
    except Exception as e:
        print(f"FAIL ({e})")
        failures += 1

if failures > 0:
    sys.exit(1)
sys.exit(0)
EOF

if [ "$SMOKE_STATUS" -ne 0 ]; then
    FAILURES=$((FAILURES + SMOKE_STATUS))
fi

echo ""
echo "============================================================"
echo " 🔒 AI-OS GitHub Actions Workflow Pin Verification (Online)"
echo "============================================================"

check_action_pin() {
    local action="$1"
    local tag="$2"
    local expected_sha="$3"
    printf "Checking GitHub Action %s@%s ... " "$action" "$tag"
    
    local resolved_sha=""
    if command -v gh >/dev/null 2>&1; then
        resolved_sha=$(gh api "repos/$action/commits/$tag" --jq .sha 2>/dev/null || true)
    fi
    if [ -z "$resolved_sha" ]; then
        resolved_sha=$(curl -sSf -H "User-Agent: AI-OS-Registry-Check" "https://api.github.com/repos/$action/commits/$tag" 2>/dev/null | python -c "import sys, json; print(json.load(sys.stdin).get('sha', ''))" 2>/dev/null || true)
    fi

    if [ -z "$resolved_sha" ]; then
        echo "FAIL: Could not resolve commit for tag $tag from GitHub API"
        FAILURES=$((FAILURES + 1))
        return
    fi

    if [ "$resolved_sha" = "$expected_sha" ]; then
        echo "PASS (SHA matches $expected_sha)"
    else
        echo "FAIL: Pinned SHA $expected_sha != resolved commit SHA $resolved_sha"
        FAILURES=$((FAILURES + 1))
    fi
}

check_action_pin "actions/checkout" "v4.2.2" "11bd71901bbe5b1630ceea73d27597364c9af683"
check_action_pin "actions/setup-python" "v5.6.0" "a26af69be951a213d495a4c3e4e4022e16d87065"
check_action_pin "actions/setup-node" "v4.4.0" "49933ea5288caeca8642d1e84afbd3f7d6820020"
check_action_pin "astral-sh/setup-uv" "v5.4.2" "d4b2f3b6ecc6e67c4457f6d3e41ec42d3d0fcb86"

echo ""
echo "============================================================"
echo " 🌐 Approved Dependency Online Registry Verification"
echo "============================================================"
python3 "$REPO_ROOT/scripts/ai_os_verify.py" registry-check --online --target "$REPO_ROOT" || FAILURES=$((FAILURES + 1))

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ All MCP pins and workflow action pins verified against upstream registries."
    exit 0
else
    echo "❌ Registry & action pin check failed with $FAILURES error(s)."
    exit 1
fi
