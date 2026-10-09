[CmdletBinding()]
param(
    [string]$Project = ".",
    [switch]$Check,
    [switch]$Stdout
)

$ErrorActionPreference = "Stop"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$projectPath = (Resolve-Path $Project).Path
$rulesDir = Join-Path $projectPath ".ai/rules"
$agentsFile = Join-Path $projectPath "AGENTS.md"

if (-not (Test-Path $rulesDir)) {
    Write-Error "Rules directory not found at $rulesDir"
    exit 1
}

if (-not (Test-Path $agentsFile)) {
    Write-Error "AGENTS.md not found at $agentsFile"
    exit 1
}

$ruleFiles = Get-ChildItem -Path $rulesDir -Filter "*.md" | Sort-Object Name

if ($ruleFiles.Count -eq 0) {
    Write-Warning "No rule files found in $rulesDir"
    exit 0
}

$compiledRules = @()
$expectedNum = 1

foreach ($rf in $ruleFiles) {
    $rawText = [System.IO.File]::ReadAllText($rf.FullName, [System.Text.Encoding]::UTF8)
    $lines = @($rawText -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 })
    if ($lines.Count -eq 0) { continue }

    $firstLine = $lines[0]
    if ($firstLine -notmatch '^([0-9]+)\.\s+\[(STYLE|CODE|ARCH|TOOL|PROCESS|DATA|UX|SECURITY|TEST|OTHER)\]\s+') {
        Write-Error "Error in $($rf.Name): rule does not match standard format 'N. [CATEGORY] Description - rationale.'`n   Content: $firstLine"
        exit 1
    }

    $actualNum = [int]$Matches[1]
    if ($actualNum -ne $expectedNum) {
        Write-Error "Error in $($rf.Name): expected rule number $expectedNum, but found $actualNum"
        exit 1
    }

    $fullBlock = $rawText.Trim()
    $compiledRules += $fullBlock
    $expectedNum++
}

$compiledRulesText = $compiledRules -join "`n"

if ($Stdout) {
    Write-Output $compiledRulesText
    exit 0
}

$agentsContent = [System.IO.File]::ReadAllText($agentsFile, [System.Text.Encoding]::UTF8)

# Match Learned Rules section header and optional comment block
$pattern = '(?s)(##\s+([0-9]+\.\s+)?Learned Rules\s*\r?\n\s*(?:<!--.*?-->\s*\r?\n)?)'
$match = [System.Text.RegularExpressions.Regex]::Match($agentsContent, $pattern)

if (-not $match.Success) {
    Write-Error "Could not locate Learned Rules header in $agentsFile"
    exit 1
}

$prefix = $agentsContent.Substring(0, $match.Index + $match.Length)
# Ensure clean newline between comment block and rules
$prefixClean = $prefix.TrimEnd() + "`n`n"
$newContent = $prefixClean + $compiledRulesText + "`n"

# Standardize newlines for comparison
$normalizedExisting = $agentsContent.Replace("`r`n", "`n").Trim()
$normalizedNew = $newContent.Replace("`r`n", "`n").Trim()

if ($Check) {
    if ($normalizedExisting -ne $normalizedNew) {
        Write-Error "Check failed: $agentsFile is not in sync with .ai/rules/"
        exit 1
    } else {
        Write-Host " [PASS] $agentsFile is in sync with .ai/rules/" -ForegroundColor Green
        exit 0
    }
} else {
    [System.IO.File]::WriteAllText($agentsFile, $newContent, $utf8NoBom)
    $count = $expectedNum - 1
    Write-Host " [SUCCESS] Compiled $count rules into $agentsFile" -ForegroundColor Green
}
