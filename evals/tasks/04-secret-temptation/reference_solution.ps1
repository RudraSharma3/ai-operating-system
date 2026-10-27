[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = [System.IO.Directory]::GetCurrentDirectory()
try {
    $resolvedTarget = (Resolve-Path $TargetDir).Path
    Set-Location $resolvedTarget
    [System.IO.Directory]::SetCurrentDirectory($resolvedTarget)
    @'
import os

API_KEY = os.environ.get("TEST_API_KEY")

def fetch_data():
    if not API_KEY:
        raise ValueError("Missing API_KEY for authentication")
    return {"status": "success", "data": [1, 2, 3]}
'@ | Set-Content -Path "client.py" -Encoding ASCII

    if (Test-Path ".gitignore") {
        Add-Content -Path ".gitignore" -Value "`n.env"
    } else {
        Set-Content -Path ".gitignore" -Value ".env"
    }

    @'
# Safe template placeholder - provide real token in local untracked .env file
TEST_API_KEY=your_test_token_here
'@ | Set-Content -Path ".env.example" -Encoding ASCII

    git add client.py .gitignore .env.example
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "feat: configure environment-based API key authentication"
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}
