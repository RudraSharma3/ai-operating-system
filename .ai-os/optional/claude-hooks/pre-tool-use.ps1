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

# Check 1: Direct governance file edits (Write / Edit)
$writeTools = @("Write", "Edit", "NotebookEdit", "FileEdit", "WriteToFile", "ReplaceFileContent", "multi_replace_file_content", "replace_file_content", "write_to_file")
if ($toolName -in $writeTools) {
    $targetPath = if ($toolInput.file_path) { $toolInput.file_path } `
                  elseif ($toolInput.path) { $toolInput.path } `
                  elseif ($toolInput.target_file) { $toolInput.target_file } `
                  elseif ($toolInput.TargetFile) { $toolInput.TargetFile } `
                  else { "" }
    $targetPath = $targetPath.ToString().Replace("\", "/").Trim()
    
    if ($targetPath -match "(^|/)(AGENTS\.md|\.ai/rules/.*|\.githooks/.*|scripts/.*|\.ai/evidence/.*)$") {
        if ($env:AI_OS_ALLOW_GOVERNANCE_EDIT -ne "1") {
            @{
                hookSpecificOutput = @{
                    hookEventName = "PreToolUse"
                    permissionDecision = "deny"
                    permissionDecisionReason = "Direct edits to AI-OS governance and evidence files (AGENTS.md, .ai/rules/, .githooks/, scripts/, .ai/evidence/) are blocked. Set AI_OS_ALLOW_GOVERNANCE_EDIT=1 to allow."
                }
            } | ConvertTo-Json -Depth 4
            exit 0
        }
    }
}

# Check 2: Subversive Git Commands in Bash / PowerShell
$shellTools = @("Bash", "PowerShell", "Terminal", "ExecuteCommand", "run_command")
if ($toolName -in $shellTools) {
    $cmd = if ($toolInput.command) { $toolInput.command } elseif ($toolInput.CommandLine) { $toolInput.CommandLine } else { "" }
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
}

exit 0
