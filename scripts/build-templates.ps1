[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$root = (Get-Item $PSScriptRoot).Parent.FullName

$versionFile = Join-Path $root "VERSION"
if (-not (Test-Path $versionFile)) {
    Write-Error "Missing VERSION file at repo root"
    exit 1
}
$version = (Get-Content $versionFile -Raw).Trim()

$templateDir = Join-Path $root "templates/project"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$targetDir = $templateDir
$tmpDir = $null

if ($Check) {
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ai-os-check-" + [System.Guid]::NewGuid().ToString("N"))
    $targetDir = Join-Path $tmpDir "project"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Copy-Item -Path (Join-Path $templateDir "*") -Destination $targetDir -Recurse -Force
    # Copy dot folders explicitly
    Get-ChildItem -Path $templateDir -Directory -Force | Where-Object { $_.Name.StartsWith(".") } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $targetDir -Recurse -Force
    }
    Write-Host " Checking template synchronization against master..." -ForegroundColor Cyan
} else {
    Write-Host " Building AI-OS project template (v$version)..." -ForegroundColor Cyan
}

# 1. Sync playbooks and prompts into .ai-os/
$aiOsPlaybooks = Join-Path $targetDir ".ai-os/playbooks"
$aiOsPrompts = Join-Path $targetDir ".ai-os/prompts"
if (-not (Test-Path $aiOsPlaybooks)) { New-Item -ItemType Directory -Path $aiOsPlaybooks -Force | Out-Null }
if (-not (Test-Path $aiOsPrompts)) { New-Item -ItemType Directory -Path $aiOsPrompts -Force | Out-Null }

Copy-Item -Path (Join-Path $root "playbooks/*") -Destination $aiOsPlaybooks -Recurse -Force
Copy-Item -Path (Join-Path $root "prompts/*") -Destination $aiOsPrompts -Recurse -Force

$optDest = Join-Path $targetDir ".ai-os/optional/claude-hooks"
if (-not (Test-Path $optDest)) { New-Item -ItemType Directory -Path $optDest -Force | Out-Null }
$optSrc = Join-Path $root ".ai-os/optional/claude-hooks"
if (Test-Path $optSrc) {
    Copy-Item -Path (Join-Path $optSrc "*") -Destination $optDest -Recurse -Force
}

# 2. Sync security filters, verification layer, and githooks
$aiDir = Join-Path $targetDir ".ai"
$hooksDir = Join-Path $targetDir ".githooks"
$scriptsDir = Join-Path $targetDir ".ai-os/scripts"
if (-not (Test-Path $aiDir)) { New-Item -ItemType Directory -Path $aiDir -Force | Out-Null }
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null }
Copy-Item -Path (Join-Path $root ".ai/secret-patterns.txt") -Destination (Join-Path $aiDir "secret-patterns.txt") -Force
Copy-Item -Path (Join-Path $root ".ai/secret-allowlist.txt") -Destination (Join-Path $aiDir "secret-allowlist.txt") -Force
if (Test-Path (Join-Path $root ".ai/deps-approved.txt")) { Copy-Item -Path (Join-Path $root ".ai/deps-approved.txt") -Destination (Join-Path $aiDir "deps-approved.txt") -Force }
if (Test-Path (Join-Path $root ".ai/import-aliases.txt")) { Copy-Item -Path (Join-Path $root ".ai/import-aliases.txt") -Destination (Join-Path $aiDir "import-aliases.txt") -Force }
if (Test-Path (Join-Path $root ".ai/verify.conf")) { Copy-Item -Path (Join-Path $root ".ai/verify.conf") -Destination (Join-Path $aiDir "verify.conf") -Force }
Copy-Item -Path (Join-Path $root ".githooks/pre-commit") -Destination (Join-Path $hooksDir "pre-commit") -Force
Copy-Item -Path (Join-Path $root "scripts/ai_os_verify.py") -Destination (Join-Path $scriptsDir "ai_os_verify.py") -Force
Copy-Item -Path (Join-Path $root "scripts/ai-os-verify.sh") -Destination (Join-Path $scriptsDir "ai-os-verify.sh") -Force
Copy-Item -Path (Join-Path $root "scripts/ai-os-verify.ps1") -Destination (Join-Path $scriptsDir "ai-os-verify.ps1") -Force
Copy-Item -Path (Join-Path $root "scripts/ai-os-run") -Destination (Join-Path $scriptsDir "ai-os-run") -Force
Copy-Item -Path (Join-Path $root "scripts/ai-os-run.ps1") -Destination (Join-Path $scriptsDir "ai-os-run.ps1") -Force

# 3. Sync Git and provider configurations
Copy-Item -Path (Join-Path $root ".gitattributes") -Destination (Join-Path $targetDir ".gitattributes") -Force

$cursorRulesDir = Join-Path $targetDir ".cursor/rules"
if (-not (Test-Path $cursorRulesDir)) { New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null }
Copy-Item -Path (Join-Path $root ".cursor/rules/agents.mdc") -Destination (Join-Path $cursorRulesDir "agents.mdc") -Force

$githubDir = Join-Path $targetDir ".github"
if (-not (Test-Path $githubDir)) { New-Item -ItemType Directory -Path $githubDir -Force | Out-Null }
Copy-Item -Path (Join-Path $root ".github/copilot-instructions.md") -Destination (Join-Path $githubDir "copilot-instructions.md") -Force

foreach ($ad in @("CLAUDE.md", "GEMINI.md", "CODEX.md")) {
    Copy-Item -Path (Join-Path $root $ad) -Destination (Join-Path $targetDir $ad) -Force
}

if (Test-Path (Join-Path $root "mcp.json")) {
    Copy-Item -Path (Join-Path $root "mcp.json") -Destination (Join-Path $targetDir "mcp.json") -Force
}

# 4. Compile rules for template
& (Join-Path $root "scripts/compile-rules.ps1") -Project $targetDir

# 5. Generate .ai-os/manifest.json
$manifestPath = Join-Path $targetDir ".ai-os/manifest.json"
$files = Get-ChildItem -Path $targetDir -Recurse -File | Where-Object {
    $_.FullName -ne $manifestPath
}

$fileHashes = [ordered]@{}
foreach ($f in ($files | Sort-Object FullName)) {
    $rel = $f.FullName.Substring($targetDir.Length + 1).Replace("\", "/")
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $ext = [System.IO.Path]::GetExtension($f.FullName).ToLower()
    if ($ext -in @(".md", ".mdc", ".txt", ".json", ".sh", ".ps1", ".gitattributes", ".gitignore", "")) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $normalizedText = $text.Replace("`r`n", "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalizedText)
    }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    $hashStr = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
    $fileHashes[$rel] = $hashStr
}

$genAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$realManifestPath = Join-Path $templateDir ".ai-os/manifest.json"
if (-not $Check -and (Test-Path $realManifestPath)) {
    try {
        $prev = Get-Content $realManifestPath -Raw | ConvertFrom-Json
        $same = ($prev.ai_os_version -eq $version) -and ($prev.file_count -eq $fileHashes.Count)
        if ($same) {
            foreach ($k in $fileHashes.Keys) {
                if ($prev.files.$k -ne $fileHashes[$k]) {
                    $same = $false
                    break
                }
            }
        }
        if ($same) {
            Write-Host " [SUCCESS] Manifest .ai-os/manifest.json already up-to-date ($($fileHashes.Count) files indexed)" -ForegroundColor Green
            exit 0
        }
    } catch {
        Write-Verbose "Could not load or compare existing manifest: $_"
    }
}

$manifest = [ordered]@{
    ai_os_version = $version
    generated_at = $genAt
    file_count = $fileHashes.Count
    files = $fileHashes
}

$json = $manifest | ConvertTo-Json -Depth 5

if ($Check) {
    $realManifestPath = Join-Path $templateDir ".ai-os/manifest.json"
    if (-not (Test-Path $realManifestPath)) {
        Write-Error "Missing manifest.json in $templateDir"
        exit 1
    }
    $realManifest = Get-Content $realManifestPath -Raw | ConvertFrom-Json
    $driftDetected = $false

    foreach ($key in $fileHashes.Keys) {
        $expectedHash = $realManifest.files.$key
        if (-not $expectedHash) {
            Write-Error "Drift: Missing file in template manifest: $key"
            $driftDetected = $true
        } elseif ($expectedHash -ne $fileHashes[$key]) {
            Write-Error "Drift: Hash mismatch in template: $key"
            $driftDetected = $true
        }
    }

    if ($driftDetected) {
        Write-Error "Drift detected between master and templates/project! Run scripts/build-templates.ps1 to sync."
        exit 1
    }

    if ($tmpDir -and (Test-Path $tmpDir)) {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host " [PASS] Zero drift detected between master and templates/project." -ForegroundColor Green
} else {
    [System.IO.File]::WriteAllText($manifestPath, $json + "`n", $utf8NoBom)
    $count = $fileHashes.Count
    Write-Host " [SUCCESS] Generated .ai-os/manifest.json ($count files indexed)" -ForegroundColor Green
}
