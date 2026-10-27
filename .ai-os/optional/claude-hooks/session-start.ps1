# AI-OS Claude Code Hook: SessionStart (PowerShell)
# Displays active project task-state summary and token budget status on session start/resume.

$ErrorActionPreference = "SilentlyContinue"
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$taskState = Join-Path $projectDir "docs/task-state.md"
$agentsFile = Join-Path $projectDir "AGENTS.md"
$budget = 8192

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " AI-OS Claude Code Session Active" -ForegroundColor Cyan
Write-Host " Project Root: $projectDir"
Write-Host "====================================================" -ForegroundColor Cyan

if (Test-Path $agentsFile) {
    $size = (Get-Item $agentsFile).Length
    if ($size -le $budget) {
        Write-Host " Token Budget: AGENTS.md is $size / $budget bytes [PASS]" -ForegroundColor Green
    } else {
        Write-Host " Token Budget: AGENTS.md is $size / $budget bytes [EXCEEDED]" -ForegroundColor Red
    }
} else {
    Write-Host " Token Budget: AGENTS.md not found in project root" -ForegroundColor Yellow
}

if (Test-Path $taskState) {
    Write-Host " Task State Summary (docs/task-state.md):" -ForegroundColor Cyan
    Get-Content $taskState -TotalCount 25 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host " Task State: docs/task-state.md not initialized" -ForegroundColor Yellow
}

Write-Host "====================================================" -ForegroundColor Cyan
exit 0
