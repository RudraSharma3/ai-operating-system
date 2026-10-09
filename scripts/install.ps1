param (
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = (Get-Location).Path
)

# Detect Git User and Project Name
$gitUser = (git config user.name 2>$null)
if (-not $gitUser) { $gitUser = $env:USERNAME }
if (-not $gitUser) { $gitUser = "Developer" }

$projectName = (Split-Path -Leaf $TargetPath)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $RepoRoot "templates\project"

# ASCII Logo Header
Write-Host ""
Write-Host "    ___    ____      ____  _____ " -ForegroundColor Cyan
Write-Host "   /   |  /  _/     / __ \/ ___/ " -ForegroundColor Cyan
Write-Host "  / /| |  / /______/ / / /\__ \  " -ForegroundColor Cyan
Write-Host " / ___ |_/ /_____/ /_/ /___/ /  " -ForegroundColor Cyan
Write-Host "/_/  |_/___/      \____//____/   " -ForegroundColor Cyan
Write-Host "   ++ AI OPERATING SYSTEM v2.0 ++" -ForegroundColor Magenta
Write-Host "       by Rudra Sharma" -ForegroundColor DarkGray
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " AI Operating System (AI-OS by Rudra Sharma) - Project Integrator" -ForegroundColor Cyan
Write-Host " Target Project: $projectName ($TargetPath)" -ForegroundColor Cyan
Write-Host " User:           $gitUser" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# Safety Check: Verify Target Exists
if (-not (Test-Path $TargetPath)) {
    Write-Error "Target directory '$TargetPath' does not exist! Please check path."
    exit 1
}

# Step 1: Per-File Non-Destructive Copy
Write-Host "`n[1/3] Copying AI-OS architecture, rule files, and playbooks..." -ForegroundColor Green
$templateFiles = Get-ChildItem -Path $TemplateDir -Recurse -File
foreach ($file in $templateFiles) {
    $relative = $file.FullName.Substring($TemplateDir.Length).TrimStart("\", "/")
    $destFile = Join-Path $TargetPath $relative
    $destDir = Split-Path -Parent $destFile
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (-not (Test-Path $destFile)) {
        Copy-Item -Path $file.FullName -Destination $destFile -Force
        Write-Host "  + Added $relative" -ForegroundColor Gray
    } else {
        Write-Host "  = Preserved existing $relative" -ForegroundColor DarkGray
    }
}

# Non-destructive .gitignore merge
$destGitignore = Join-Path $TargetPath ".gitignore"
$srcGitignore = Join-Path $TemplateDir ".gitignore"
if (Test-Path $destGitignore) {
    $currentContent = Get-Content $destGitignore -Raw -ErrorAction SilentlyContinue
    if ($currentContent -notmatch "# --- AI-OS START ---") {
        $aiosBlock = "`n# --- AI-OS START ---`n.env`n.env.*`n!.env.example`n!.env.sample`n!.env.template`n!.env.dist`n# --- AI-OS END ---`n"
        Add-Content -Path $destGitignore -Value $aiosBlock
        Write-Host "  + Merged AI-OS secret rules into existing .gitignore" -ForegroundColor Gray
    } else {
        Write-Host "  = Existing .gitignore already contains AI-OS rules" -ForegroundColor DarkGray
    }
} else {
    Copy-Item -Path $srcGitignore -Destination $destGitignore -Force
    Write-Host "  + Created .gitignore with AI-OS rules" -ForegroundColor Gray
}

# Step 2: Configure Git Hooks and Chaining
Write-Host "`n[2/3] Configuring secret protection and Git hooks..." -ForegroundColor Green
Push-Location $TargetPath
try {
    if (Test-Path ".git") {
        $existingHooksPath = (git config core.hooksPath 2>$null)
        if ($existingHooksPath -and ($existingHooksPath -ne ".githooks")) {
            Write-Host "  [INFO] Detected existing core.hooksPath='$existingHooksPath'." -ForegroundColor Cyan
            Write-Host "         Preserving existing hook path and chaining AI-OS guard..." -ForegroundColor Cyan
            if (-not (Test-Path $existingHooksPath)) {
                New-Item -ItemType Directory -Path $existingHooksPath -Force | Out-Null
            }
            $targetHook = Join-Path $existingHooksPath "pre-commit"
            $chainCmd = '[ -f .githooks/pre-commit ] && .githooks/pre-commit "$@"'
            if (Test-Path $targetHook) {
                $hookContent = Get-Content $targetHook -Raw -ErrorAction SilentlyContinue
                if ($hookContent -notmatch "\.githooks/pre-commit") {
                    $appendVal = "`n# AI-OS Pre-Commit Guard Chained Delegation`n" + $chainCmd
                    Add-Content -Path $targetHook -Value $appendVal
                    Write-Host "  + Chained AI-OS guard into $targetHook" -ForegroundColor Gray
                } else {
                    Write-Host "  = AI-OS guard already chained in $targetHook" -ForegroundColor DarkGray
                }
            } else {
                $lines = @(
                    "#!/usr/bin/env bash",
                    "# Chained pre-commit hook delegating to AI-OS guard",
                    $chainCmd
                )
                [System.IO.File]::WriteAllLines($targetHook, $lines)
                Write-Host "  + Created $targetHook with AI-OS guard delegation" -ForegroundColor Gray
            }
        } else {
            git config core.hooksPath .githooks
            Write-Host "  + Set core.hooksPath to .githooks" -ForegroundColor Gray
        }
    }
} finally {
    Pop-Location
}

# Step 3: Run Diagnostic Validation
Write-Host "`n[3/3] Running health integrity check..." -ForegroundColor Green
$doctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript -ProjectPath $TargetPath
}

Write-Host "`n========================================================================" -ForegroundColor Yellow
Write-Host " Hey $gitUser! AI-OS by Rudra is successfully integrated" -ForegroundColor Yellow
Write-Host "    into your project '$projectName'!" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Yellow

Write-Host "`n NEXT STEP: Open '$projectName' in your AI IDE (Antigravity/Cursor/Claude Code)" -ForegroundColor Cyan
Write-Host "   and paste this EXACT first prompt into chat:" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor White
Write-Host "Read AGENTS.md and follow .ai-os/playbooks/codebase-analysis.md to analyze this repository." -ForegroundColor Green
Write-Host "Please map our existing codebase, update docs/architecture.md, docs/conventions.md," -ForegroundColor Green
Write-Host "and docs/graph.md with our current components, tech stack, and data flow," -ForegroundColor Green
Write-Host "and conclude with the AI-OS integration greeting and next steps menu." -ForegroundColor Green
Write-Host "------------------------------------------------------------------------" -ForegroundColor White
Write-Host ""
