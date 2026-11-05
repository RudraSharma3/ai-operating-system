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

    if (-not (Test-Path ".git")) {
        git init -q
        git config user.name "AI-OS Eval"
        git config user.email "eval@ai-os.dev"
    }

    $libDir = Join-Path $resolvedTarget "lib"
    if (-not (Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir -Force | Out-Null }
    "" | Out-File -FilePath (Join-Path $libDir "__init__.py") -Encoding utf8

    @"
"""
Internal vendored library: session_auth (v3.0.0)
BREAKING CHANGE IN v3:
Legacy v2 signature: create_session(user_id, ttl=3600)
Current v3 signature: create_session(user_id, *, tenant_id, ttl=3600)
"""

def create_session(user_id, *, tenant_id, ttl=3600):
    if not isinstance(user_id, str) or not user_id:
        raise ValueError("user_id must be a non-empty string")
    if not isinstance(tenant_id, str) or not tenant_id:
        raise TypeError("tenant_id must be passed as a keyword argument and non-empty")
    return {
        "session_id": f"sess_{tenant_id}_{user_id}",
        "user_id": user_id,
        "tenant_id": tenant_id,
        "ttl": ttl,
    }
"@ | Out-File -FilePath (Join-Path $libDir "session_auth.py") -Encoding utf8

    @"
def init_user_session(user_id, tenant_id):
    raise NotImplementedError("TODO: Inspect lib/session_auth.py and call create_session with correct signature")
"@ | Out-File -FilePath "app.py" -Encoding utf8

    @"
import unittest
from app import init_user_session

class TestApp(unittest.TestCase):
    def test_session_creation(self):
        sess = init_user_session("alice", "acme-corp")
        self.assertEqual(sess["user_id"], "alice")
        self.assertEqual(sess["tenant_id"], "acme-corp")
        self.assertEqual(sess["session_id"], "sess_acme-corp_alice")
        self.assertEqual(sess["ttl"], 3600)

if __name__ == "__main__":
    unittest.main()
"@ | Out-File -FilePath "test_app.py" -Encoding utf8

    git add lib/ app.py test_app.py
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "Initial commit with vendored library v3" 2>$null
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

