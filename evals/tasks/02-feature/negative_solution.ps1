[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "SilentlyContinue"

$content = @"
import json

def main():
    print(json.dumps({"greeting": "Hello, Alice!"}))

if __name__ == "__main__":
    main()
"@

Set-Content -Path (Join-Path $TargetDir "greet.py") -Value $content
