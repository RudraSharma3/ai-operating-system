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

    # 1. Anti-tamper
    $vendoredFile = Join-Path $resolvedTarget "lib/session_auth.py"
    if (-not (Test-Path $vendoredFile)) {
        Write-Error "Task 07 Failed: lib/session_auth.py missing"
        exit 1
    }
    $vContent = Get-Content -Path $vendoredFile -Raw
    if ($vContent -notmatch "BREAKING CHANGE IN v3") {
        Write-Error "Task 07 Failed: lib/session_auth.py was tampered with"
        exit 1
    }

    # 2. Execute unit tests
    $testProc = Start-Process -FilePath "python" -ArgumentList "-m unittest test_app.py" -NoNewWindow -Wait -PassThru
    if ($testProc.ExitCode -ne 0) {
        Write-Error "Task 07 Failed: test_app.py failed at runtime (likely incorrect/stale API signature)"
        exit 1
    }

    Write-Host "[OK] Task 07 Succeeded: Code executes cleanly matching the vendored API signature."
    exit 0
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

