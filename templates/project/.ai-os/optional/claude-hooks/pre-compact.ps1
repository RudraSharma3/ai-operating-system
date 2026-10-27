# AI-OS Claude Code Hook: PreCompact (PowerShell)
# Writes a durable state checkpoint into docs/task-state.md prior to context compaction.

$ErrorActionPreference = "SilentlyContinue"
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$taskState = Join-Path $projectDir "docs/task-state.md"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$checkpoint = @"

### Compaction Checkpoint: $timestamp
- Context window compaction initiated by Claude Code.
- Active task-state preserved across compaction boundary.
"@

$taskStateDir = Split-Path -Parent $taskState
if (-not (Test-Path $taskStateDir)) {
    New-Item -ItemType Directory -Path $taskStateDir -Force | Out-Null
}

if (Test-Path $taskState) {
    Add-Content -Path $taskState -Value $checkpoint -Encoding UTF8
    Write-Host " [AI-OS Hook] Pre-compaction checkpoint recorded into docs/task-state.md ($timestamp)"
} else {
    Set-Content -Path $taskState -Value ("# Active Task State`n" + $checkpoint) -Encoding UTF8
    Write-Host " [AI-OS Hook] Pre-compaction checkpoint initialized in docs/task-state.md"
}

exit 0
