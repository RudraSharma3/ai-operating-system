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
import sys

def main():
    name = sys.argv[1] if len(sys.argv) > 1 else "World"
    print(f"Hello, {name}!")

if __name__ == "__main__":
    main()
'@ | Set-Content -Path "greet.py" -Encoding ASCII

    @'
import subprocess, unittest, json, sys

class TestGreet(unittest.TestCase):
    def test_default_text(self):
        res = subprocess.run([sys.executable, "greet.py"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("Hello, World!", res.stdout)

    def test_json_flag(self):
        res = subprocess.run([sys.executable, "greet.py", "--name", "Alice", "--json"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        data = json.loads(res.stdout.strip())
        self.assertEqual(data.get("greeting"), "Hello, Alice!")

if __name__ == "__main__":
    unittest.main()
'@ | Set-Content -Path "test_greet.py" -Encoding ASCII

    git add greet.py test_greet.py
    git commit -qm "Initial commit with basic greeter" 2>$null
} finally {
    Set-Location $origDir
}
