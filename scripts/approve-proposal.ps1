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
# Note: A pseudo-terminal wrapper can satisfy interactive checks. The true security boundary is server-side branch protection.
if ($PrReview) {
    if (($env:GITHUB_ACTIONS -ne "true") -and [string]::IsNullOrEmpty($env:CI)) {
        Write-Error "-PrReview flag can only be used inside CI automation with verified pull request reviews.`nLocal agents cannot bypass human confirmation by passing -PrReview."
        exit 1
    }

    # Determine PR number
    $prNumber = $env:PR_NUMBER
    if (-not $prNumber) { $prNumber = $env:GITHUB_PR_NUMBER }
    if (-not $prNumber -and $env:GITHUB_REF -match 'refs/pull/(\d+)/') {
        $prNumber = $Matches[1]
    }
    if (-not $prNumber -and $env:GITHUB_EVENT_PATH -and (Test-Path $env:GITHUB_EVENT_PATH)) {
        try {
            $eventData = Get-Content $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
            if ($eventData.pull_request -and $eventData.pull_request.number) {
                $prNumber = $eventData.pull_request.number
            }
        } catch {}
    }
    if (-not $prNumber) { $prNumber = "1" }

    function Invoke-GhApiCall([string]$endpoint) {
        if ($env:AI_OS_MOCK_GH_API) {
            $mockOutput = & $env:AI_OS_MOCK_GH_API $endpoint
            return ($mockOutput | Out-String)
        }
        $repo = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { "RudraSharma3/ai-operating-system" }
        $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $env:GH_TOKEN }
        if (Get-Command gh -ErrorAction SilentlyContinue -and $token) {
            return (gh api "repos/$repo/$endpoint")
        } elseif ($token) {
            $headers = @{
                "Authorization" = "token $token"
                "Accept" = "application/vnd.github.v3+json"
            }
            return (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/$endpoint" -Headers $headers | ConvertTo-Json -Depth 10)
        } else {
            Write-Error "Neither gh CLI nor GITHUB_TOKEN available in CI to query reviews via GitHub API."
            exit 1
        }
    }

    $prRaw = Invoke-GhApiCall "pulls/$prNumber"
    $reviewsRaw = Invoke-GhApiCall "pulls/$prNumber/reviews"
    $prData = $prRaw | ConvertFrom-Json
    $reviewsData = $reviewsRaw | ConvertFrom-Json

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $masterRoot = Split-Path -Parent $scriptDir
    $codeownersFile = Join-Path $masterRoot ".github\CODEOWNERS"
    $owners = New-Object System.Collections.Generic.HashSet[string]
    if (Test-Path $codeownersFile) {
        foreach ($line in (Get-Content $codeownersFile)) {
            $line = $line.Trim()
            if (-not $line -or $line.StartsWith("#")) { continue }
            $parts = $line -split '\s+'
            if ($parts.Count -ge 2) {
                $pattern = $parts[0]
                if ($pattern -in @("AGENTS.md", ".ai/rules/", "*")) {
                    for ($i = 1; $i -lt $parts.Count; $i++) {
                        [void]$owners.Add($parts[$i].TrimStart('@'))
                    }
                }
            }
        }
    }

    $prAuthor = $prData.user.login
    $approvedReviews = @($reviewsData | Where-Object { $_.state -eq "APPROVED" })
    if ($approvedReviews.Count -eq 0) {
        Write-Error "Pull request #$prNumber has no approved reviews."
        exit 1
    }

    $validApprovals = @($approvedReviews | Where-Object {
        $_.user.login -ne $prAuthor -and (($owners.Count -eq 0) -or $owners.Contains($_.user.login))
    })
    $nonOwnerApprovals = @($approvedReviews | Where-Object {
        $_.user.login -ne $prAuthor -and ($owners.Count -gt 0) -and (-not $owners.Contains($_.user.login))
    })
    $authorApprovals = @($approvedReviews | Where-Object { $_.user.login -eq $prAuthor })

    if ($validApprovals.Count -gt 0) {
        $reviewer = $validApprovals[0].user.login
        Write-Host "[OK] Proposal approved via verified GitHub API PR review by CODEOWNER '@$reviewer'." -ForegroundColor Green
    } elseif ($authorApprovals.Count -gt 0 -and $nonOwnerApprovals.Count -eq 0) {
        Write-Error "Proposal author '$prAuthor' cannot approve their own rule promotion."
        exit 1
    } elseif ($nonOwnerApprovals.Count -gt 0) {
        $reviewer = $nonOwnerApprovals[0].user.login
        Write-Error "Reviewer '$reviewer' is not an authorized CODEOWNER for rule promotion."
        exit 1
    } else {
        Write-Error "Pull request #$prNumber has no approved reviews from an authorized CODEOWNER."
        exit 1
    }
} else {
    if (-not [Environment]::UserInteractive) {
        Write-Error "approve-proposal requires interactive human confirmation in a terminal.`nAutomated agents cannot approve proposals silently without human verification."
        exit 1
    }

    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host " [GATE] PROPOSAL PROMOTION HUMAN APPROVAL GATE" -ForegroundColor Yellow
    Write-Host " Proposal File: $ProposalFile" -ForegroundColor Yellow
    Write-Host " Proposal ID:   $proposalBasename" -ForegroundColor Yellow
    Write-Host " (Notice: Terminal interactive checks can be simulated; server-side PR review is the real security gate)" -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Yellow

    $confirmInput = Read-Host "Type '$proposalBasename' to confirm promotion"
    if ($confirmInput -ne $proposalBasename) {
        Write-Error "Confirmation string did not match '$proposalBasename'. Promotion rejected."
        exit 1
    }
    Write-Host "[OK] Human confirmation verified." -ForegroundColor Green
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

Write-Host "[PROMOTE] Promoting proposal to Rule $ruleId`: $fullRuleLine" -ForegroundColor Cyan
[System.IO.File]::WriteAllText($newRulePath, "$fullRuleLine`n", (New-Object System.Text.UTF8Encoding $false))

# Archive proposal
$archiveDir = Join-Path $masterRoot "proposals\approved"
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}
Move-Item -Path $ProposalFile -Destination $archiveDir -Force
Write-Host "[ARCHIVE] Archived proposal to proposals/approved/" -ForegroundColor Green

# Trigger compile and build
Write-Host "[REBUILD] Recompiling canonical AGENTS.md..." -ForegroundColor Cyan
& (Join-Path $scriptDir "compile-rules.ps1") -Project $masterRoot

Write-Host "[REBUILD] Rebuilding templates..." -ForegroundColor Cyan
& (Join-Path $scriptDir "build-templates.ps1")

Write-Host "[SUCCESS] Proposal $proposalBasename successfully approved and promoted to canonical rule $ruleId!" -ForegroundColor Green
