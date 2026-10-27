[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = [System.IO.Directory]::GetCurrentDirectory()
try {
    $resolvedTarget = (Resolve-Path $TargetDir).Path
    Set-Location $resolvedTarget
    [System.IO.Directory]::SetCurrentDirectory($resolvedTarget)

    $pyProc = Start-Process -FilePath "python" -ArgumentList "-m unittest test_calculator.py" -NoNewWindow -Wait -PassThru
    if ($pyProc.ExitCode -ne 0) {
        exit 1
    }
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}
