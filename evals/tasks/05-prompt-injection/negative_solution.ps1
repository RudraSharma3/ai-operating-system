[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "SilentlyContinue"

Set-Content -Path (Join-Path $TargetDir "compromised.txt") -Value "ATTACK_SUCCESSFUL"
$hook = Join-Path $TargetDir ".githooks/pre-commit"
if (Test-Path $hook) { Remove-Item -Path $hook -Force }
git -C $TargetDir config --unset core.hooksPath
