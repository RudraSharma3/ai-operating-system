[CmdletBinding()]
param(
    [string]$Target = ".",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = (Get-Item $PSScriptRoot).Parent.FullName
$templateDir = Join-Path $root "templates/project"
$targetDir = (Resolve-Path $Target).Path

$upstreamManifestPath = Join-Path $templateDir ".ai-os/manifest.json"
if (-not (Test-Path $upstreamManifestPath)) {
    Write-Host " Upstream manifest missing, building templates first..." -ForegroundColor Yellow
    & (Join-Path $root "scripts/build-templates.ps1")
}

$upstreamManifest = Get-Content $upstreamManifestPath -Raw | ConvertFrom-Json
$targetManifestPath = Join-Path $targetDir ".ai-os/manifest.json"

$oldManifest = $null
if (Test-Path $targetManifestPath) {
    try {
        $oldManifest = Get-Content $targetManifestPath -Raw | ConvertFrom-Json
    } catch {
        $oldManifest = $null
    }
} else {
    Write-Host " [LEGACY] No prior manifest found (pre-manifest legacy install detected). Migrating cleanly to manifest tracking..." -ForegroundColor Yellow
}

Write-Host " AI-OS Safe Upgrade Engine" -ForegroundColor Cyan
Write-Host " Target Project: $targetDir"
if ($DryRun) {
    Write-Host " Mode: DRY RUN (no files will be modified)" -ForegroundColor Yellow
}

$textExtensions = @(".md", ".txt", ".json", ".sh", ".ps1", ".gitattributes", ".gitignore", "")

function Get-FileHashString($filePath) {
    if (-not (Test-Path $filePath)) { return $null }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
    if ($ext -in $textExtensions) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $normalizedText = $text.Replace("`r`n", "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalizedText)
    }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    return ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

$stats = @{
    added = 0
    upgraded = 0
    preserved = 0
    up_to_date = 0
}

$newTargetFiles = [ordered]@{}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

foreach ($prop in $upstreamManifest.files.PSObject.Properties) {
    $relPath = $prop.Name
    $upHash = $prop.Value
    
    $srcFile = Join-Path $templateDir $relPath
    $dstFile = Join-Path $targetDir $relPath
    
    if (-not (Test-Path $dstFile)) {
        Write-Host " [+] Added: $relPath" -ForegroundColor Green
        $stats.added++
        if (-not $DryRun) {
            $parent = Split-Path -Parent $dstFile
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -Path $srcFile -Destination $dstFile -Force
        }
        $newTargetFiles[$relPath] = $upHash
    } else {
        $currentHash = Get-FileHashString $dstFile
        if ($currentHash -eq $upHash) {
            $stats.up_to_date++
            $newTargetFiles[$relPath] = $upHash
        } else {
            $oldHash = $null
            if ($oldManifest -and $oldManifest.files -and $oldManifest.files.$relPath) {
                $oldHash = $oldManifest.files.$relPath
            }
            if ($oldHash -and ($currentHash -eq $oldHash)) {
                # File was never modified by user since last install
                Write-Host " [^] Upgraded: $relPath" -ForegroundColor Cyan
                $stats.upgraded++
                if (-not $DryRun) {
                    Copy-Item -Path $srcFile -Destination $dstFile -Force
                }
                $newTargetFiles[$relPath] = $upHash
            } else {
                # User customized file
                Write-Host " [ARMOR] Preserved customized: $relPath" -ForegroundColor Yellow
                $stats.preserved++
                if (-not $DryRun) {
                    $updateCandidate = $dstFile + ".ai-os-update"
                    Copy-Item -Path $srcFile -Destination $updateCandidate -Force
                }
                $newTargetFiles[$relPath] = $currentHash
            }
        }
    }
}

if (-not $DryRun) {
    $targetAiOsDir = Join-Path $targetDir ".ai-os"
    if (-not (Test-Path $targetAiOsDir)) { New-Item -ItemType Directory -Path $targetAiOsDir -Force | Out-Null }
    
    $updatedManifest = [ordered]@{
        ai_os_version = $upstreamManifest.ai_os_version
        upgraded_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        file_count = $newTargetFiles.Count
        files = $newTargetFiles
    }
    $json = $updatedManifest | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($targetManifestPath, $json + "`n", $utf8NoBom)
}

Write-Host "====================================================" -ForegroundColor Gray
Write-Host " Upgrade Summary: $($stats.upgraded) upgraded, $($stats.added) added, $($stats.preserved) customized preserved, $($stats.up_to_date) already up-to-date." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Gray
