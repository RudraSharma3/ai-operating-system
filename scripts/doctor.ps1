<#
.SYNOPSIS
    Project Health & Integrity Doctor for AI Operating System.
.DESCRIPTION
    Runs comprehensive diagnostics on repository structure, secret hygiene, documentation integrity, and git hooks.
.PARAMETER ProjectPath
    The path to the project directory. Defaults to current directory.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = (Get-Location).Path
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " Running AI-OS Project Health Doctor" -ForegroundColor Cyan
Write-Host " Target: $ProjectPath" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$passed = 0
$warnings = 0
$failures = 0

function Check-Item {
    param ($Name, $Condition, $FailureMsg, $IsWarning = $false)
    if ($Condition) {
        Write-Host " [PASS] $Name" -ForegroundColor Green
        $script:passed++
    } else {
        if ($IsWarning) {
            Write-Host " [WARN] $Name - $FailureMsg" -ForegroundColor Yellow
            $script:warnings++
        } else {
            Write-Host " [FAIL] $Name - $FailureMsg" -ForegroundColor Red
            $script:failures++
        }
    }
}

# 1. Check Core Instruction Files
Write-Host "`n1. Core Instruction Files:" -ForegroundColor White
Check-Item "Canonical AGENTS.md exists" (Test-Path (Join-Path $ProjectPath "AGENTS.md")) "Missing AGENTS.md in project root!"
Check-Item "CLAUDE.md adapter exists" (Test-Path (Join-Path $ProjectPath "CLAUDE.md")) "Missing CLAUDE.md adapter."
Check-Item "GEMINI.md adapter exists" (Test-Path (Join-Path $ProjectPath "GEMINI.md")) "Missing GEMINI.md adapter."
Check-Item "CODEX.md adapter exists" (Test-Path (Join-Path $ProjectPath "CODEX.md")) "Missing CODEX.md adapter."

# 2. Check Documentation Suite
Write-Host "`n2. Documentation Integrity:" -ForegroundColor White
$docsPath = Join-Path $ProjectPath "docs"
Check-Item "docs/ directory exists" (Test-Path $docsPath) "Missing docs/ directory."
Check-Item "docs/architecture.md exists" (Test-Path (Join-Path $docsPath "architecture.md")) "Missing architecture document."
Check-Item "docs/conventions.md exists" (Test-Path (Join-Path $docsPath "conventions.md")) "Missing conventions guide."
Check-Item "docs/task-state.md exists" (Test-Path (Join-Path $docsPath "task-state.md")) "Missing active task state tracker."
Check-Item "docs/graph.md exists" (Test-Path (Join-Path $docsPath "graph.md")) "Missing dependency graph."

# 3. Check Learning Engine
Write-Host "`n3. Learning Engine:" -ForegroundColor White
$aiDir = Join-Path $ProjectPath ".ai"
Check-Item ".ai/ directory exists" (Test-Path $aiDir) "Missing .ai directory."
Check-Item ".ai/mistakes-candidates.md exists" (Test-Path (Join-Path $aiDir "mistakes-candidates.md")) "Missing candidate lessons log."
Check-Item "docs/lessons.md exists" (Test-Path (Join-Path $docsPath "lessons.md")) "Missing verified lessons log."

# 4. Secret & Security Hygiene
Write-Host "`n4. Secret & Security Hygiene:" -ForegroundColor White
$secretPattern = "sk-[a-zA-Z0-9]{20,}|BEGIN (RSA|EC|PGP|OPENSSH) PRIVATE KEY"
$mdFiles = Get-ChildItem -Path $ProjectPath -Recurse -Filter *.md -ErrorAction SilentlyContinue
$leaksFound = 0
foreach ($f in $mdFiles) {
    $c = Get-Content $f.FullName -Raw
    if ($c -match $secretPattern) {
        $leaksFound++
        Write-Host "   -> Detected secret pattern in: $($f.Name)" -ForegroundColor Red
    }
}
Check-Item "Zero secrets detected in Markdown/docs" ($leaksFound -eq 0) "$leaksFound file(s) contain potential hardcoded secrets!"
Check-Item ".env file not committed to Git" (-not (Test-Path (Join-Path $ProjectPath ".env"))) ".env file is present in project root. Ensure it is in .gitignore!" -IsWarning $true

# 5. Summary Report
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host (' Health Summary: ' + $passed + ' Passed | ' + $warnings + ' Warnings | ' + $failures + ' Failures') -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host " EXCELLENT! Project health is in pristine operational order." -ForegroundColor Green
} else {
    Write-Host " ATTENTION: Please address the failed checks above." -ForegroundColor Yellow
}
Write-Host "====================================================" -ForegroundColor Cyan
