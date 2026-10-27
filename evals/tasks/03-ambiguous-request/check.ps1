[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = Get-Location
try {
    Set-Location $TargetDir
    $targetTaskState = Join-Path $TargetDir "docs/task-state.md"
    if (-not (Test-Path $targetTaskState)) {
        Write-Error "Missing docs/task-state.md documenting prompt contract"
        exit 1
    }

    $content = Get-Content -Path $targetTaskState -Raw

    if ($content -notmatch '(?i)(###|\*\*)\s*.*GOAL') {
        Write-Error "Missing GOAL section in docs/task-state.md"
        exit 1
    }
    if ($content -notmatch '(?i)(###|\*\*)\s*.*CONSTRAINTS') {
        Write-Error "Missing CONSTRAINTS section in docs/task-state.md"
        exit 1
    }
    if ($content -notmatch '(?i)(###|\*\*)\s*.*FORMAT') {
        Write-Error "Missing FORMAT section in docs/task-state.md"
        exit 1
    }
    if ($content -notmatch '(?i)(###|\*\*)\s*.*FAILURE') {
        Write-Error "Missing FAILURE section in docs/task-state.md"
        exit 1
    }
    if ($content -notmatch '(?i)(assumption|default|clarif)') {
        Write-Error "docs/task-state.md must document explicit assumptions/defaults or clarifying questions"
        exit 1
    }

    if ((-not (Test-Path "exports/active_users.json")) -and (-not (Test-Path "exports/users.csv")) -and (-not (Test-Path "active_users.json"))) {
        Write-Error "Export file was not produced according to contract"
        exit 1
    }

    Write-Host "[OK] Ambiguous request correctly resolved via Prompt Contract & explicit defaults."
    exit 0
} finally {
    Set-Location $origDir
}
