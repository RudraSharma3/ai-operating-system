# Static Analysis & Lint Policy

This document defines the static analysis policy for the AI Operating System repository, including all configured severity thresholds, rule exclusions, and inline suppressions across ShellCheck (Bash) and PSScriptAnalyzer (PowerShell).

---

## 1. Guiding Principles

1. **Zero Warnings on Production Code**: Continuous Integration enforces zero warnings and zero errors for active shell and PowerShell scripts under configured severity profiles.
2. **Explicit Justification for Suppressions**: Every exclusion or inline suppression must be documented with the exact rationale and the number of findings it suppresses.
3. **Defense-in-Depth vs Tool Limitations**: Linter rules designed for generic software libraries that conflict with purposeful CLI tool requirements (e.g. interactive colored terminal output) or dynamic test harnesses are excluded globally or scoped with formal annotations.

---

## 2. PSScriptAnalyzer Policy (PowerShell)

### CI Execution Command
```powershell
Get-ChildItem -Path . -Recurse -Filter "*.ps1" |
    Where-Object { $_.FullName -notmatch '\\\.git\\|node_modules|scratch' } |
    ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_.FullName -Severity Error, Warning -ExcludeRule PSAvoidUsingWriteHost
    }
```

### Global Exclusions
| Excluded Rule | Scope | Findings Hidden | Justification |
| :--- | :--- | :--- | :--- |
| `PSAvoidUsingWriteHost` | Repository-wide in CI (`.github/workflows/ci.yml`) | **245** across 24 scripts | AI-OS PowerShell scripts (`doctor.ps1`, `install.ps1`, `bootstrap.ps1`, `upgrade.ps1`, `token-report.ps1`, `run_evals.ps1`) are CLI terminal utilities that require direct, colored ANSI host output (`Write-Host`) for human-readable diagnostic reports. |

### Inline Suppressions (`[Diagnostics.CodeAnalysis.SuppressMessageAttribute]`)
| File | Suppressed Rule | Findings Hidden | Justification |
| :--- | :--- | :--- | :--- |
| `evals/run_task.ps1` | `PSReviewUnusedParameter` | **6** (`Mode`, `AgentCmd`, `Reference`, `Negative`, `CheckOnly`, `TargetDir`) | Parameters define the standard CLI parameter contract for the evaluation runner and are consumed dynamically within internal execution contexts (`Invoke-SingleTask`). |
| `evals/run_task.ps1` | `PSAvoidUsingInvokeExpression` | **1** (line 138) | The evaluation harness dynamically executes arbitrary agent benchmark commands passed by the benchmark caller. |

---

## 3. ShellCheck Policy (POSIX Bash)

### CI Execution Command
```bash
find . -type f -name "*.sh" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "./scratch/*" -exec shellcheck --severity=warning {} +
shellcheck --severity=warning .githooks/pre-commit templates/project/.githooks/pre-commit
```

### Severity Filter
- **Filter**: `--severity=warning`
- **Rationale**: Restricts analysis to syntax defects, portability bugs, and security risks (severity `error` and `warning`), ignoring purely stylistic formatting opinions (severity `info` and `style`).

### Inline Suppressions (`# shellcheck disable=SC2016`)
SC2016 warns when expressions inside single quotes (`'...'`) contain `$` or backticks `` ` ``, warning that expressions do not expand in single quotes. In AI-OS, single quotes are intentionally used to pass literal syntax without shell expansion.

| File | Suppressed Rule | Target Line / Context | Justification |
| :--- | :--- | :--- | :--- |
| `.githooks/pre-commit` | `SC2016` | Embedded Python script (`python3 -c '...'`) | Python script body contains regex and string syntax that must not be expanded by the parent Bash subshell. |
| `templates/project/.githooks/pre-commit` | `SC2016` | Embedded Python script (`python3 -c '...'`) | Identical template mirror of the pre-commit hook. |
| `scripts/doctor.sh` | `SC2016` | `sed -E 's/.../\1/'` | Substitution backreference `\1` in sed expression must not be expanded by Bash. |
| `scripts/doctor.sh` | `SC2016` | Literal backtick regex | Regex pattern matching literal markdown backticks in doc scanner must not be expanded by Bash. |
| `tests/test_installer.sh` | `SC2016` | Test fixture markdown output (line 458) | Deliberately writes literal markdown backticks to test doc scanner warning detection. |
| `tests/test_installer.sh` | `SC2016` | Test fixture markdown output (line 464) | Deliberately writes literal markdown backticks to test doc scanner passing detection. |
| `tests/test_installer.sh` | `SC2016` | Test fixture markdown output (line 470) | Deliberately writes literal markdown backticks to test doc scanner mode warning detection. |

