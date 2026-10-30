# AI-OS Interactive & Automated Demonstration Script (PowerShell)
# Demonstrates secret blocking, phantom dependency blocking, and clean commit execution.

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " [AI-OS] LIVE CAPABILITY DEMONSTRATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$tempBase = [System.IO.Path]::GetTempPath()
$demoDir = Join-Path $tempBase ("aios_demo_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $demoDir -Force | Out-Null

$origDir = [System.IO.Directory]::GetCurrentDirectory()

try {
    Write-Host " Created scratch demonstration repository at $demoDir" -ForegroundColor Gray
    Set-Location $demoDir
    [System.IO.Directory]::SetCurrentDirectory($demoDir)

    git init -q
    git config user.name "AI-OS Demo User"
    git config user.email "demo@ai-os.dev"

    "# Demo Project" | Out-File -FilePath "README.md" -Encoding utf8
    git add README.md
    git commit -qm "Initial commit" 2>$null

    Write-Host " Installing AI-OS..." -ForegroundColor Gray
    & (Join-Path $RootDir "scripts/install.ps1") -TargetPath $demoDir | Out-Null

    git add -A
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git commit -qm "chore: initialize AI-OS baseline" 2>&1 | Out-Null
    $ErrorActionPreference = $prevEAP

    Write-Host "`n--- Scenario 1: Attempting to commit a leaked secret token ---" -ForegroundColor Yellow
    $keyPrefix = "sk_live_"
    $keyBody = "51Abcd1234efgh5678ijkl9012345678"
    $fakeKey = "${keyPrefix}${keyBody}"
    @"
# Inadvertent secret leak
SERVICE_KEY = "$fakeKey"
"@ | Out-File -FilePath "app_config.py" -Encoding utf8

    git add app_config.py
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git commit -m "feat: add service credentials" 2>&1 | Out-Null
    $commitStatus = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($commitStatus -eq 0) {
        Write-Error "ERROR: Secret commit was permitted!"
        exit 1
    } else {
        Write-Host " [BLOCKED] Secret leak commit rejected by AI-OS pre-commit guard." -ForegroundColor Green
    }
    git reset --hard HEAD 2>$null | Out-Null
    git clean -fd 2>$null | Out-Null

    Write-Host "`n--- Scenario 2: Attempting to commit an unapproved phantom dependency ---" -ForegroundColor Yellow
    "phantom-ai-query-parser==1.0.0" | Out-File -FilePath "requirements.txt" -Encoding utf8
    git add requirements.txt
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git commit -m "feat: add query parser package" 2>&1 | Out-Null
    $depStatus = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($depStatus -eq 0) {
        Write-Error "ERROR: Phantom dependency commit was permitted!"
        exit 1
    } else {
        Write-Host " [BLOCKED] Unapproved dependency rejected by AI-OS dependency verifier." -ForegroundColor Green
    }
    git reset --hard HEAD 2>$null | Out-Null
    git clean -fd 2>$null | Out-Null

    Write-Host "`n--- Scenario 3: Committing a clean, harmless change ---" -ForegroundColor Yellow
    @"
import math

def calculate_circle_area(radius):
    """Calculates the area of a circle using stdlib math."""
    if radius < 0:
        raise ValueError("radius cannot be negative")
    return math.pi * radius * radius
"@ | Out-File -FilePath "math_utils.py" -Encoding utf8

    git add math_utils.py
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git commit -m "feat: add circular area utility" 2>&1 | Out-Null
    $cleanStatus = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($cleanStatus -eq 0) {
        Write-Host " [ALLOWED] Clean change committed successfully through verification hooks." -ForegroundColor Green
    } else {
        Write-Error "ERROR: Harmless commit was unexpectedly blocked!"
        exit 1
    }

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " Demo Summary: 2 Blocked (Secret, Phantom Dep) | 1 Allowed (Clean)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    exit 0
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
    if (Test-Path $demoDir) {
        Remove-Item -Path $demoDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
