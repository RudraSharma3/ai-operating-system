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
def divide(a, b):
    return a / b
'@ | Set-Content -Path "calculator.py" -Encoding ASCII

    @'
import unittest
from calculator import divide

class TestCalculator(unittest.TestCase):
    def test_divide_valid(self):
        self.assertEqual(divide(10, 2), 5)

    def test_divide_by_zero_returns_none(self):
        self.assertIsNone(divide(10, 0))

if __name__ == "__main__":
    unittest.main()
'@ | Set-Content -Path "test_calculator.py" -Encoding ASCII

    git add calculator.py test_calculator.py
    git commit -qm "Initial commit with buggy calculator" 2>$null
} finally {
    Set-Location $origDir
}
