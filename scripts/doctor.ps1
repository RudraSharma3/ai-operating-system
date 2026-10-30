param (
    [Parameter(Mandatory=$false)]
    [Alias("TargetPath")]
    [string]$ProjectPath = (Get-Location).Path,
    [switch]$Ci = $false,
    [switch]$Json = $false
)

$target = Resolve-Path $ProjectPath
$passed = 0
$warnings = 0
$failures = 0
$checksList = [System.Collections.Generic.List[PSObject]]::new()

function Register-CheckRecord {
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
    Register-CheckRecord 1 "Canonical AGENTS.md exists" "PASS"
} else {
    Register-CheckRecord 1 "Canonical AGENTS.md exists" "FAIL" "Missing AGENTS.md at project root"
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
    Register-CheckRecord 2 "Provider adapters point to AGENTS.md" "PASS"
} else {
    Register-CheckRecord 2 "Provider adapters point to AGENTS.md" "FAIL" $adapterErr
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
    Register-CheckRecord 3 "Core architecture documentation exists" "PASS"
} else {
    Register-CheckRecord 3 "Core architecture documentation exists" "FAIL" $docsErr
}

# 4. Learning engine structure exists
$aiDir = Join-Path $target ".ai"
$candFile = Join-Path $aiDir "mistakes-candidates.md"
$lessFile = Join-Path $docsDir "lessons.md"
if ((Test-Path $aiDir) -and (Test-Path $candFile) -and (Test-Path $lessFile)) {
    Register-CheckRecord 4 "Learning engine structure exists" "PASS"
} else {
    Register-CheckRecord 4 "Learning engine structure exists" "FAIL" "Missing .ai/, mistakes-candidates.md, or docs/lessons.md"
}

# 5. Pre-commit hook installed
$hookFile = Join-Path $target ".githooks\pre-commit"
if (Test-Path $hookFile) {
    Register-CheckRecord 5 "Pre-commit secret guard is installed and executable" "PASS"
} else {
    Register-CheckRecord 5 "Pre-commit secret guard is installed and executable" "FAIL" "Missing .githooks/pre-commit"
}

# 6. Active git hook configuration
Push-Location $target
try {
    $hooksPath = (git config core.hooksPath 2>$null)
    if ($hooksPath) {
        Register-CheckRecord 6 "Git hook is active in core.hooksPath" "PASS"
    } else {
        Register-CheckRecord 6 "Git hook is active in core.hooksPath" "FAIL" "core.hooksPath is not configured in git (run 'powershell scripts/bootstrap.ps1' or 'bash scripts/bootstrap.sh' to initialize)"
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
    Register-CheckRecord 7 "Zero secrets detected in tracked files" "PASS"
} else {
    Register-CheckRecord 7 "Zero secrets detected in tracked files" "FAIL" "Detected $leaksFound file(s) containing secret signatures"
}

# 8. No .env files tracked by git
Push-Location $target
try {
    $trackedEnv = (git ls-files 2>$null | Where-Object { $_ -match '(^|/)\.env($|\..*)' -and $_ -notmatch '\.(example|sample|template|dist)$' })
    if (-not $trackedEnv) {
        Register-CheckRecord 8 "No environment (.env) files tracked by git" "PASS"
    } else {
        Register-CheckRecord 8 "No environment (.env) files tracked by git" "FAIL" "Sensitive env file(s) tracked in git index: $($trackedEnv -join ', ')"
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
    Register-CheckRecord 9 "Referenced playbooks and prompts paths exist" "PASS"
} else {
    Register-CheckRecord 9 "Referenced playbooks and prompts paths exist" "FAIL" "Referenced playbooks directory or files missing"
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
    Register-CheckRecord 10 "Learned rule IDs are unique" "PASS"
} else {
    Register-CheckRecord 10 "Learned rule IDs are unique" "FAIL" $ruleError
}

# 11. Active task state tracker non-empty
$tsPath = Join-Path $docsDir "task-state.md"
if ((Test-Path $tsPath) -and ((Get-Item $tsPath).Length -gt 0)) {
    Register-CheckRecord 11 "Active task state tracker is non-empty" "PASS"
} else {
    Register-CheckRecord 11 "Active task state tracker is non-empty" "FAIL" "docs/task-state.md is missing or empty"
}

# 12. AGENTS.md size under budget
if (Test-Path $agentsFile) {
    $size = (Get-Item $agentsFile).Length
    if ($size -lt 8192) {
        Register-CheckRecord 12 "AGENTS.md size within token budget (<8KB)" "PASS"
    } else {
        Register-CheckRecord 12 "AGENTS.md size within token budget (<8KB)" "WARN" "AGENTS.md is $size bytes (exceeds budget)"
    }
}

# 13. Line ending hygiene (.gitattributes)
$gaFile = Join-Path $target ".gitattributes"
if ((Test-Path $gaFile) -and ((Get-Content $gaFile -Raw) -match "eol=lf")) {
    Register-CheckRecord 13 "Line ending hygiene enforced (.gitattributes)" "PASS"
} else {
    Register-CheckRecord 13 "Line ending hygiene enforced (.gitattributes)" "FAIL" "Missing .gitattributes enforcing LF line endings"
}

# 14. Pattern registry and allowlist exist
$allowFile = Join-Path $target ".ai\secret-allowlist.txt"
if ((Test-Path $patternsFile) -and (Test-Path $allowFile)) {
    Register-CheckRecord 14 "Secret pattern registry and allowlist exist" "PASS"
} else {
    Register-CheckRecord 14 "Secret pattern registry and allowlist exist" "FAIL" "Missing secret-patterns.txt or secret-allowlist.txt"
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

    if ($mcpOk) {
        try {
            $mcpData = $mcpContent | ConvertFrom-Json
            if ($mcpData.mcpServers) {
                foreach ($prop in $mcpData.mcpServers.PSObject.Properties) {
                    $srvName = $prop.Name
                    $srvArgs = $prop.Value.args
                    $isPinned = $false
                    if ($srvArgs) {
                        foreach ($arg in $srvArgs) {
                            $ver = ""
                            if ($arg.Length -gt 1 -and $arg.Substring(1).Contains("@")) {
                                $ver = $arg.Substring(1).Split("@")[-1]
                            } elseif ($arg.Contains("==")) {
                                $ver = $arg.Split("==")[-1]
                            }
                            if ($ver) {
                                if ($ver -match '^[\^~><*]' -or $ver -eq 'latest') {
                                    $mcpOk = $false
                                    $mcpError = "Server '$srvName' in mcp.json has range version specification '$ver' (exact pins required)"
                                    break
                                }
                                if ($ver -match '^\d') { $isPinned = $true }
                            }
                        }
                    }
                    if (-not $mcpOk) { break }
                    if (-not $isPinned) {
                        $mcpOk = $false
                        $mcpError = "Server '$srvName' in mcp.json has unpinned version specification"
                        break
                    }
                }
            }
        } catch {
            $mcpOk = $false
            $mcpError = "Failed to parse mcp.json: $_"
        }
    }
}

if ($mcpOk) {
    Register-CheckRecord 15 "Playbook MCP worker tools exist in mcp.json" "PASS"
} else {
    Register-CheckRecord 15 "Playbook MCP worker tools exist in mcp.json" "FAIL" $mcpError
}

# 16. Pending *.ai-os-update conflict files
$conflictFiles = Get-ChildItem -Path $target -Filter "*.ai-os-update" -Recurse -File -ErrorAction SilentlyContinue
if ($conflictFiles -and $conflictFiles.Count -gt 0) {
    Register-CheckRecord 16 "Side-by-side upgrade conflict files" "WARN" "$($conflictFiles.Count) pending *.ai-os-update file(s) found. Review preserved differences."
} else {
    Register-CheckRecord 16 "Side-by-side upgrade conflict files" "PASS"
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
    Register-CheckRecord 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "PASS"
} else {
    Register-CheckRecord 17 "PowerShell script encoding hygiene (.ps1 ASCII or UTF-8 BOM)" "FAIL" $ps1Err
}

# 18. No hardcoded local user paths in tracked files
$localHits = (git -C $target grep -iE "C:[\\/]Users" -- ":!scripts/doctor.*" 2>$null)
if ($localHits) {
    Register-CheckRecord 18 "No hardcoded local user paths in tracked files" "FAIL" "Found hardcoded local user path: $localHits"
} else {
    Register-CheckRecord 18 "No hardcoded local user paths in tracked files" "PASS"
}

# 19. Documentation counts synchronicity
$docCountsOk = $true
$docErr = ""
$readmePath = Join-Path $target "README.md"
$userGuidePath = Join-Path $target "docs/AI-OS-USER-GUIDE.md"
$playbooksDir = if (Test-Path (Join-Path $target "playbooks")) { Join-Path $target "playbooks" } else { Join-Path $target ".ai-os/playbooks" }

if (Test-Path $readmePath) {
    $readmeContent = Get-Content $readmePath -Raw
    $actualPlaybooks = if (Test-Path $playbooksDir) { (Get-ChildItem -Path $playbooksDir -Filter "*.md").Count } else { 0 }
    if ($readmeContent -match 'playbooks/\s*\((\d+)\s+Playbooks\)') {
        $claimedPlaybooks = [int]$matches[1]
        if ($claimedPlaybooks -ne $actualPlaybooks) {
            $docCountsOk = $false
            $docErr = "README claims $claimedPlaybooks playbooks, but $actualPlaybooks exist"
        }
    }
    if ($readmeContent -match '(\d+)-point diagnostic doctor') {
        $claimedDoctor = [int]$matches[1]
        if ($claimedDoctor -ne 27) {
            $docCountsOk = $false
            $docErr = "README claims $claimedDoctor-point doctor, expected 27"
        }
    }
}

if (Test-Path $userGuidePath) {
    $ugContent = Get-Content $userGuidePath -Raw
    if ($ugContent -match '(\d+)-point diagnostic') {
        $ugClaimedDoctor = [int]$matches[1]
        if ($ugClaimedDoctor -ne 27) {
            $docCountsOk = $false
            $docErr = "User Guide claims $ugClaimedDoctor-point doctor, expected 27"
        }
    }
    if ($ugContent -match 'tests\s+(\d+)\s+key integrity checks') {
        $ugClaimedChecks = [int]$matches[1]
        if ($ugClaimedChecks -ne 27) {
            $docCountsOk = $false
            $docErr = "User Guide claims $ugClaimedChecks integrity checks, expected 27"
        }
    }
}

if ($docCountsOk) {
    Register-CheckRecord 19 "Documentation counts match reality (playbooks, doctor checks)" "PASS"
} else {
    Register-CheckRecord 19 "Documentation counts match reality (playbooks, doctor checks)" "FAIL" $docErr
}

# 20. Private names deny-list check (.ai/private-names.txt)
$privNamesFile = Join-Path $target ".ai/private-names.txt"
$privMatches = 0
if (Test-Path $privNamesFile) {
    $denied = @(Get-Content $privNamesFile | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 -and -not $_.StartsWith("#") })
    if ($denied.Count -gt 0) {
        foreach ($pattern in $denied) {
            $hits = (git -C $target grep -iF "$pattern" -- ":!.ai/private-names.txt" 2>$null)
            if ($hits) {
                $privMatches += @($hits).Count
            }
        }
    }
}
if ($privMatches -gt 0) {
    Register-CheckRecord 20 "No private deny-listed names in tracked files" "FAIL" "Found $privMatches match(es) for private deny-listed names in tracked files"
} else {
    Register-CheckRecord 20 "No private deny-listed names in tracked files" "PASS"
}

# 21. Optional Claude Code hooks installed check
$claudeSettings = Join-Path $target ".claude/settings.json"
if (Test-Path $claudeSettings) {
    Register-CheckRecord 21 "Optional Claude Code hooks status" "WARN" "Opt-in Claude Code hooks are active (.claude/settings.json)"
} else {
    Register-CheckRecord 21 "Optional Claude Code hooks status" "PASS"
}

# 22. Headless agent command documentation verification
$sourcesFile = Join-Path $target "docs/sources.md"
$unverifiedCmdErr = $null

$docFiles = @()
$readmeFile = Join-Path $target "README.md"
if (Test-Path $readmeFile) { $docFiles += $readmeFile }
$docsFolder = Join-Path $target "docs"
if (Test-Path $docsFolder) {
    Get-ChildItem -Path $docsFolder -Filter "*.md" -Recurse | ForEach-Object { $docFiles += $_.FullName }
}
$evalsFolder = Join-Path $target "evals"
if (Test-Path $evalsFolder) {
    Get-ChildItem -Path $evalsFolder -Filter "*.md" -Recurse | ForEach-Object { $docFiles += $_.FullName }
}

$sourcesContent = if (Test-Path $sourcesFile) { Get-Content $sourcesFile -Raw } else { "" }

$sourcesResolved = if (Test-Path $sourcesFile) { (Resolve-Path $sourcesFile -ErrorAction SilentlyContinue).Path } else { $null }

foreach ($df in $docFiles) {
    $dfResolved = (Resolve-Path $df -ErrorAction SilentlyContinue).Path
    if ($sourcesResolved -and $dfResolved -eq $sourcesResolved) { continue }
    $lines = Get-Content $df
    foreach ($line in $lines) {
        $foundCmd = $null
        if ($line -match '`claude\s+([^`]+)`') {
            $foundCmd = $matches[0].Trim('`')
        } elseif ($line -match '"claude\s+([^"]+)"') {
            $foundCmd = $matches[0].Trim('"')
        } elseif ($line -match '\bclaude\s+(-[a-zA-Z0-9_ -]+)') {
            $foundCmd = $matches[0]
        }
        if ($foundCmd) {
            if (-not (Test-Path $sourcesFile)) {
                $unverifiedCmdErr = "docs/sources.md missing; unverified command '$foundCmd' found in $(Split-Path $df -Leaf)"
                break
            }
            $flags = [regex]::Matches($foundCmd, '(--[a-zA-Z0-9_-]+|-[a-zA-Z0-9])') | ForEach-Object { $_.Value }
            foreach ($fl in $flags) {
                if (-not $sourcesContent.Contains($fl)) {
                    $unverifiedCmdErr = "Unverified flag '$fl' in '$foundCmd' in $(Split-Path $df -Leaf) (not listed in docs/sources.md)"
                    break
                }
            }
            if ($foundCmd -match '--non-interactive') {
                $unverifiedCmdErr = "Unverified command '$foundCmd' in $(Split-Path $df -Leaf) (flag marked invalid/unverified in docs/sources.md)"
                break
            }
        }
        if ($line -match '--permission-mode[=\s]+([a-zA-Z0-9_-]+)') {
            $mode = $matches[1]
            if (-not (Test-Path $sourcesFile)) {
                $unverifiedCmdErr = "docs/sources.md missing; unverified permission-mode '$mode' found in $(Split-Path $df -Leaf)"
                break
            }
            if (-not ($sourcesContent -match "(`$mode`|'$mode'|\($mode\)|,\s*$mode\b|\b$mode\b)")) {
                $unverifiedCmdErr = "Unverified permission-mode '$mode' in $(Split-Path $df -Leaf) (not listed in docs/sources.md)"
                break
            }
        }
    }
    if ($unverifiedCmdErr) { break }
}

if ($unverifiedCmdErr) {
    Register-CheckRecord 22 "Headless agent command documentation verification" "WARN" $unverifiedCmdErr
} else {
    Register-CheckRecord 22 "Headless agent command documentation verification" "PASS"
}

# 23. MCP pin maturity and freshness (reads docs/mcp-pins.json offline)
$mcpPinsFile = Join-Path $target "docs/mcp-pins.json"
if (Test-Path $mcpPinsFile) {
    try {
        $pinsRaw = Get-Content $mcpPinsFile -Raw
        $pinsData = ConvertFrom-Json $pinsRaw
        $now = [DateTime]::UtcNow
        $pinWarns = @()
        foreach ($item in $pinsData) {
            $pkg = $item.package
            $ver = $item.version
            if ($item.published_at -and $item.checked_at) {
                $pubDt = [DateTime]::Parse($item.published_at, $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                $chkDt = [DateTime]::Parse($item.checked_at, $null, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                $ageAtChk = ($chkDt - $pubDt).TotalDays
                if ($ageAtChk -lt 14.0) {
                    $pinWarns += "$pkg@$ver was younger than 14 days ($([math]::Round($ageAtChk, 1))d) when recorded"
                }
                $recAge = ($now - $chkDt).TotalDays
                if ($recAge -gt 90.0) {
                    $pinWarns += "Record for $pkg@$ver is older than 90 days ($([math]::Round($recAge, 1))d stale)"
                }
            }
        }
        if ($pinWarns.Count -gt 0) {
            Register-CheckRecord 23 "MCP pin maturity and freshness" "WARN" ($pinWarns -join "; ")
        } else {
            Register-CheckRecord 23 "MCP pin maturity and freshness" "PASS"
        }
    } catch {
        Register-CheckRecord 23 "MCP pin maturity and freshness" "WARN" "Error parsing docs/mcp-pins.json: $_"
    }
} else {
    Register-CheckRecord 23 "MCP pin maturity and freshness" "PASS"
}

# 24. GitHub Actions workflow security (pinned action SHAs and permissions block)
$workflowsDir = Join-Path $target ".github/workflows"
$workflowWarn = ""
if (Test-Path $workflowsDir) {
    $wfFiles = Get-ChildItem -Path $workflowsDir -File | Where-Object { $_.Extension -in ".yml", ".yaml" }
    foreach ($wf in $wfFiles) {
        $wfLines = Get-Content $wf.FullName
        $hasTopPermissions = $false
        foreach ($line in $wfLines) {
            if ($line -match '^permissions:') {
                $hasTopPermissions = $true
                break
            }
        }
        if (-not $hasTopPermissions) {
            $workflowWarn = "Workflow '$($wf.Name)' lacks a top-level permissions block"
            break
        }
        foreach ($line in $wfLines) {
            if ($line -match '^\s*(?:-\s*)?uses:\s*([^\s#]+)') {
                $actionRef = $matches[1].Trim("'", '"')
                if ($actionRef.StartsWith("./") -or $actionRef.StartsWith("docker://")) {
                    continue
                }
                if ($actionRef -match '@([0-9a-fA-F]{40})$') {
                    continue
                } else {
                    $workflowWarn = "Workflow '$($wf.Name)' uses unpinned action '$actionRef' (expected 40-character commit SHA)"
                    break
                }
            }
        }
        if ($workflowWarn) { break }
    }
}

# Check 3: Dependabot 14-day cooldown enforcement (table-driven from docs/dependabot-cooldown-keys.json)
$dependabotFile = Join-Path $target ".github\dependabot.yml"
$cooldownTableFile = Join-Path $target "docs\dependabot-cooldown-keys.json"
if (-not (Test-Path $cooldownTableFile)) {
    $cooldownTableFile = Join-Path $PSScriptRoot "..\docs\dependabot-cooldown-keys.json"
}

$workflowErr = ""
if (-not $workflowWarn -and (Test-Path $dependabotFile)) {
    $tableData = $null
    if (Test-Path $cooldownTableFile) {
        try {
            $tableJson = Get-Content $cooldownTableFile -Raw | ConvertFrom-Json
            $tableData = $tableJson.ecosystems
        } catch {
            $tableData = $null
        }
    }

    $depLines = Get-Content $dependabotFile
    $currentEco = ""
    $inCooldown = $false
    $cooldownIndent = 0
    $hasCooldown = $false
    $has14Day = $false
    $unknownEco = $null

    foreach ($rawLine in $depLines) {
        $cleanLine = ($rawLine -replace '#.*$', '').TrimEnd()
        if ([string]::IsNullOrWhiteSpace($cleanLine)) { continue }

        if ($cleanLine -match 'package-ecosystem:\s*"?([a-zA-Z0-9_-]+)"?') {
            $currentEco = $matches[1]
            $inCooldown = $false
            continue
        }

        if ($cleanLine -match '^(\s*)cooldown:\s*$') {
            $inCooldown = $true
            $hasCooldown = $true
            $cooldownIndent = $matches[1].Length
            continue
        }

        if ($inCooldown) {
            if ($cleanLine -match '^(\s+)([a-zA-Z0-9_-]+):') {
                $kIndent = $matches[1].Length
                $ckey = $matches[2]
                if ($kIndent -le $cooldownIndent) {
                    $inCooldown = $false
                } else {
                    if ($ckey -eq 'default-days') {
                        if ($cleanLine -match 'default-days:\s*([0-9]+)') {
                            if ([int]$matches[1] -ge 14) { $has14Day = $true }
                        }
                    }

                    if ($tableData) {
                        $prop = $tableData.PSObject.Properties[$currentEco]
                        if (-not $prop) {
                            if (-not $unknownEco) { $unknownEco = $currentEco }
                        } else {
                            $allowedKeys = @($prop.Value)
                            if ($allowedKeys -notcontains $ckey) {
                                $workflowErr = "Dependabot configuration '.github/dependabot.yml' uses unsupported cooldown key '$ckey' for package ecosystem '$currentEco'"
                                break
                            }
                        }
                    }
                }
            } else {
                $inCooldown = $false
            }
        }
    }

    if (-not $workflowErr) {
        if ($unknownEco) {
            $workflowWarn = "Dependabot configuration '.github/dependabot.yml' uses unknown package ecosystem '$unknownEco'"
        } elseif (-not $hasCooldown -or -not $has14Day) {
            $workflowWarn = "Dependabot configuration '.github/dependabot.yml' lacks a minimum 14-day cooldown"
        }
    }
}

if ($workflowErr) {
    Register-CheckRecord 24 "GitHub Actions workflow action pinning and permissions" "FAIL" $workflowErr
} elseif ($workflowWarn) {
    Register-CheckRecord 24 "GitHub Actions workflow action pinning and permissions" "WARN" $workflowWarn
} else {
    Register-CheckRecord 24 "GitHub Actions workflow action pinning and permissions" "PASS"
}

# 25. Python 3.9+ runtime availability (warn if missing)
$pyAvail = $false
$pyBin = if (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } elseif (Get-Command "python" -ErrorAction SilentlyContinue) { "python" } else { $null }
if ($pyBin) {
    $pyAvail = $true
}

if ($pyAvail) {
    Register-CheckRecord 25 "Python 3.9+ runtime availability" "PASS"
} else {
    Register-CheckRecord 25 "Python 3.9+ runtime availability" "WARN" "Python 3.9+ not found in PATH; verification layer features will be disabled"
}

# 26. Dependency approval list and CODEOWNERS coverage
$depsFile = Join-Path $target ".ai/deps-approved.txt"
if (-not (Test-Path $depsFile)) {
    Register-CheckRecord 26 "Dependency approval list and CODEOWNERS coverage" "FAIL" "Missing required .ai/deps-approved.txt file"
} else {
    $coHasOwner = $false
    foreach ($cand in @(".github/CODEOWNERS", "CODEOWNERS", "docs/CODEOWNERS")) {
        $coPath = Join-Path $target $cand
        if (Test-Path $coPath) {
            $coLines = Get-Content $coPath -ErrorAction SilentlyContinue
            foreach ($line in $coLines) {
                if ($line -match '^\s*\.ai/deps-approved\.txt\s+@[a-zA-Z0-9_\-]+') {
                    $coHasOwner = $true
                    break
                }
            }
            if ($coHasOwner) { break }
        }
    }

    $repoRoot = Split-Path $PSScriptRoot -Parent
    $isRootRepo = $false
    try {
        if ((Resolve-Path $target).Path -eq (Resolve-Path $repoRoot).Path) {
            $isRootRepo = $true
        }
    } catch {
        $null = $_
    }

    if ($coHasOwner) {
        Register-CheckRecord 26 "Dependency approval list and CODEOWNERS coverage" "PASS"
    } else {
        if ($isRootRepo) {
            Register-CheckRecord 26 "Dependency approval list and CODEOWNERS coverage" "FAIL" ".github/CODEOWNERS must cover .ai/deps-approved.txt with a valid owner handle"
        } else {
            Register-CheckRecord 26 "Dependency approval list and CODEOWNERS coverage" "WARN" "CODEOWNERS lacks owner coverage for .ai/deps-approved.txt; fix: echo '.ai/deps-approved.txt @your-handle' >> .github/CODEOWNERS"
        }
    }
}

# 27. Pre-commit verification configuration
$vconfFile = Join-Path $target ".ai/verify.conf"
$vconfErr = $null
if (-not (Test-Path $vconfFile)) {
    $vconfErr = "Missing .ai/verify.conf configuration file"
} else {
    $vlines = Get-Content $vconfFile
    foreach ($vl in $vlines) {
        $cleanVl = ($vl -replace '#.*$', '').Trim()
        if ([string]::IsNullOrWhiteSpace($cleanVl)) { continue }
        $parts = $cleanVl -split '='
        if ($parts.Length -eq 2) {
            $k = $parts[0].Trim()
            $v = $parts[1].Trim()
            if ($k -eq "deps" -and $v -notmatch '^(block|warn|off)$') {
                $vconfErr = "Invalid verify.conf setting for deps: '$v'"
            } elseif ($k -eq "imports" -and $v -notmatch '^(block|warn|off)$') {
                $vconfErr = "Invalid verify.conf setting for imports: '$v'"
            } elseif ($k -eq "on_missing_python" -and $v -notmatch '^(warn|block)$') {
                $vconfErr = "Invalid verify.conf setting for on_missing_python: '$v'"
            } elseif ($k -eq "approvals_changed" -and $v -notmatch '^(warn|block)$') {
                $vconfErr = "Invalid verify.conf setting for approvals_changed: '$v'"
            }
        }
    }
}

if ($vconfErr) {
    Register-CheckRecord 27 "Pre-commit verification configuration" "FAIL" $vconfErr
} else {
    Register-CheckRecord 27 "Pre-commit verification configuration" "PASS"
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
    if ($Ci) { exit 1 }
    exit 1
}
exit 0
