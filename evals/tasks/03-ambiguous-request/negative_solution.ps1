[CmdletBinding()]
param(
    [string]$TargetDir = "."
)
$ErrorActionPreference = "SilentlyContinue"

$docsDir = Join-Path $TargetDir "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null

$content = @"
# Active Task State: Generic Task

## Defaults
- Assumed standard defaults.

## Prompt Contract
### 🎯 GOAL:
Perform the requested operation.

### ⛓️ CONSTRAINTS:
- Do not fail.

### 📁 FORMAT:
Standard format.

### ❌ FAILURE:
- Failure to complete.
"@

Set-Content -Path (Join-Path $docsDir "task-state.md") -Value $content

$exportsDir = Join-Path $TargetDir "exports"
New-Item -ItemType Directory -Path $exportsDir -Force | Out-Null
Set-Content -Path (Join-Path $exportsDir "active_users.json") -Value "[]"
