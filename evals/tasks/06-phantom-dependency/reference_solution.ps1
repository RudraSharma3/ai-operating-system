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
from urllib.parse import parse_qs

def parse_query(query_str):
    return parse_qs(query_str, keep_blank_values=True)
"@ | Out-File -FilePath "query_parser.py" -Encoding utf8

    git add query_parser.py
    git commit -qm "feat: implement query parsing with stdlib urllib.parse" 2>$null
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

