[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "Stop"

$origDir = Get-Location
try {
    Set-Location $TargetDir
    @'
def divide(a, b):
    if b == 0:
        return None
    return a / b
'@ | Set-Content -Path "calculator.py" -Encoding ASCII

    git add calculator.py
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    git commit -qm "fix: handle zero division safely by returning None"
    $ErrorActionPreference = $prev
} finally {
    Set-Location $origDir
}
