[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProposalFile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MasterRoot = Split-Path -Parent $ScriptDir
$ResolvedProposal = (Resolve-Path $ProposalFile).Path

if (-not (Test-Path $ResolvedProposal)) {
    Write-Error "Proposal file not found: $ProposalFile"
    exit 1
}

$rulesDir = Join-Path $MasterRoot ".ai/rules"
if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null }

$content = Get-Content $ResolvedProposal -Raw
if ($content -notmatch '`(\[[A-Z]+\]\s+[^`]+)`') {
    Write-Error "Could not locate proposed rule definition in $ProposalFile"
    exit 1
}

$proposedRuleBody = $Matches[1].Trim()

# Find next sequential rule number
$maxNum = 0
Get-ChildItem -Path $rulesDir -Filter "*.md" | ForEach-Object {
    if ($_.Name -match '^([0-9]+)-') {
        $num = [int]$Matches[1]
        if ($num -gt $maxNum) { $maxNum = $num }
    }
}

$nextNum = $maxNum + 1
$nextPadded = "{0:D4}" -f $nextNum

# Generate slug
$coreText = ($proposedRuleBody -replace '^\[[A-Z]+\]\s+', '')
$coreText = ($coreText -split '—')[0]
$coreText = ($coreText -split '-')[0].Trim()
$slug = ($coreText.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ($slug.Length -gt 35) { $slug = $slug.Substring(0, 35) }

$newRuleFileName = "$nextPadded-$slug.md"
$newRulePath = Join-Path $rulesDir $newRuleFileName
$fullRuleLine = "$nextNum. $proposedRuleBody"

Write-Host " Promoting proposal to Rule $nextNum: $fullRuleLine" -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($newRulePath, $fullRuleLine + "`n", $utf8NoBom)

# Recompile canonical AGENTS.md
Write-Host " Compiling rules into AGENTS.md..." -ForegroundColor Cyan
& (Join-Path $MasterRoot "scripts/compile-rules.ps1") -Project $MasterRoot

# Rebuild templates/project
Write-Host " Synchronizing template package..." -ForegroundColor Cyan
& (Join-Path $MasterRoot "scripts/build-templates.ps1")

# Mark proposal as approved
$updatedContent = $content -replace '(?m)\*\*Status\*\*:\s*PENDING', '**Status**: APPROVED'
$approvalRecord = @"

## Approval Record
- **Approved Date**: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
- **Canonical Rule**: Rule $nextNum (`.ai/rules/$newRuleFileName`)
"@
$updatedContent += $approvalRecord
[System.IO.File]::WriteAllText($ResolvedProposal, $updatedContent + "`n", $utf8NoBom)

Write-Host "====================================================" -ForegroundColor Gray
Write-Host " [SUCCESS] Proposal approved into Rule $nextNum!" -ForegroundColor Green
Write-Host " Location: .ai/rules/$newRuleFileName" -ForegroundColor Gray
Write-Host " AGENTS.md and templates/project are fully synchronized." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Gray
