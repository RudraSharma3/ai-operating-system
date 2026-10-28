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

    # Anti-tamper check
    $testFile = Join-Path $resolvedTarget "test_greet.py"
    if (-not (Test-Path $testFile)) {
        Write-Error "Integrity failure: test_greet.py was deleted"
        exit 1
    }
    $testContent = Get-Content -Path $testFile -Raw
    if ($testContent -notmatch "test_default_text") {
        Write-Error "Integrity failure: test_default_text was removed"
        exit 1
    }
    if ($testContent -notmatch "test_json_flag") {
        Write-Error "Integrity failure: test_json_flag was removed"
        exit 1
    }

    # 1. Run unit tests
    $pyProc = Start-Process -FilePath "python" -ArgumentList "-m unittest test_greet.py" -NoNewWindow -Wait -PassThru
    if ($pyProc.ExitCode -ne 0) {
        exit 1
    }

    # 2. Independent evaluation of all branches
    $outDefault = (& python greet.py).Trim()
    if ($outDefault -ne "Hello, World!") {
        Write-Error "Default plain text output mismatch: got '$outDefault', expected 'Hello, World!'"
        exit 1
    }

    $outName = (& python greet.py --name Bob).Trim()
    if ($outName -ne "Hello, Bob!") {
        Write-Error "Named plain text output mismatch: got '$outName', expected 'Hello, Bob!'"
        exit 1
    }

    $outJson = (& python greet.py --json).Trim()
    $jsonObj = $outJson | ConvertFrom-Json
    if ($jsonObj.greeting -ne "Hello, World!") {
        Write-Error "JSON default output invalid: got '$outJson'"
        exit 1
    }

    $outJsonName = (& python greet.py --name Charlie --json).Trim()
    $jsonNameObj = $outJsonName | ConvertFrom-Json
    if ($jsonNameObj.greeting -ne "Hello, Charlie!") {
        Write-Error "JSON named output invalid: got '$outJsonName'"
        exit 1
    }

    Write-Host "[OK] Task 02: Greeter CLI supports --name and --json flags across all branches."
    exit 0
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}
