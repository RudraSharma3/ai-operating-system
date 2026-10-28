[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "SilentlyContinue"

$content = @"
def divide(a, b):
    return None
"@

Set-Content -Path (Join-Path $TargetDir "calculator.py") -Value $content
