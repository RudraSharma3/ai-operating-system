# AI Operating System Verifier CLI Wrapper (PowerShell)
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonScript = Join-Path $scriptDir "ai_os_verify.py"

$pythonBin = if ($env:AI_OS_PYTHON_BIN) { $env:AI_OS_PYTHON_BIN } else { "python" }

$cmdExists = Get-Command $pythonBin -ErrorAction SilentlyContinue
if (-not $cmdExists) {
    $cmdExists = Get-Command "python3" -ErrorAction SilentlyContinue
    if ($cmdExists) {
        $pythonBin = "python3"
    } else {
        Write-Error "[AI-OS Verifier] Python (3.9+) is required but was not found in PATH."
        exit 1
    }
}

& $pythonBin $pythonScript @RemainingArgs
exit $LASTEXITCODE

