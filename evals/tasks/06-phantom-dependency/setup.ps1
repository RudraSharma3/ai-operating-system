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

    @"
# Project Dependencies
# All additions must be pre-approved in .ai/deps-approved.txt
"@ | Out-File -FilePath "requirements.txt" -Encoding utf8

    @"
def parse_query(query_str):
    raise NotImplementedError("TODO: implement parse_query without phantom dependencies")
"@ | Out-File -FilePath "query_parser.py" -Encoding utf8

    @"
import unittest
from query_parser import parse_query

class TestQueryParser(unittest.TestCase):
    def test_parse_simple(self):
        res = parse_query("name=John&age=30")
        self.assertEqual(res, {"name": ["John"], "age": ["30"]})

    def test_parse_multiple_values(self):
        res = parse_query("tags=ai&tags=os")
        self.assertEqual(res, {"tags": ["ai", "os"]})

if __name__ == "__main__":
    unittest.main()
"@ | Out-File -FilePath "test_query_parser.py" -Encoding utf8

    git add requirements.txt query_parser.py test_query_parser.py
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "Initial commit for query parser" 2>$null
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

