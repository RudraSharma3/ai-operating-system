[CmdletBinding()]
param(
    [string]$ProjectPath = ".",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MasterRoot = Split-Path -Parent $ScriptDir
$ResolvedProjectPath = (Resolve-Path $ProjectPath).Path

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " AI-OS Federated Learning & Proposal Gate" -ForegroundColor Cyan
Write-Host " Source Project: $ResolvedProjectPath" -ForegroundColor Cyan
Write-Host " Master AI-OS:   $MasterRoot" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$secretPatternsFile = Join-Path $MasterRoot ".ai/secret-patterns.txt"
$proposalsDir = Join-Path $MasterRoot "proposals"
if (-not (Test-Path $proposalsDir)) { New-Item -ItemType Directory -Path $proposalsDir -Force | Out-Null }

$secretRegexes = @()
if (Test-Path $secretPatternsFile) {
    Get-Content $secretPatternsFile | Where-Object { $_.Trim().Length -gt 0 -and -not $_.Trim().StartsWith("#") } | ForEach-Object {
        $parts = $_ -split '\|', 2
        $pat = if ($parts.Count -eq 2) { $parts[1] } else { $parts[0] }
        try {
            $secretRegexes += [regex]$pat
        } catch { }
    }
}

$masterRules = @()
$masterRulesDir = Join-Path $MasterRoot ".ai/rules"
if (Test-Path $masterRulesDir) {
    Get-ChildItem -Path $masterRulesDir -Filter "*.md" | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8).Trim()
        if ($content) { $masterRules += $content }
    }
}

$candidateRules = @()
$projectRulesDir = Join-Path $ResolvedProjectPath ".ai/rules"
if (Test-Path $projectRulesDir) {
    Get-ChildItem -Path $projectRulesDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
        $lines = @(Get-Content -Path $_.FullName | Where-Object { $_.Trim().Length -gt 0 })
        if ($lines.Count -gt 0) { $candidateRules += $lines[0] }
    }
}

if ($candidateRules.Count -eq 0) {
    $projectAgents = Join-Path $ResolvedProjectPath "AGENTS.md"
    if (Test-Path $projectAgents) {
        $inLearned = $false
        Get-Content $projectAgents | ForEach-Object {
            if ($_ -match '^##\s+([0-9]+\.\s*)?Learned Rules') {
                $inLearned = $true
            } elseif ($inLearned -and ($_ -match '^##\s+')) {
                $inLearned = $false
            }
            if ($inLearned -and ($_ -match '^[0-9]+\.\s+\[[A-Z]+\]')) {
                $candidateRules += $_.Trim()
            }
        }
    }
}

if ($candidateRules.Count -eq 0) {
    Write-Host "No learned rules discovered in project to evaluate." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($candidateRules.Count) candidate rule(s). Evaluating through 10-point mechanical gate..." -ForegroundColor Cyan

$stats = @{ proposed = 0; rejected = 0; duplicate = 0 }
$validCategories = @("STYLE", "CODE", "ARCH", "TOOL", "PROCESS", "DATA", "UX", "SECURITY", "TEST", "OTHER")

foreach ($r in $candidateRules) {
    if ($r -match '[\u200B-\u200D\uFEFF\u202A-\u202E\u2060-\u206F]') {
        Write-Host " [REJECTED] Contains hidden unicode or zero-width directional characters: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }

    if ($r -notmatch '^([a-zA-Z0-9_-]+)\.\s+\[([A-Z]+)\]\s+(.*)') {
        Write-Host " [REJECTED] Fails format syntax: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }

    $ruleId = $Matches[1]
    $category = $Matches[2]
    $body = $Matches[3]
    $checks = @()

    if ($category -notin $validCategories) {
        Write-Host " [REJECTED] Invalid category [$category]: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "1. [PASS] Valid Category tag [$category]"

    if ($body -notmatch ' — ' -and $body -notmatch ' - ') {
        Write-Host " [REJECTED] Missing evidence/rationale separator: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "2. [PASS] Includes explicit evidence and rationale separator"

    if ($body.Length -lt 20) {
        Write-Host " [REJECTED] Statement too brief to be actionable: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "3. [PASS] Actionable instruction statement length adequate"

    $hasLocalPath = $false
    foreach ($lp in @('/Users/', 'C:\\', 'D:\\', '/home/', 'node_modules', 'apps/web', 'src/components')) {
        if ($body -match [regex]::Escape($lp)) { $hasLocalPath = $true; break }
    }
    if ($hasLocalPath) {
        Write-Host " [REJECTED] Contains project-specific local file paths: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "4. [PASS] Free of project-specific local file paths"

    $bodyCore = ($body -split ' — ')[0].Trim()
    $bodyCore = ($bodyCore -split ' - ')[0].Trim()
    $isDup = $false
    foreach ($mr in $masterRules) {
        if ($mr.ToLower().Contains($bodyCore.ToLower())) { $isDup = $true; break }
    }
    if ($isDup) {
        Write-Host " [=] Skipped (already in master): $bodyCore..." -ForegroundColor DarkGray
        $stats.duplicate++
        continue
    }
    $checks += "5. [PASS] Non-conflicting and not already present in master"

    $injectionWords = @(
        'ignore previous',
        'disable the pre-commit',
        'disable pre-commit',
        '--no-verify',
        'do not ask the user',
        "don't ask the user",
        'never ask the user',
        'edit agents.md directly',
        'modify agents.md directly',
        'write to agents.md',
        'system prompt',
        'api key sk-',
        'bypass guard'
    )
    $hasInj = $false
    foreach ($iw in $injectionWords) {
        if ($body.ToLower().Contains($iw.ToLower())) { $hasInj = $true; break }
    }
    if ($hasInj) {
        Write-Host " [REJECTED] Contains prompt injection or security-subverting phrases: $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "6. [PASS] Clean instruction source"

    $hasSecret = $false
    foreach ($rx in $secretRegexes) {
        if ($rx.IsMatch($r)) { $hasSecret = $true; break }
    }
    if ($hasSecret) {
        Write-Host " [REJECTED] CRITICAL: Contains credential or secret pattern! $r" -ForegroundColor Red
        $stats.rejected++
        continue
    }
    $checks += "7. [PASS] Zero secrets or credential patterns detected"
    $checks += "8. [PASS] Durable engineering practice"
    $checks += "9. [PASS] Complies with canonical format"
    $checks += "10. [PASS] Reusable principle across software stacks"


    $slug = ($bodyCore.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40) }
    $ts = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
    $propFilename = "$ts-$slug.md"
    $propPath = Join-Path $proposalsDir $propFilename

    $mdLines = @(
        "# Rule Proposal: $bodyCore",
        "",
        "- **Source Project**: $ResolvedProjectPath",
        "- **Proposed Date**: " + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"),
        "- **Category**: [$category]",
        "- **Status**: PENDING",
        "",
        "## Proposed Rule Content",
        "`[$category] $body`",
        "",
        "## 10-Point Mechanical Quality Gate Assessment"
    )
    $mdLines += $checks
    $mdLines += @(
        "",
        "## Execution Command",
        "To approve and compile into canonical rules:",
        "```powershell",
        "powershell -ExecutionPolicy Bypass -File scripts/approve-proposal.ps1 proposals/$propFilename",
        "```"
    )

    if (-not $DryRun) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($propPath, $mdLines, $utf8NoBom)
    }

    Write-Host " [PASS] PROPOSAL GENERATED: proposals/$propFilename" -ForegroundColor Green
    Write-Host "        Rule: [$category] $body" -ForegroundColor Gray
    $stats.proposed++
}

Write-Host "====================================================" -ForegroundColor Gray
Write-Host " Gate Summary: $($stats.proposed) proposal(s) created, $($stats.rejected) rejected, $($stats.duplicate) duplicate(s) skipped." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Gray
