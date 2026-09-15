param (
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = (Get-Location).Path
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Detect Git User and Project Name
$gitUser = (git config user.name)
if (-not $gitUser) { $gitUser = $env:USERNAME }
if (-not $gitUser) { $gitUser = "Developer" }

$projectName = (Split-Path -Leaf $TargetPath)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $RepoRoot "templates\project"

Write-Host ""
Write-Host "  > AI Operating System v2.0" -ForegroundColor Cyan
Write-Host "    by Rudra Sharma" -ForegroundColor DarkGray
Write-Host ""

# Safety Check: Verify Target Exists
if (-not (Test-Path $TargetPath)) {
    Write-Host "  [X] Target directory not found: $TargetPath" -ForegroundColor Red
    exit 1
}

Write-Host "  [+] Target: $projectName ($TargetPath)" -ForegroundColor Gray

# Step 1: Copy AI-OS Template Files Safely
$items = @("AGENTS.md", "CLAUDE.md", "GEMINI.md", "CODEX.md", "mcp.json", "docs", ".ai", ".claude", ".githooks")
foreach ($item in $items) {
    $srcItem = Join-Path $TemplateDir $item
    $destItem = Join-Path $TargetPath $item
    if (Test-Path $srcItem) {
        if (-not (Test-Path $destItem)) {
            Copy-Item -Path $srcItem -Destination $destItem -Recurse -Force
        }
    }
}
Write-Host "  [OK] Architecture and Canonical Rules Ingested" -ForegroundColor Green

# Step 2: Configure Git Hooks
Push-Location $TargetPath
try {
    if (Test-Path ".git") {
        if (Test-Path ".githooks") {
            git config core.hooksPath .githooks
        }
    }
} finally {
    Pop-Location
}
Write-Host "  [OK] Git Pre-Commit Secret Armor Armed" -ForegroundColor Green

# Step 3: Run Diagnostic Validation
$doctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript -ProjectPath $TargetPath
}

# Clean, Professional Developer Confirmation
Write-Host ""
Write-Host "  Hey $gitUser! AI-OS by Rudra is successfully integrated into '$projectName'!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next Step: Open '$projectName' in your AI IDE and paste this prompt:" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze this" -ForegroundColor White
Write-Host "  repository. Please map our existing codebase and update docs/architecture.md," -ForegroundColor White
Write-Host "  docs/conventions.md, and docs/graph.md with our current components," -ForegroundColor White
Write-Host "  tech stack, and data flow." -ForegroundColor White
Write-Host "  --------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
