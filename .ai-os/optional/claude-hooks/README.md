# Claude Code Lifecycle Hooks (Opt-In)

This directory contains optional lifecycle hooks for Anthropic's **Claude Code** CLI agent (`https://code.claude.com/docs/en/hooks`).

## Security Notice
- **Execution Permissions**: Hook commands run automatically with the full permissions of the active user in the shell environment.
- **Reviewability**: All AI-OS hooks are transparent, reviewable plain scripts (bash and PowerShell). They never download or execute remote code.
- **Input Isolation**: Hook scripts parse structured JSON from `stdin` to read file paths or command strings; they **never evaluate or execute arbitrary content taken from tool inputs**.
- **Opt-In Policy**: These hooks are **not installed by default**. They are activated only when explicitly requested via the installer flag `--with-claude-hooks` (Bash) or `-WithClaudeHooks` (PowerShell).

## Hooks Overview
1. **`SessionStart` (`session-start.sh` / `.ps1`)**:
   - Fires at session begin or resume.
   - Prints current task summary from `docs/task-state.md` and active token budget metrics.
2. **`PreCompact` (`pre-compact.sh` / `.ps1`)**:
   - Fires immediately before context window compaction.
   - Appends an automatic checkpoint timestamp into `docs/task-state.md` to prevent agent state loss across compaction.
3. **`PreToolUse` (`pre-tool-use.sh` / `.ps1`)**:
   - Fires before tool calls (`Write`, `Edit`, `Bash`, `PowerShell`).
   - Blocks unauthorized direct edits to governance files (`AGENTS.md`, `.ai/rules/`, `.githooks/`, `scripts/`) unless `AI_OS_ALLOW_GOVERNANCE_EDIT=1` is explicitly set in the environment.
   - Blocks destructive / subversive git operations (`git commit --no-verify`, `git push --force`).

## Installation
To install Claude Code hooks into your project:
```bash
# Bash
bash scripts/install.sh --with-claude-hooks .

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -WithClaudeHooks -Target .
```
This copies the hook scripts to `.claude/hooks/` and provisions `.claude/settings.json`.
