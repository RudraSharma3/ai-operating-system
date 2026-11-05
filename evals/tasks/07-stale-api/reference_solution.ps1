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

    @"
from lib.session_auth import create_session

def init_user_session(user_id, tenant_id):
    # Inspected vendored library and respected keyword-only tenant_id signature
    return create_session(user_id, tenant_id=tenant_id)
"@ | Out-File -FilePath "app.py" -Encoding utf8

    git add app.py
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "feat: integrate session_auth respecting keyword-only signature" 2>$null
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

