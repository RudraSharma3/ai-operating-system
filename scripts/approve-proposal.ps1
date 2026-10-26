[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$ProposalFile,
    [switch]$PrReview
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProposalFile)) {
    Write-Error "Proposal file not found: $ProposalFile"
    exit 1
}

$proposalItem = Get-Item $ProposalFile
$proposalBasename = $proposalItem.BaseName

# HUMAN CONFIRMATION GATE
if (-not $PrReview) {
    if (-not [Environment]::UserInteractive) {
        Write-Error "approve-proposal requires interactive human confirmation or -PrReview flag.`nAutomated agents cannot approve proposals silently without human verification."
        exit 1
    }

    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host " 🚨 PROPOSAL PROMOTION HUMAN APPROVAL GATE" -ForegroundColor Yellow
    Write-Host " Proposal File: $ProposalFile" -ForegroundColor Yellow
    Write-Host " Proposal ID:   $proposalBasename" -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Yellow

    $confirmInput = Read-Host "Type '$proposalBasename' to confirm promotion"
    if ($confirmInput -ne $proposalBasename) {
        Write-Error "Confirmation string did not match '$proposalBasename'. Promotion rejected."
        exit 1
    }
    Write-Host "✅ Human confirmation verified." -ForegroundColor Green
} else {
    Write-Host "✅ Proposal approved via verified GitHub PR review." -ForegroundColor Green
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$masterRoot = Split-Path -Parent $scriptDir
$rulesDir = Join-Path $masterRoot ".ai\rules"
if (-not (Test-Path $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null
}

$lines = Get-Content $ProposalFile
$proposedLine = $null
foreach ($line in $lines) {
    if ($line -match '^`(\[[A-Z]+\]\s+.*)`') {
        $proposedLine = $Matches[1]
        break
    }
}

if (-not $proposedLine) {
    Write-Error "Could not locate proposed rule definition in $ProposalFile"
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd"
$slug = ($proposedLine -replace '^\[[A-Z]+\]\s+', '' -replace '—.*', '' -replace '-.*', '').ToLower()
$slug = ($slug -replace '[^a-z0-9]+', '-').Trim('-')
if ($slug.Length -gt 30) { $slug = $slug.Substring(0, 30) }
$ruleId = "$timestamp-$slug"
$newRulePath = Join-Path $rulesDir "$ruleId.md"

$fullRuleLine = "$ruleId. $proposedLine"

Write-Host "📝 Promoting proposal to Rule $ruleId`: $fullRuleLine" -ForegroundColor Cyan
[System.IO.File]::WriteAllText($newRulePath, "$fullRuleLine`n", (New-Object System.Text.UTF8Encoding $false))

# Archive proposal
$archiveDir = Join-Path $masterRoot "proposals\approved"
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}
Move-Item -Path $ProposalFile -Destination $archiveDir -Force
Write-Host "📦 Archived proposal to proposals/approved/" -ForegroundColor Green

# Trigger compile and build
Write-Host "🔄 Recompiling canonical AGENTS.md..." -ForegroundColor Cyan
& (Join-Path $scriptDir "compile-rules.ps1") -Project $masterRoot

Write-Host "🔄 Rebuilding templates..." -ForegroundColor Cyan
& (Join-Path $scriptDir "build-templates.ps1")

Write-Host "🎉 Proposal $proposalBasename successfully approved and promoted to canonical rule $ruleId!" -ForegroundColor Green
