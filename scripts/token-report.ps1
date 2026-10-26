[CmdletBinding()]
param(
    [switch]$Json,
    [int]$BudgetBytes = 15360
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

$targetFiles = @(
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "CODEX.md",
    ".cursorrules",
    ".github/copilot-instructions.md",
    ".ai/routing.md",
    "templates/project/AGENTS.md"
)

Get-ChildItem -Path (Join-Path $RootDir "playbooks") -Filter "*.md" | Sort-Object Name | ForEach-Object {
    $targetFiles += "playbooks/" + $_.Name
}
Get-ChildItem -Path (Join-Path $RootDir "prompts") -Filter "*.md" | Sort-Object Name | ForEach-Object {
    $targetFiles += "prompts/" + $_.Name
}

$report = @()
$totalBytes = 0
$totalChars = 0
$totalLines = 0
$totalTokens = 0

foreach ($rel in $targetFiles) {
    $fullPath = Join-Path $RootDir $rel
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath
        $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
        
        $bCount = $item.Length
        $cCount = $content.Length
        $lines = @($content -split "`r?`n")
        $lCount = $lines.Count
        $words = @($content -split '\s+' | Where-Object { $_.Length -gt 0 })
        $wCount = $words.Count
        $tEst = [int][Math]::Round($cCount / 4.0)

        $report += [PSCustomObject]@{
            File = $rel
            Bytes = $bCount
            Lines = $lCount
            Words = $wCount
            EstTokens = $tEst
        }

        $totalBytes += $bCount
        $totalChars += $cCount
        $totalLines += $lCount
        $totalTokens += $tEst
    }
}

$agentsPath = Join-Path $RootDir "AGENTS.md"
$agentsBytes = if (Test-Path $agentsPath) { (Get-Item $agentsPath).Length } else { 0 }
$budgetPass = $agentsBytes -le $BudgetBytes

if ($Json) {
    $outObj = [PSCustomObject]@{
        budget_limit_bytes = $BudgetBytes
        canonical_agents_bytes = $agentsBytes
        budget_pass = $budgetPass
        total_files = $report.Count
        total_bytes = $totalBytes
        total_lines = $totalLines
        total_est_tokens = $totalTokens
        files = $report
    }
    Write-Output ($outObj | ConvertTo-Json -Depth 3)
} else {
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host " AI-OS Empirical Token & Footprint Measurement Report" -ForegroundColor Cyan
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host ("{0,-45} | {1,7} | {2,6} | {3,6} | {4,11}" -f "File", "Bytes", "Lines", "Words", "Est. Tokens") -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor Gray
    foreach ($r in $report) {
        Write-Host ("{0,-45} | {1,7} | {2,6} | {3,6} | {4,11}" -f $r.File, $r.Bytes, $r.Lines, $r.Words, $r.EstTokens)
    }
    Write-Host "========================================================================================" -ForegroundColor Gray
    Write-Host ("{0,-45} | {1,7} | {2,6} | {3,6} | {4,11}" -f "TOTALS", $totalBytes, $totalLines, "-", $totalTokens) -ForegroundColor Yellow
    Write-Host "========================================================================================" -ForegroundColor Gray

    $statusStr = if ($budgetPass) { "[PASS]" } else { "[FAIL]" }
    $color = if ($budgetPass) { "Green" } else { "Red" }
    Write-Host " $statusStr Canonical AGENTS.md Budget Check: $agentsBytes bytes / limit $BudgetBytes bytes (~$([int][Math]::Round($agentsBytes / 4.0)) est. tokens)" -ForegroundColor $color
    Write-Host "========================================================================================" -ForegroundColor Gray
}

if (-not $budgetPass) {
    exit 1
}
