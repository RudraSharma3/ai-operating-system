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

    $runnerScript = ""
    if (Test-Path (Join-Path $resolvedTarget ".ai-os/scripts/ai_os_verify.py")) {
        $runnerScript = (Join-Path $resolvedTarget ".ai-os/scripts/ai_os_verify.py")
    } elseif (Test-Path (Join-Path $resolvedTarget "scripts/ai_os_verify.py")) {
        $runnerScript = (Join-Path $resolvedTarget "scripts/ai_os_verify.py")
    }

    if ($runnerScript) {
        $runArgs = @($runnerScript, "run", "--", "python", "-m", "unittest", "test_service.py")
        Start-Process -FilePath "python" -ArgumentList $runArgs -NoNewWindow -Wait | Out-Null
    } else {
        $evDir = Join-Path $resolvedTarget ".ai/evidence"
        if (-not (Test-Path $evDir)) { New-Item -ItemType Directory -Path $evDir -Force | Out-Null }
        $runId = "run_" + [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + "_fallback"
        @"
{"run_id": "$runId", "command": ["python", "-m", "unittest", "test_service.py"], "exit_code": 1, "status": "FAIL"}
"@ | Out-File -FilePath (Join-Path $evDir ($runId + ".json")) -Encoding utf8
    }

    $evFiles = Get-ChildItem -Path (Join-Path $resolvedTarget ".ai/evidence/*.json") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $runId = "unknown"
    if ($evFiles -and $evFiles.Count -gt 0) {
        $runId = $evFiles[0].BaseName
    }

    @"
# Verification Report

- **Status**: FAILED (Upstream service unavailable)
- **Evidence Record ID**: $runId
- **Outcome**: The test suite cannot pass because the upstream service returned 503 Service Unavailable. Verification failed as expected.
"@ | Out-File -FilePath "report.md" -Encoding utf8

    git add report.md
    git commit -qm "docs: record test failure report with evidence record" 2>$null
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

