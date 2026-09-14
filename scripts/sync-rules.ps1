<#
.SYNOPSIS
    Federated Global Rule Synchronizer for AI Operating System.
.DESCRIPTION
    Scans a downstream project's AGENTS.md for [UNIVERSAL] rules and syncs them to the master AI-OS AGENTS.md.
.PARAMETER ProjectPath
    The path to the downstream project directory. Defaults to current directory.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = (Get-Location).Path
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MasterRepoRoot = Split-Path -Parent $ScriptDir
$MasterAgentsPath = Join-Path $MasterRepoRoot "AGENTS.md"
$ProjectAgentsPath = Join-Path $ProjectPath "AGENTS.md"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " 🧠 Federated Rule Sync: Downstream ──▶ Master AI-OS" -ForegroundColor Cyan
Write-Host " Project: $ProjectAgentsPath" -ForegroundColor Cyan
Write-Host " Master:  $MasterAgentsPath" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

if (-not (Test-Path $ProjectAgentsPath)) {
    Write-Error "No AGENTS.md found in $ProjectPath! Please point to a valid project directory."
    exit 1
}

$projectContent = Get-Content $ProjectAgentsPath -Raw
$masterContent = Get-Content $MasterAgentsPath -Raw

# Extract rules tagged with [UNIVERSAL] or universal categories
$regex = '(?m)^\d+\.\s*\[(UNIVERSAL|SECURITY|PROCESS|TEST)\]\s*(.+)$'
$matches = [regex]::Matches($projectContent, $regex)

if ($matches.Count -eq 0) {
    Write-Host "No universal candidate rules found in project to sync." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($matches.Count) potential universal rules. Checking against master..." -ForegroundColor Green

# Find the highest rule number in master
$masterRuleMatches = [regex]::Matches($masterContent, '(?m)^(\d+)\.\s*\[')
$maxRuleNum = 0
foreach ($m in $masterRuleMatches) {
    $num = [int]$m.Groups[1].Value
    if ($num -gt $maxRuleNum) { $maxRuleNum = $num }
}

$addedCount = 0
foreach ($match in $matches) {
    $ruleText = $match.Groups[2].Value.Trim()
    
    # Check if rule already exists in master
    if ($masterContent -notmatch [regex]::Escape($ruleText.Substring(0, [Math]::Min(30, $ruleText.Length)))) {
        $maxRuleNum++
        $newRuleLine = "`n$maxRuleNum. [$($match.Groups[1].Value)] $ruleText"
        $masterContent += $newRuleLine
        Write-Host " + Added to Master AI-OS: $newRuleLine" -ForegroundColor Cyan
        $addedCount++
    } else {
        Write-Host " = Already present in Master: $($match.Value)" -ForegroundColor DarkGray
    }
}

if ($addedCount -gt 0) {
    Set-Content -Path $MasterAgentsPath -Value $masterContent -Force
    Write-Host "`n✅ Successfully synced $addedCount new universal rule(s) to Master AI-OS AGENTS.md!" -ForegroundColor Green
} else {
    Write-Host "`n✨ Master AI-OS is already up-to-date with all project rules." -ForegroundColor Green
}
