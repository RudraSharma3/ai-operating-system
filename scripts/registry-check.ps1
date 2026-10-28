# AI-OS MCP Package Registry Verification (Online, PowerShell)
# Verifies all pinned MCP servers against upstream npm and PyPI registries for >= 14 days maturity.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$mcpJson = Join-Path $repoRoot "mcp.json"

if (-not (Test-Path $mcpJson)) {
    Write-Error "mcp.json not found at $mcpJson"
    exit 1
}

Write-Host "============================================================"
Write-Host " [REGISTRY] AI-OS MCP Server Registry & Maturity Verification"
Write-Host "============================================================"

$now = [DateTime]::UtcNow
$cutoff = $now.AddDays(-14)
Write-Host "  Cutoff date (14 days ago): $($cutoff.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
Write-Host ""

$failures = 0

function Check-NpmPackage {
    param([string]$pkg, [string]$pinnedVer)
    Write-Host -NoNewline "Checking npm package $pkg@$pinnedVer ... "
    try {
        $jsonStr = & npm view $pkg time --json 2>$null
        if (-not $jsonStr) {
            Write-Host "FAIL: npm view returned no data" -ForegroundColor Red
            $script:failures++
            return
        }
        $timeObj = $jsonStr | ConvertFrom-Json
        $pubStr = $timeObj.$pinnedVer
        if (-not $pubStr) {
            Write-Host "FAIL: Version $pinnedVer not found in npm registry" -ForegroundColor Red
            $script:failures++
            return
        }
        $pubDt = [DateTime]::Parse($pubStr, $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        $ageDays = [math]::Round(($now - $pubDt).TotalDays, 1)
        if ($pubDt -le $cutoff) {
            Write-Host "PASS ($pubStr, ${ageDays}d old)" -ForegroundColor Green
        } else {
            Write-Host "FAIL: Package is too young! Published $pubStr (${ageDays}d old < 14d)" -ForegroundColor Red
            $script:failures++
        }
    } catch {
        Write-Host "FAIL: Exception checking npm: $_" -ForegroundColor Red
        $script:failures++
    }
}

function Check-PyPiPackage {
    param([string]$pkg, [string]$pinnedVer)
    Write-Host -NoNewline "Checking PyPI package $pkg==$pinnedVer ... "
    try {
        $resp = Invoke-RestMethod -Uri "https://pypi.org/pypi/$pkg/json" -Method Get -TimeoutSec 15
        $releases = $resp.releases.$pinnedVer
        if (-not $releases -or $releases.Count -eq 0) {
            Write-Host "FAIL: Version $pinnedVer not found in PyPI registry" -ForegroundColor Red
            $script:failures++
            return
        }
        $pubStr = $releases[0].upload_time_iso_8601
        $pubDt = [DateTime]::Parse($pubStr, $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        $ageDays = [math]::Round(($now - $pubDt).TotalDays, 1)
        if ($pubDt -le $cutoff) {
            Write-Host "PASS ($pubStr, ${ageDays}d old)" -ForegroundColor Green
        } else {
            Write-Host "FAIL: Package is too young! Published $pubStr (${ageDays}d old < 14d)" -ForegroundColor Red
            $script:failures++
        }
    } catch {
        Write-Host "FAIL: Exception checking PyPI: $_" -ForegroundColor Red
        $script:failures++
    }
}

Check-NpmPackage "@modelcontextprotocol/server-filesystem" "1.0.0"
Check-NpmPackage "@modelcontextprotocol/server-memory" "1.0.0"
Check-PyPiPackage "mcp-server-git" "2026.10.10"
Check-PyPiPackage "mcp-server-fetch" "2026.10.10"

Write-Host ""
Write-Host "============================================================"
Write-Host " [SMOKE] AI-OS MCP Server Stdio Smoke Test (Initialize Handshake)"
Write-Host "============================================================"

$pySmokeScript = @'
import json, os, subprocess, sys, time, shutil

mcp_path = sys.argv[1]
with open(mcp_path, "r", encoding="utf-8") as f:
    config = json.load(f)

servers = config.get("mcpServers", {})
failures = 0

req = json.dumps({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "smoke-test", "version": "1.0.0"}
    }
}) + "\n"

for name, srv in servers.items():
    cmd = [srv["command"]] + srv.get("args", [])
    resolved_bin = shutil.which(cmd[0])
    if not resolved_bin:
        print(f"Server {name}: NOT VERIFIED (binary {cmd[0]} not found)")
        failures += 1
        continue

    full_cmd = [resolved_bin] + cmd[1:]
    cmd_str = " ".join(cmd)
    print(f"Starting {name} ({cmd_str}) ... ", end="", flush=True)
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

        resp_line = ""
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
            if "result" in data:
                proto = data["result"].get("protocolVersion", "unknown")
                srv_info = data["result"].get("serverInfo", {}).get("name", "unknown")
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
'@

$pyCmd = if (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } else { "python" }
$smokeOutput = $pySmokeScript | & $pyCmd - $mcpJson
Write-Host $smokeOutput
if ($LASTEXITCODE -ne 0) {
    $failures++
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host " [PASS] All MCP pins verified against upstream registries and passed stdio initialize smoke tests." -ForegroundColor Green
    exit 0
} else {
    Write-Host " [FAIL] Registry & smoke check failed with $failures error(s)." -ForegroundColor Red
    exit 1
}
