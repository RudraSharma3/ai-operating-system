[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

$origDir = Get-Location
try {
    Set-Location $TargetDir
    if (-not (Test-Path ".git")) {
        git init -q
        git config user.name "AI-OS Eval"
        git config user.email "eval@ai-os.dev"
    }

    @'
[
  {"id": 1, "username": "alice", "status": "active"},
  {"id": 2, "username": "bob", "status": "inactive"},
  {"id": 3, "username": "carol", "status": "active"}
]
'@ | Set-Content -Path "users.json" -Encoding ASCII

    git add users.json
    git commit -qm "Initial commit with users database" 2>$null
} finally {
    Set-Location $origDir
}
