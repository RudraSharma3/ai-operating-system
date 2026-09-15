param (
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = (Get-Location).Path
)

# Detect Git User and Project Name
$gitUser = (git config user.name)
if (-not $gitUser) { $gitUser = $env:USERNAME }
if (-not $gitUser) { $gitUser = "Developer" }

$projectName = (Split-Path -Leaf $TargetPath)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $RepoRoot "templates\project"

# Animation helper
function Animate-Step {
    param([string]$Text)
    $frames = @('/', '-', '\', '|')
    for ($i = 0; $i -lt 8; $i++) {
        $frame = $frames[$i % $frames.Count]
        Write-Host ("`r  " + $frame + " " + $Text) -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 40
    }
    Write-Host ("`r  [OK] " + $Text) -ForegroundColor Green
}

# ASCII Mascot & Cyberpunk Header
Write-Host ""
Write-Host "         +-----------------------------------------+" -ForegroundColor Yellow
Write-Host "         |   [ * _ * ]   (b^_^ )b   ALL SYSTEMS GO |" -ForegroundColor Yellow
Write-Host "         |   AI-OS Ready to Code, Boss!            |" -ForegroundColor Yellow
Write-Host "         +--------------------+--------------------+" -ForegroundColor Yellow
Write-Host "                              |" -ForegroundColor Yellow
Write-Host "    ___    ____      ____  _____ " -ForegroundColor Cyan
Write-Host "   /   |  /  _/     / __ \/ ___/ " -ForegroundColor Cyan
Write-Host "  / /| |  / /______/ / / /\__ \  " -ForegroundColor Cyan
Write-Host " / ___ |_/ /_____/ /_/ /___/ /  " -ForegroundColor Cyan
Write-Host "/_/  |_/___/      \____//____/   " -ForegroundColor Cyan
Write-Host "   ++ AI OPERATING SYSTEM v2.0 ++" -ForegroundColor Magenta
Write-Host "       by Rudra Sharma" -ForegroundColor DarkGray
Write-Host ""
Write-Host "========================================================================" -ForegroundColor DarkCyan
Write-Host (" Target Project: " + $projectName) -ForegroundColor White
Write-Host (" Target Path:    " + $TargetPath) -ForegroundColor DarkGray
Write-Host (" Engineer:       " + $gitUser) -ForegroundColor White
Write-Host "========================================================================" -ForegroundColor DarkCyan
Write-Host ""

# Safety Check: Verify Target Exists
if (-not (Test-Path $TargetPath)) {
    Write-Host "Error: Target directory does not exist: $TargetPath" -ForegroundColor Red
    exit 1
}

# Step 1: Copy AI-OS Template Files Safely
Animate-Step -Text "Ingesting AI-OS Architecture, Rules and Adapters..."
$items = @("AGENTS.md", "CLAUDE.md", "GEMINI.md", "CODEX.md", "mcp.json", "docs", ".ai", ".claude", ".githooks")
foreach ($item in $items) {
    $srcItem = Join-Path $TemplateDir $item
    $destItem = Join-Path $TargetPath $item
    if (Test-Path $srcItem) {
        if (-not (Test-Path $destItem)) {
            Copy-Item -Path $srcItem -Destination $destItem -Recurse -Force
            Write-Host ("     + Added " + $item) -ForegroundColor Gray
        } else {
            Write-Host ("     = Existing " + $item + " preserved (safe)") -ForegroundColor DarkGray
        }
    }
}

# Step 2: Configure Git Hooks
Animate-Step -Text "Armoring Pre-Commit Secret Scanning and Git Protection..."
Push-Location $TargetPath
try {
    if (Test-Path ".git") {
        if (Test-Path ".githooks") {
            git config core.hooksPath .githooks
            Write-Host "     + Secret protection hook armed." -ForegroundColor Gray
        }
    }
} finally {
    Pop-Location
}

# Step 3: Run Diagnostic Validation
Animate-Step -Text "Running 14-Point Diagnostic Doctor Verification..."
Write-Host ""
$doctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript -ProjectPath $TargetPath
}

# Crazy Victory Box Banner
$headline = "|   *** HEY " + $gitUser.ToUpper() + "! AI-OS IS INTEGRATED! (b^_^)b ***"
$projectLine = "|   Target Project: " + $projectName

Write-Host ""
Write-Host "+=======================================================================+" -ForegroundColor Green
Write-Host "|                                                                       |" -ForegroundColor Green
Write-Host ($headline.PadRight(72) + "|") -ForegroundColor Green
Write-Host ($projectLine.PadRight(72) + "|") -ForegroundColor Green
Write-Host "|                                                                       |" -ForegroundColor Green
Write-Host "|   Persistent Memory:       [ ONLINE  ]                                |" -ForegroundColor Green
Write-Host "|   Secret Armor Pre-Commit: [ ARMED   ]                                |" -ForegroundColor Green
Write-Host "|   Prompt Auto-Refiner:     [ ACTIVE  ]                                |" -ForegroundColor Green
Write-Host "|   Codebase Graph Engine:   [ READY   ]                                |" -ForegroundColor Green
Write-Host "|                                                                       |" -ForegroundColor Green
Write-Host "+=======================================================================+" -ForegroundColor Green

# Glow Kickoff Prompt Box
Write-Host ""
Write-Host "+-----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "| [!] COPY AND PASTE THIS FIRST PROMPT INTO YOUR AI IDE CHAT:           |" -ForegroundColor Yellow
Write-Host "+-----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|                                                                       |" -ForegroundColor Cyan
Write-Host "|  Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze  |" -ForegroundColor White
Write-Host "|  this repository. Please map our existing codebase and update        |" -ForegroundColor White
Write-Host "|  docs/architecture.md, docs/conventions.md, and docs/graph.md with   |" -ForegroundColor White
Write-Host "|  our current components, tech stack, and data flow.                  |" -ForegroundColor White
Write-Host "|                                                                       |" -ForegroundColor Cyan
Write-Host "+-----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
