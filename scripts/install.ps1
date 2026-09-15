<#
.SYNOPSIS
    AI Operating System Professional Project Integrator (by Rudra Sharma).
.DESCRIPTION
    Safely integrates AI-OS into an existing software repository without modifying existing code.
.PARAMETER TargetPath
    Path to the target project directory. Defaults to current working directory.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = (Get-Location).Path
)

# Detect Git User and Project Name
$gitUser = (git config user.name)
if (-not $gitUser) { $gitUser = $env:USERNAME }
if (-not $gitUser) { $gitUser = "Developer" }

$projectName = (Split-Path -Leaf $TargetPath)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $RepoRoot "templates\project"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " AI Operating System (AI-OS by Rudra Sharma) - Project Integrator" -ForegroundColor Cyan
Write-Host " Target Project: $projectName ($TargetPath)" -ForegroundColor Cyan
Write-Host " User:           $gitUser" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# Safety Check: Verify Target Exists
if (-not (Test-Path $TargetPath)) {
    Write-Error "Target directory '$TargetPath' does not exist! Please check path."
    exit 1
}

# Step 1: Copy AI-OS Template Files Safely
Write-Host "`n[1/3] Copying AI-OS architecture and rule files..." -ForegroundColor Green
$items = @("AGENTS.md", "CLAUDE.md", "GEMINI.md", "CODEX.md", "mcp.json", "docs", ".ai", ".claude", ".githooks")
foreach ($item in $items) {
    $srcItem = Join-Path $TemplateDir $item
    $destItem = Join-Path $TargetPath $item
    if (Test-Path $srcItem) {
        if (-not (Test-Path $destItem)) {
            Copy-Item -Path $srcItem -Destination $destItem -Recurse -Force
            Write-Host "  + Added $item" -ForegroundColor Gray
        } else {
            Write-Host "  = Existing $item preserved (not overwritten)" -ForegroundColor DarkGray
        }
    }
}

# Step 2: Configure Git Hooks
Write-Host "[2/3] Configuring secret protection and Git hooks..." -ForegroundColor Green
Push-Location $TargetPath
try {
    if (Test-Path ".git") {
        if (Test-Path ".githooks") {
            git config core.hooksPath .githooks
            Write-Host "  + Secret scanning pre-commit hook activated." -ForegroundColor Gray
        }
    }
} finally {
    Pop-Location
}

# Step 3: Run Diagnostic Validation
Write-Host "[3/3] Running health integrity check..." -ForegroundColor Green
$doctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript -ProjectPath $TargetPath
}

Write-Host "`n========================================================================" -ForegroundColor Yellow
Write-Host " Hey $gitUser! AI-OS by Rudra is successfully integrated" -ForegroundColor Yellow
Write-Host "    into your project '$projectName'!" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Yellow

Write-Host "`n NEXT STEP: Open '$projectName' in your AI IDE (Antigravity/Cursor/Claude Code)" -ForegroundColor Cyan
Write-Host "   and paste this EXACT first prompt into chat:" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor White
Write-Host "Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze this repository." -ForegroundColor Green
Write-Host "Please map our existing codebase and update docs/architecture.md, docs/conventions.md," -ForegroundColor Green
Write-Host "and docs/graph.md with our current components, tech stack, and data flow." -ForegroundColor Green
Write-Host "------------------------------------------------------------------------" -ForegroundColor White
Write-Host ""
