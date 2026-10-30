# AI-OS Claude Code Hook: PreToolUse (PowerShell)
# Blocks unauthorized direct edits to governance files and subversive git commands.
# Input: JSON context delivered via stdin. Never executes tool input.

$ErrorActionPreference = "SilentlyContinue"

try {
    $rawInput = [Console]::In.ReadToEnd()
    if (-not $rawInput) { exit 0 }
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$toolName = $data.tool_name
$toolInput = $data.tool_input

# Check 1: Direct governance file edits (Write / Edit / NotebookEdit)
$writeTools = @("Write", "Edit", "NotebookEdit")
if ($toolName -in $writeTools) {
    $targetPath = if ($toolInput.file_path) { $toolInput.file_path } `
                  elseif ($toolInput.path) { $toolInput.path } `
                  else { "" }
    $targetPath = $targetPath.ToString().Replace("\", "/").Trim()
    
    if ($targetPath -match "(^|/)(AGENTS\.md|\.ai/rules/.*|\.githooks/.*|scripts/.*|\.ai/deps-approved\.txt)$") {
        if ($env:AI_OS_ALLOW_GOVERNANCE_EDIT -ne "1") {
            @{
                hookSpecificOutput = @{
                    hookEventName = "PreToolUse"
                    permissionDecision = "deny"
                    permissionDecisionReason = "Direct edits to AI-OS governance files (AGENTS.md, .ai/rules/, .githooks/, scripts/, .ai/deps-approved.txt) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
                }
            } | ConvertTo-Json -Depth 4
            exit 0
        }
    }
}

# Check 2: Subversive Git Commands in Bash / PowerShell
$shellTools = @("Bash", "PowerShell")
if ($toolName -in $shellTools) {
    $cmd = if ($toolInput.command) { $toolInput.command } else { "" }
    $cmd = $cmd.ToString()
    
    $noVerify = $cmd -match "\bgit\s+commit\b.*--no-verify"
    $forcePush = $cmd -match "\bgit\s+push\b.*(--force|-f\b|--force-with-lease)"
    
    if ($noVerify -or $forcePush) {
        $subversive = if ($noVerify) { "--no-verify" } else { "--force" }
        @{
            hookSpecificOutput = @{
                hookEventName = "PreToolUse"
                permissionDecision = "deny"
                permissionDecisionReason = "Subversive git command detected: $subversive is blocked by AI-OS governance."
            }
        } | ConvertTo-Json -Depth 4
        exit 0
    }

    # Check 3: Best-effort heuristic deny for shell writes / appends to .ai/deps-approved.txt only
    # Intercepts: >, >>, tee (with or without -a), sed -i, cp, mv, dd of=
    $shellWriteDeps = ($cmd -match "(>>?)\s*['""]?.*\.ai/deps-approved\.txt") -or `
                      ($cmd -match "\btee(\s+-[a-zA-Z0-9]+)*\s+['""]?.*\.ai/deps-approved\.txt") -or `
                      ($cmd -match "\bsed\s+-[a-zA-Z0-9]*i.*\.ai/deps-approved\.txt") -or `
                      ($cmd -match "\bcp\s+.*[\s'""]\.ai/deps-approved\.txt") -or `
                      ($cmd -match "\bmv\s+.*[\s'""]\.ai/deps-approved\.txt") -or `
                      ($cmd -match "\bdd\s+.*of=['""]?.*\.ai/deps-approved\.txt")

    if ($shellWriteDeps) {
        if ($env:AI_OS_ALLOW_GOVERNANCE_EDIT -ne "1") {
            @{
                hookSpecificOutput = @{
                    hookEventName = "PreToolUse"
                    permissionDecision = "deny"
                    permissionDecisionReason = "Shell write redirection to .ai/deps-approved.txt detected (heuristic). Direct modification blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
                }
            } | ConvertTo-Json -Depth 4
            exit 0
        }
    }
}

exit 0
