<#
.SYNOPSIS
    One-Shot Project Scaffolding CLI for AI Operating System.
.DESCRIPTION
    Automates creating a new software repository using the AI Operating System template.
.PARAMETER Name
    The name of the new project / folder.
.PARAMETER Stack
    The technology stack (e.g., "Next.js + Tailwind", "FastAPI + PostgreSQL", "Go + React").
.PARAMETER TargetDir
    The parent directory where the project should be created. Defaults to current directory.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [string]$Stack,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetDir = (Get-Location).Path
)

# Interactive prompts if parameters are missing
if (-not $Name) {
    $Name = Read-Host "Enter Project Name (e.g. my-awesome-app)"
}
if (-not $Stack) {
    $Stack = Read-Host "Enter Tech Stack (e.g. Next.js + Tailwind + Supabase)"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $RepoRoot "templates\project"
$ProjectPath = Join-Path $TargetDir $Name

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " 🚀 Initializing AI Operating System Project: $Name" -ForegroundColor Cyan
Write-Host " Stack: $Stack" -ForegroundColor Cyan
Write-Host " Path:  $ProjectPath" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

if (Test-Path $ProjectPath) {
    Write-Error "Directory '$ProjectPath' already exists! Aborting to prevent overwrite."
    exit 1
}

# 1. Create project directory and copy template
Write-Host "`n[1/5] Copying AI Operating System template..." -ForegroundColor Green
New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
Copy-Item -Path "$TemplateDir\*" -Destination $ProjectPath -Recurse -Force
if (Test-Path "$TemplateDir\.ai") {
    Copy-Item -Path "$TemplateDir\.ai" -Destination $ProjectPath -Recurse -Force
}
if (Test-Path "$TemplateDir\.githooks") {
    Copy-Item -Path "$TemplateDir\.githooks" -Destination $ProjectPath -Recurse -Force
}

# 2. Populate project purpose and architecture
Write-Host "[2/5] Populating architecture & conventions with stack: $Stack..." -ForegroundColor Green
$ArchPath = Join-Path $ProjectPath "docs\architecture.md"
if (Test-Path $ArchPath) {
    $ArchContent = Get-Content $ArchPath -Raw
    $ArchContent = $ArchContent -replace '<!-- What does this project do\? Who are the primary users\? What problem does it solve\? -->', "Primary application: $Name. Stack: $Stack."
    Set-Content -Path $ArchPath -Value $ArchContent -Force
}

# 3. Populate project AGENTS.md
$AgentsPath = Join-Path $ProjectPath "AGENTS.md"
if (Test-Path $AgentsPath) {
    $AgentsContent = Get-Content $AgentsPath -Raw
    $AgentsContent = $AgentsContent -replace '<!-- State the primary user problem, application outcome, and core value proposition. -->', "Application: $Name`nTarget Stack: $Stack"
    Set-Content -Path $AgentsPath -Value $AgentsContent -Force
}

# 4. Initialize Git repository
Write-Host "[3/5] Initializing Git repository..." -ForegroundColor Green
Push-Location $ProjectPath
try {
    git init | Out-Null
    
    # Configure git hooks if present
    $HooksDir = Join-Path $ProjectPath ".githooks"
    if (Test-Path $HooksDir) {
        git config core.hooksPath .githooks
    }

    # 5. Create initial baseline commit
    Write-Host "[4/5] Creating baseline commit..." -ForegroundColor Green
    git add .
    git commit -m "feat: initialize $Name with AI Operating System ($Stack)" | Out-Null
    Write-Host "[5/5] Project $Name successfully scaffolded!" -ForegroundColor Green
}
finally {
    Pop-Location
}

Write-Host "`n====================================================" -ForegroundColor Yellow
Write-Host " ✨ SUCCESS! Your new project is ready." -ForegroundColor Yellow
Write-Host " Next steps:" -ForegroundColor Yellow
Write-Host "   1. cd $ProjectPath" -ForegroundColor White
Write-Host "   2. Open in your AI IDE (Antigravity, Cursor, Claude Code, VSCode)" -ForegroundColor White
Write-Host "   3. Prompt your agent: 'I want to build $Name using $Stack'" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Yellow
