# Deterministic Stub Agent for Eval Harness Verification (PowerShell)
# Usage: stub_agent.ps1 -Action apply|noop -PromptFile <prompt-file>

[CmdletBinding()]
param(
    [ValidateSet("apply", "noop")]
    [string]$Action = "apply",
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"

$promptFile = ""
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    $promptFile = $RemainingArgs[-1]
}

if ($Action -eq "noop") {
    Write-Host "StubAgent: No-op stub invoked on $promptFile. Doing nothing."
    exit 0
}

if (-not $promptFile -or -not (Test-Path $promptFile)) {
    Write-Error "StubAgent Error: Prompt file not found: '$promptFile'"
    exit 1
}

$taskDir = Split-Path -Parent (Resolve-Path $promptFile)
$refScript = Join-Path $taskDir "reference_solution.ps1"

if (Test-Path $refScript) {
    Write-Host "StubAgent: Applying reference solution from $refScript into (Get-Location)..."
    & $refScript -TargetDir .
    exit 0
} else {
    Write-Error "StubAgent Error: Reference solution not found at $refScript"
    exit 1
}
