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
Write-Host " 🌐 AI-OS MCP Server Registry & Maturity Verification"
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
if ($failures -eq 0) {
    Write-Host "✅ All MCP pins verified against upstream registries and satisfy 14-day maturity requirement." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Registry check failed with $failures error(s)." -ForegroundColor Red
    exit 1
}
