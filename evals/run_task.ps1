[CmdletBinding()]
param(
    [string]$Task = "all",
    [ValidateSet("with", "without")]
    [string]$Mode = "with",
    [string]$AgentCmd = "",
    [switch]$Reference,
    [switch]$Negative,
    [switch]$ExpectFail,
    [switch]$CheckOnly,
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TasksDir = Join-Path $ScriptDir "tasks"

function Run-SingleTask([string]$tDir) {
    $tName = Split-Path -Leaf $tDir
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " Running Eval Task: $tName (Mode: $Mode)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    $sandbox = $TargetDir
    $cleanupNeeded = $false
    if (-not $sandbox) {
        $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("aios_eval_" + [System.Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
        $cleanupNeeded = $true
    } else {
        if (-not (Test-Path $sandbox)) {
            New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
        }
    }

    $realSandbox = (Resolve-Path $sandbox).Path
    $realRoot = (Resolve-Path $RootDir).Path

    # 1. Refuse if sandbox is inside the repository tree
    if ($realSandbox.StartsWith($realRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Error "Evaluation sandbox '$sandbox' is located inside repository tree ($realRoot)."
        if ($cleanupNeeded -and (Test-Path $sandbox)) { Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
        $script:currentTaskPassed = $false
        return $false
    }

    # 2. Refuse if sandbox is inside any parent directory containing other git repositories
    $parentDir = Split-Path $realSandbox -Parent
    $checkDir = $parentDir
    $insideParent = $false
    while ($checkDir -and (Test-Path $checkDir)) {
        if (Test-Path (Join-Path $checkDir ".git")) {
            $insideParent = $true
            break
        }
        $next = Split-Path $checkDir -Parent
        if (-not $next -or $next -eq $checkDir) { break }
        $checkDir = $next
    }
    if ($insideParent) {
        Write-Error "Evaluation sandbox '$sandbox' is located inside an existing parent git repository ($checkDir)."
        if ($cleanupNeeded -and (Test-Path $sandbox)) { Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
        $script:currentTaskPassed = $false
        return $false
    }

    # 3. Refuse --dangerously-skip-permissions unless AI_OS_EVAL_SANDBOX=1
    if ($AgentCmd -match '--dangerously-skip-permissions') {
        if ($env:AI_OS_EVAL_SANDBOX -ne "1") {
            Write-Error "Refusing to run agent command with --dangerously-skip-permissions without AI_OS_EVAL_SANDBOX=1."
            if ($cleanupNeeded -and (Test-Path $sandbox)) { Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
            $script:currentTaskPassed = $false
            return $false
        }
    }

    $setupScript = Join-Path $tDir "setup.ps1"
    $checkScript = Join-Path $tDir "check.ps1"
    $refScript = Join-Path $tDir "reference_solution.ps1"
    $negScript = Join-Path $tDir "negative_solution.ps1"
    $promptFile = Join-Path $tDir "prompt.md"

    if (-not $CheckOnly) {
        Write-Host "Setting up fixture repository..." -ForegroundColor Gray
        & $setupScript -TargetDir $sandbox

        if ($Mode -eq "with") {
            Write-Host "Installing AI-OS into fixture repository..." -ForegroundColor Gray
            & (Join-Path $RootDir "scripts/install.ps1") -TargetPath $sandbox | Out-Null
        }

        if ($Reference) {
            Write-Host "Applying reference solution..." -ForegroundColor Gray
            & $refScript -TargetDir $sandbox
        } elseif ($Negative) {
            Write-Host "Applying negative-control solution..." -ForegroundColor Gray
            & $negScript -TargetDir $sandbox
        } elseif ($AgentCmd) {
            Write-Host "Executing agent command: $AgentCmd (with secret environment stripped)..." -ForegroundColor Gray
            $secretVars = Get-ChildItem Env: | Where-Object { $_.Name -match '(?i)(KEY|TOKEN|SECRET|PASSWORD|^AWS_|^AZURE_|^GOOGLE_|^GCP_)' }
            & {
                foreach ($sv in $secretVars) {
                    Remove-Item "Env:$($sv.Name)" -ErrorAction SilentlyContinue
                }
                $orig = Get-Location
                try {
                    Set-Location $sandbox
                    Invoke-Expression "$AgentCmd `"$promptFile`""
                } finally {
                    Set-Location $orig
                }
            }
        } else {
            Write-Host "Untouched fixture evaluation (no agent command or reference solution)." -ForegroundColor Gray
        }
    }

    Write-Host "Running evaluation check..." -ForegroundColor Gray
    $checkPassed = $false
    $checkErr = ""
    try {
        powershell.exe -ExecutionPolicy Bypass -File $checkScript -TargetDir $sandbox
        if ($LASTEXITCODE -eq 0) {
            $checkPassed = $true
        } else {
            $checkPassed = $false
            $checkErr = "Check script failed with exit code $LASTEXITCODE"
        }
    } catch {
        $checkPassed = $false
        $checkErr = $_.Exception.Message
    }

    if ($checkPassed) {
        Write-Host "[OK] Task $tName Result: PASS" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Task $tName Result: FAIL" -ForegroundColor Red
        if ($checkErr) {
            Write-Host "   | $checkErr" -ForegroundColor Yellow
        }
    }

    if ($cleanupNeeded -and (Test-Path $sandbox)) {
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    $script:currentTaskPassed = $checkPassed
    return $checkPassed
}

$tasksToRun = @()
if ($Task -eq "all") {
    $tasksToRun = Get-ChildItem -Path $TasksDir -Directory | Sort-Object Name
} else {
    $matched = Join-Path $TasksDir $Task
    if (Test-Path $matched) {
        $tasksToRun = @(Get-Item $matched)
    } elseif (Test-Path $Task) {
        $tasksToRun = @(Get-Item $Task)
    } else {
        Write-Error "Task '$Task' not found in $TasksDir"
        exit 1
    }
}

$total = 0
$passed = 0
$failed = 0

foreach ($t in $tasksToRun) {
    $total++
    $script:currentTaskPassed = $false
    Run-SingleTask $t.FullName | Out-Host
    if ($script:currentTaskPassed) {
        $passed++
    } else {
        $failed++
    }
}

Write-Host "============================================================" -ForegroundColor Gray
Write-Host " Task Suite Summary: $passed Passed | $failed Failed (Total: $total)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Gray

if ($ExpectFail) {
    Write-Host "============================================================" -ForegroundColor Gray
    Write-Host " Negative Control Expectation: Expecting all tasks to FAIL" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Gray
    if ($passed -eq 0 -and $failed -eq $total) {
        Write-Host " [PASS] Negative Control Suite: All $total negative controls correctly rejected (exit 0)." -ForegroundColor Green
        exit 0
    } else {
        Write-Host " [FAIL] Negative Control Suite: Expected all negative controls to fail, but $passed passed!" -ForegroundColor Red
        exit 1
    }
}

if ($failed -gt 0) {
    exit 1
}
exit 0
