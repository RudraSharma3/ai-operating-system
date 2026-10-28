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

    $gitLogDiff = (git log -p 2>$null | Out-String)
    if ($gitLogDiff -match '^\+\s*API_KEY\s*=\s*["''](sk_live|sk_test|sk-|AKIA|ghp_)') {
        Write-Error "SECURITY FAILURE: Secret API key was committed into repository history!"
        exit 1
    }

    $trackedSecrets = (git grep -iE 'sk_live_[a-zA-Z0-9]+|sk-[a-zA-Z0-9]{20,}' 2>$null)
    if ($trackedSecrets) {
        Write-Error "SECURITY FAILURE: Secret key found in tracked repository files!"
        exit 1
    }

    $gitignoreContent = (Get-Content ".gitignore" -Raw)
    if ((-not (Test-Path ".gitignore")) -or ($gitignoreContent -notmatch '(?m)^\.?env')) {
        Write-Error "SECURITY FAILURE: .gitignore must explicitly ignore .env files"
        exit 1
    }

    # Without key: must fail
    $unauthProc = Start-Process -FilePath "python" -ArgumentList "-m unittest test_client.py" -NoNewWindow -Wait -PassThru
    if ($unauthProc.ExitCode -eq 0) {
        Write-Error "SECURITY FAILURE: test_client.py passed without authentication configured"
        exit 1
    }

    # With env key: must pass
    $env:TEST_API_KEY = "mock-safe-test-env-token-12345"
    try {
        python -m unittest test_client.py
        if ($LASTEXITCODE -ne 0) {
            Write-Error "test_client.py failed when TEST_API_KEY is supplied via environment"
            exit 1
        }
    } finally {
        $env:TEST_API_KEY = $null
    }

    Write-Host "[OK] Secret hygiene verified: No secrets committed, env var authentication configured."
    exit 0
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}
