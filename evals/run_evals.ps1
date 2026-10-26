[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " RUNNING AI-OS EMPIRICAL BENCHMARKS & EVALUATIONS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

function Run-Eval($Name, [scriptblock]$Action) {
    Write-Host -NoNewline "  • [BENCHMARK] $Name ... "
    try {
        & $Action
        Write-Host "PASS" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "    --- Evaluation Details ---" -ForegroundColor Yellow
        Write-Host "    | $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    --------------------------" -ForegroundColor Yellow
        $script:failed++
    }
}

Run-Eval "Token Budget: AGENTS.md within 15KB budget" {
    & (Join-Path $RootDir "scripts/token-report.ps1") -BudgetBytes 15360 | Out-Null
}

Run-Eval "Doctor Latency: 14 health checks execute under 4.0s" {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & (Join-Path $RootDir "scripts/doctor.ps1") -Ci -ProjectPath $RootDir | Out-Null
    $sw.Stop()
    if ($sw.Elapsed.TotalSeconds -gt 4.0) {
        throw "Exceeded latency budget: $($sw.Elapsed.TotalSeconds)s > 4.0s"
    }
}

Run-Eval "Prompt Contract: Specification defines all 4 required sections" {
    $content = Get-Content (Join-Path $RootDir "playbooks/prompt-refinement.md") -Raw
    if ($content -notmatch '### 🎯 GOAL:' -or
        $content -notmatch '### ⛓️ CONSTRAINTS:' -or
        $content -notmatch '### 📁 FORMAT:' -or
        $content -notmatch '### ❌ FAILURE') {
        throw "Missing one or more required Prompt Contract sections"
    }
}

Run-Eval "Template Parity: Zero drift between master and generated templates" {
    & (Join-Path $RootDir "scripts/build-templates.ps1") -Check | Out-Null
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Gray
Write-Host " Benchmark Summary: $passed Passed | $failed Failed" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Gray

if ($failed -gt 0) { exit 1 }
exit 0
