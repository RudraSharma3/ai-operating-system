[CmdletBinding()]
param()
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "health\run_evals.ps1") @args
