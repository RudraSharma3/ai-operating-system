[CmdletBinding()]
param(
    [string]$Project = ".",
    [switch]$Check,
    [switch]$Stdout,
    [int]$MaxRules = 50,
    [int]$TokenBudget = 12000,
    [switch]$Recursive
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Compile-SingleTarget {
    param(
        [string]$TargetDir
    )

    $rulesDir = Join-Path $TargetDir ".ai\rules"
    $agentsFile = Join-Path $TargetDir "AGENTS.md"

    if ((-not (Test-Path $rulesDir)) -or (-not (Test-Path $agentsFile))) {
        return
    }

    $ruleFiles = Get-ChildItem -Path $rulesDir -Filter "*.md" | Sort-Object Name
    if ($ruleFiles.Count -eq 0) {
        return
    }

    if ($ruleFiles.Count -gt $MaxRules) {
        Write-Error "Error in $TargetDir : rule count ($($ruleFiles.Count)) exceeds configured maximum ($MaxRules)"
        exit 1
    }

    $compiledRules = @()
    $seenIds = @{}

    foreach ($rf in $ruleFiles) {
        $rawText = [System.IO.File]::ReadAllText($rf.FullName, [System.Text.Encoding]::UTF8)
        $lines = @($rawText -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 })
        if ($lines.Count -eq 0) { continue }

        $firstLine = $lines[0]
        if ($firstLine -notmatch '^([a-zA-Z0-9_-]+)\.\s+\[(STYLE|CODE|ARCH|TOOL|PROCESS|DATA|UX|SECURITY|TEST|OTHER)\]\s+') {
            Write-Error "Error in $($rf.Name): rule does not match standard format '<ID>. [CATEGORY] Description - rationale.'`n   Content: $firstLine"
            exit 1
        }

        $actualId = $Matches[1]
        if ($seenIds.ContainsKey($actualId)) {
            Write-Error "Error in $($rf.Name): duplicate rule ID '$actualId' detected (collision with $($seenIds[$actualId]))"
            exit 1
        }
        $seenIds[$actualId] = $rf.Name

        $fullBlock = $rawText.Trim()
        $compiledRules += $fullBlock
    }

    $compiledRulesText = $compiledRules -join "`n"

    if ($Stdout) {
        Write-Output $compiledRulesText
        return
    }

    $agentsContent = [System.IO.File]::ReadAllText($agentsFile, [System.Text.Encoding]::UTF8)
    $pattern = '(?s)(##\s+([0-9]+\.\s+)?Learned Rules\s*\r?\n\s*(?:<!--.*?-->\s*\r?\n)?)'
    $match = [System.Text.RegularExpressions.Regex]::Match($agentsContent, $pattern)

    if (-not $match.Success) {
        Write-Error "Could not locate Learned Rules header in $agentsFile"
        exit 1
    }

    $prefix = $agentsContent.Substring(0, $match.Index + $match.Length)
    $prefixClean = $prefix.TrimEnd() + "`n`n"
    $newContent = $prefixClean + $compiledRulesText + "`n"

    $byteSize = [System.Text.Encoding]::UTF8.GetByteCount($newContent)
    if ($byteSize -gt $TokenBudget) {
        Write-Error "Error: Compiled $agentsFile size ($byteSize bytes) exceeds configured token budget ($TokenBudget bytes)"
        exit 1
    }

    $normalizedExisting = $agentsContent.Replace("`r`n", "`n").Trim()
    $normalizedNew = $newContent.Replace("`r`n", "`n").Trim()

    if ($Check) {
        if ($normalizedExisting -ne $normalizedNew) {
            Write-Error "Check failed: $agentsFile is not in sync with .ai/rules/"
            exit 1
        } else {
            Write-Host " [PASS] $agentsFile is in sync with .ai/rules/" -ForegroundColor Green
        }
    } else {
        [System.IO.File]::WriteAllText($agentsFile, $newContent, $utf8NoBom)
        Write-Host " [SUCCESS] Compiled $($seenIds.Count) rules into $agentsFile ($byteSize bytes / budget $TokenBudget bytes)" -ForegroundColor Green
    }
}

$projectPath = (Resolve-Path $Project).Path
Compile-SingleTarget -TargetDir $projectPath

if ($Recursive) {
    $subDirs = @(Get-ChildItem -Path (Join-Path $projectPath "packages") -Directory -ErrorAction SilentlyContinue) +
               @(Get-ChildItem -Path (Join-Path $projectPath "apps") -Directory -ErrorAction SilentlyContinue)
    foreach ($sub in $subDirs) {
        $subRules = Join-Path $sub.FullName ".ai\rules"
        $subAgents = Join-Path $sub.FullName "AGENTS.md"
        if ((Test-Path $subRules) -and (Test-Path $subAgents)) {
            Write-Host " [MONOREPO] Compiling nested package: $($sub.Name)" -ForegroundColor Cyan
            Compile-SingleTarget -TargetDir $sub.FullName
        }
    }
}
