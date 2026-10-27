param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = (Get-Location).Path,
    [switch]$Ci = $false,
    [switch]$Json = $false
)

$target = Resolve-Path $ProjectPath
$passed = 0
$warnings = 0
$failures = 0
$checksList = [System.Collections.Generic.List[PSObject]]::new()

function Record-Check {
    param ($Id, $Name, $Status, $Details = "")
    if ($Status -eq "PASS") {
        $script:passed++
        if (-not $Json) { Write-Host " [PASS] $Name" -ForegroundColor Green }
    } elseif ($Status -eq "WARN") {
        $script:warnings++
        if (-not $Json) { Write-Host " [WARN] $Name - $Details" -ForegroundColor Yellow }
    } else {
        $script:failures++
        if (-not $Json) { Write-Host " [FAIL] $Name - $Details" -ForegroundColor Red }
    }
    $script:checksList.Add([PSCustomObject]@{
        id = $Id
        name = $Name
        status = $Status
        details = $Details
    })
}

if (-not $Json) {
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " Running AI-OS Project Health Doctor" -ForegroundColor Cyan
    Write-Host " Target: $target" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
}

# 1. Canonical AGENTS.md
$agentsFile = Join-Path $target "AGENTS.md"
if (Test-Path $agentsFile) {
    Record-Check 1 "Canonical AGENTS.md exists" "PASS"
} else {
    Record-Check 1 "Canonical AGENTS.md exists" "FAIL" "Missing AGENTS.md at project root"
}

# 2. Provider adapters point to AGENTS.md
$adaptersOk = $true
$adapterErr = ""
foreach ($ad in @("CLAUDE.md", "GEMINI.md", "CODEX.md", ".cursor/rules/agents.mdc", ".github/copilot-instructions.md")) {
    $adPath = Join-Path $target $ad
    if (-not (Test-Path $adPath)) {
        $adaptersOk = $false; $adapterErr = "Missing $ad adapter"; break
    }
    $c = Get-Content $adPath -Raw -ErrorAction SilentlyContinue
    if ($c -notmatch "AGENTS.md") {
        $adaptersOk = $false; $adapterErr = "$ad does not point to AGENTS.md"; break
    }
}
if ($adaptersOk) {
    Record-Check 2 "Provider adapters point to AGENTS.md" "PASS"
} else {
    Record-Check 2 "Provider adapters point to AGENTS.md" "FAIL" $adapterErr
}

# 3. Core architecture documentation exists
$docsOk = $true
$docsErr = ""
$docsDir = Join-Path $target "docs"
foreach ($d in @("architecture.md", "conventions.md", "task-state.md", "graph.md")) {
    $dPath = Join-Path $docsDir $d
    if (-not (Test-Path $dPath)) {
        $docsOk = $false; $docsErr = "Missing docs/$d"; break
    }
}
if ($docsOk) {
    Record-Check 3 "Core architecture documentation exists" "PASS"
} else {
    Record-Check 3 "Core architecture documentation exists" "FAIL" $docsErr
}

# 4. Learning engine structure exists
$aiDir = Join-Path $target ".ai"
$candFile = Join-Path $aiDir "mistakes-candidates.md"
$lessFile = Join-Path $docsDir "lessons.md"
if ((Test-Path $aiDir) -and (Test-Path $candFile) -and (Test-Path $lessFile)) {
    Record-Check 4 "Learning engine structure exists" "PASS"
} else {
    Record-Check 4 "Learning engine structure exists" "FAIL" "Missing .ai/, mistakes-candidates.md, or docs/lessons.md"
}

# 5. Pre-commit hook installed
$hookFile = Join-Path $target ".githooks\pre-commit"
if (Test-Path $hookFile) {
    Record-Check 5 "Pre-commit secret guard is installed and executable" "PASS"
} else {
    Record-Check 5 "Pre-commit secret guard is installed and executable" "FAIL" "Missing .githooks/pre-commit"
}

# 6. Active git hook configuration
Push-Location $target
try {
    $hooksPath = (git config core.hooksPath 2>$null)
    if ($hooksPath) {
        Record-Check 6 "Git hook is active in core.hooksPath" "PASS"
    } else {
        Record-Check 6 "Git hook is active in core.hooksPath" "FAIL" "core.hooksPath is not configured in git"
    }
} finally {
    Pop-Location
}

# 7. Secret scan of tracked files
$patternsFile = Join-Path $target ".ai\secret-patterns.txt"
$leaksFound = 0
if (Test-Path $patternsFile) {
    $patterns = Get-Content $patternsFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } | ForEach-Object { ($_ -split '\|', 2)[1] }
    Push-Location $target
    try {
        $trackedFiles = (git ls-files 2>$null)
        if (-not $trackedFiles) { $trackedFiles = Get-ChildItem -File -Recurse | Select-Object -ExpandProperty FullName }
        foreach ($tf in $trackedFiles) {
            if ($tf -match 'secret-patterns\.txt|\.githooks/pre-commit') { continue }
            if (-not (Test-Path $tf)) { continue }
            $content = Get-Content $tf -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            foreach ($p in $patterns) {
                if ($content -match $p) {
                    $leaksFound++
                    break
                }
            }
        }
    } finally {
        Pop-Location
    }
}

if ($leaksFound -eq 0) {
    Record-Check 7 "Zero secrets detected in tracked files" "PASS"
} else {
    Record-Check 7 "Zero secrets detected in tracked files" "FAIL" "Detected $leaksFound file(s) containing secret signatures"
}

# 8. No .env files tracked by git
Push-Location $target
try {
    $trackedEnv = (git ls-files 2>$null | Where-Object { $_ -match '(^|/)\.env($|\..*)' -and $_ -notmatch '\.(example|sample|template|dist)$' })
    if (-not $trackedEnv) {
        Record-Check 8 "No environment (.env) files tracked by git" "PASS"
    } else {
        Record-Check 8 "No environment (.env) files tracked by git" "FAIL" "Sensitive env file(s) tracked in git index: $($trackedEnv -join ', ')"
    }
} finally {
    Pop-Location
}

# 9. Referenced playbooks and prompts exist
$playbooksOk = $false
$pbDir = Join-Path $target "playbooks"
$aiosPbDir = Join-Path $target ".ai-os\playbooks"
if (Test-Path (Join-Path $pbDir "codebase-analysis.md")) {
    $playbooksOk = $true
} elseif (Test-Path (Join-Path $aiosPbDir "codebase-analysis.md")) {
    $playbooksOk = $true
}
if ($playbooksOk) {
    Record-Check 9 "Referenced playbooks and prompts paths exist" "PASS"
} else {
    Record-Check 9 "Referenced playbooks and prompts paths exist" "FAIL" "Referenced playbooks directory or files missing"
}

# 10. Unique learned rule IDs
$rulesOk = $true
$ruleError = ""
if (Test-Path $agentsFile) {
    $lines = Get-Content $agentsFile
    $seen = @{}
    $inLearnedSection = $false
    foreach ($l in $lines) {
        if ($l -match '^##\s+([0-9]+\.\s+)?Learned Rules') { $inLearnedSection = $true; continue }
        if ($inLearnedSection -and ($l -match '^([a-zA-Z0-9_-]+)\.\s+\[[A-Z]+\]')) {
            $rid = $matches[1]
            if ($seen.ContainsKey($rid)) {
                $rulesOk = $false
                $ruleError = "Duplicate rule ID '$rid' detected"
                break
            }
            $seen[$rid] = $true
        }
    }
}
if ($rulesOk) {
    Record-Check 10 "Learned rule IDs are unique" "PASS"
} else {
    Record-Check 10 "Learned rule IDs are unique" "FAIL" $ruleError
}

# 11. Active task state tracker non-empty
$tsPath = Join-Path $docsDir "task-state.md"
if ((Test-Path $tsPath) -and ((Get-Item $tsPath).Length -gt 0)) {
    Record-Check 11 "Active task state tracker is non-empty" "PASS"
} else {
    Record-Check 11 "Active task state tracker is non-empty" "FAIL" "docs/task-state.md is missing or empty"
}

# 12. AGENTS.md size under budget
if (Test-Path $agentsFile) {
    $size = (Get-Item $agentsFile).Length
    if ($size -lt 15000) {
        Record-Check 12 "AGENTS.md size within token budget (<15KB)" "PASS"
    } else {
        Record-Check 12 "AGENTS.md size within token budget (<15KB)" "WARN" "AGENTS.md is $size bytes (exceeds budget)"
    }
}

# 13. Line ending hygiene (.gitattributes)
$gaFile = Join-Path $target ".gitattributes"
if ((Test-Path $gaFile) -and ((Get-Content $gaFile -Raw) -match "eol=lf")) {
    Record-Check 13 "Line ending hygiene enforced (.gitattributes)" "PASS"
} else {
    Record-Check 13 "Line ending hygiene enforced (.gitattributes)" "FAIL" "Missing .gitattributes enforcing LF line endings"
}

# 14. Pattern registry and allowlist exist
$allowFile = Join-Path $target ".ai\secret-allowlist.txt"
if ((Test-Path $patternsFile) -and (Test-Path $allowFile)) {
    Record-Check 14 "Secret pattern registry and allowlist exist" "PASS"
} else {
    Record-Check 14 "Secret pattern registry and allowlist exist" "FAIL" "Missing secret-patterns.txt or secret-allowlist.txt"
}

# 15. Worker tools in multi-agent playbook match mcp.json
$mcpOk = $true
$mcpError = ""
$playbookPath = Join-Path $target "playbooks\multi-agent-orchestration.md"
if (-not (Test-Path $playbookPath)) {
    $playbookPath = Join-Path $target ".ai-os\playbooks\multi-agent-orchestration.md"
}
$mcpJsonPath = Join-Path $target "mcp.json"

if ((Test-Path $playbookPath) -and (Test-Path $mcpJsonPath)) {
    $pbContent = Get-Content $playbookPath
    $mcpContent = Get-Content $mcpJsonPath -Raw
    foreach ($line in $pbContent) {
        if ($line -match '^\-\s+\*\*`([a-zA-Z0-9_-]+)`\*\*') {
            $tool = $matches[1]
            if ($mcpContent -notmatch "`"$tool`":") {
                $mcpOk = $false
                $mcpError = "Tool '$tool' declared in playbook is missing from mcp.json"
                break
            }
        }
    }
}

if ($mcpOk) {
    Record-Check 15 "Playbook MCP worker tools exist in mcp.json" "PASS"
} else {
    Record-Check 15 "Playbook MCP worker tools exist in mcp.json" "FAIL" $mcpError
}

# 16. Pending *.ai-os-update conflict files
$conflictFiles = Get-ChildItem -Path $target -Filter "*.ai-os-update" -Recurse -File -ErrorAction SilentlyContinue
if ($conflictFiles -and $conflictFiles.Count -gt 0) {
    Record-Check 16 "Side-by-side upgrade conflict files" "WARN" "$($conflictFiles.Count) pending *.ai-os-update file(s) found. Review preserved differences."
} else {
    Record-Check 16 "Side-by-side upgrade conflict files" "PASS"
}

# 17. PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)
$ps1Files = Get-ChildItem -Path $target -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue
$ps1Ok = $true
$ps1Err = ""
foreach ($psf in $ps1Files) {
    $bytes = [System.IO.File]::ReadAllBytes($psf.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $isAscii = $true
    foreach ($b in $bytes) {
        if ($b -ge 128) { $isAscii = $false; break }
    }
    if (-not $hasBom -and -not $isAscii) {
        $ps1Ok = $false
        $ps1Err = "Non-ASCII without UTF-8 BOM: $($psf.Name)"
        break
    }
}
if ($ps1Ok) {
    Record-Check 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "PASS"
} else {
    Record-Check 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "FAIL" $ps1Err
}


if ($Json) {
    $armor = if ($failures -eq 0) { "ARMED" } else { "UNARMED" }
    [PSCustomObject]@{
        passed = $passed
        warnings = $warnings
        failures = $failures
        armor = $armor
        checks = $checksList
    } | ConvertTo-Json -Depth 3
} else {
    Write-Host "`n====================================================" -ForegroundColor Cyan
    Write-Host (' Health Summary: ' + $passed + ' Passed | ' + $warnings + ' Warnings | ' + $failures + ' Failures') -ForegroundColor Cyan
    if ($failures -eq 0) {
        Write-Host " EXCELLENT! Project health is in pristine operational order." -ForegroundColor Green
        Write-Host " ARMOR STATUS: Git Secret Guard [ARMED]" -ForegroundColor Green
    } else {
        Write-Host " ATTENTION: Please address the failed checks above." -ForegroundColor Yellow
        Write-Host " ARMOR STATUS: Git Secret Guard [UNARMED]" -ForegroundColor Yellow
    }
    Write-Host "====================================================" -ForegroundColor Cyan
}

if ($failures -gt 0) {
    exit 1
}
exit 0
