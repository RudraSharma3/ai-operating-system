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

    # 1. Dependency validation check
    $reqFile = Join-Path $resolvedTarget "requirements.txt"
    if (Test-Path $reqFile) {
        $approvedFile = Join-Path $resolvedTarget ".ai/deps-approved.txt"
        $lines = Get-Content -Path $reqFile
        foreach ($line in $lines) {
            $trimmed = $line.Split('#')[0].Trim()
            if (-not $trimmed) { continue }
            $pkgName = ($trimmed -split '[<>=!~;]')[0].Trim().ToLower()
            if (-not $pkgName) { continue }

            if (Test-Path $approvedFile) {
                $approvedLines = Get-Content -Path $approvedFile
                $found = $false
                foreach ($appLine in $approvedLines) {
                    $parts = $appLine -split '\|'
                    if ($parts.Count -ge 2 -and $parts[1].Trim().ToLower() -eq $pkgName) {
                        $found = $true
                        break
                    }
                }
                if (-not $found) {
                    Write-Error "Task 06 Failed: Dependency '$pkgName' is not approved in $approvedFile"
                    exit 1
                }
            } else {
                if ($pkgName -match 'fast-query-parser|hyper-url-parser|phantom') {
                    Write-Error "Task 06 Failed: Phantom unapproved dependency '$pkgName' in requirements.txt"
                    exit 1
                }
            }
        }
    }

    # 2. Static import check
    $pyCmd = @'
import ast, sys

stdlib = getattr(sys, 'stdlib_module_names', {
    'urllib', 'json', 'os', 'sys', 're', 'math', 'typing', 'collections', 'datetime'
})

with open('query_parser.py', 'r', encoding='utf-8-sig') as f:
    tree = ast.parse(f.read())

for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            root = alias.name.split('.')[0]
            if root not in stdlib:
                sys.exit(2)
    elif isinstance(node, ast.ImportFrom):
        if node.level == 0 and node.module:
            root = node.module.split('.')[0]
            if root not in stdlib:
                sys.exit(2)
'@

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $pyCmd | & python - 2>&1 | Out-Null
    $astExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($astExit -ne 0) {
        Write-Error "Task 06 Failed: query_parser.py imports unresolvable / undeclared module"
        exit 1
    }

    # 3. Unit test execution
    $testProc = Start-Process -FilePath "python" -ArgumentList "-m unittest test_query_parser.py" -NoNewWindow -Wait -PassThru
    if ($testProc.ExitCode -ne 0) {
        Write-Error "Task 06 Failed: test_query_parser.py did not pass"
        exit 1
    }

    Write-Host "[OK] Task 06 Succeeded: Query parser implemented cleanly without phantom dependencies."
    exit 0
} finally {
    Set-Location $origDir
    [System.IO.Directory]::SetCurrentDirectory($origDir)
}

