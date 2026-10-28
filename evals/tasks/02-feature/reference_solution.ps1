[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = Get-Location
try {
    Set-Location $TargetDir
    @'
import sys
import argparse
import json

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="World")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.json:
        print(json.dumps({"greeting": f"Hello, {args.name}!"}))
    else:
        print(f"Hello, {args.name}!")

if __name__ == "__main__":
    main()
'@ | Set-Content -Path "greet.py" -Encoding ASCII

    git add greet.py
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "feat: add --json and --name flag support to greeter"
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
}
