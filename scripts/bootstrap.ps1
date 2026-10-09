# AI-OS Team Clone Bootstrap Script (PowerShell)
# Configures local git hooks and verifies system dependencies after fresh checkout.

$ErrorActionPreference = "Stop"

$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 🚀 Bootstrapping AI-OS Environment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Configure git hooks
if (Test-Path (Join-Path $RepoRoot ".git")) {
    $currentHooks = (git config core.hooksPath 2>$null)
    if (-not $currentHooks) {
        if (Test-Path (Join-Path $RepoRoot ".githooks")) {
            git config core.hooksPath .githooks
            Write-Host "✅ Configured git core.hooksPath -> .githooks" -ForegroundColor Green
        }
    } else {
        Write-Host "ℹ️ core.hooksPath already configured ($currentHooks)" -ForegroundColor Gray
    }
}

# 2. Run Doctor if available
$doctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript -ProjectPath $RepoRoot
}

Write-Host "🎉 Bootstrap complete! Your development environment is ready." -ForegroundColor Green
exit 0
