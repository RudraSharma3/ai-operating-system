[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = Get-Location
try {
    Set-Location $TargetDir
    if (-not (Test-Path "docs")) { New-Item -ItemType Directory -Path "docs" -Force | Out-Null }
    if (-not (Test-Path "exports")) { New-Item -ItemType Directory -Path "exports" -Force | Out-Null }

    @'
# Active Task State: Export Active Users

## Stated Safe Defaults & Assumptions
- Format defaulted to JSON (`exports/active_users.json`).
- Filter: only accounts with status == "active".

## Prompt Contract
### GOAL:
Export all active user accounts from users.json into exports/active_users.json.

### CONSTRAINTS:
- Retain id and username attributes.
- Filter out inactive status accounts.
- Output must be valid JSON.

### FORMAT:
`exports/active_users.json`

### FAILURE:
- Crashing on empty input.
- Missing active accounts.
- Exporting inactive accounts.
'@ | Set-Content -Path "docs/task-state.md" -Encoding UTF8

    $users = Get-Content "users.json" -Raw | ConvertFrom-Json
    $active = @($users | Where-Object { $_.status -eq "active" })
    $active | ConvertTo-Json -Depth 5 | Set-Content -Path "exports/active_users.json" -Encoding UTF8

    git add docs/task-state.md exports/active_users.json
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "feat: export active users adhering to prompt contract"
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
}
