# External Documentation Sources & Verifications

This document records the official documentation URLs, retrieval dates, and verification statuses for external tool integrations and specifications.

---

## 1. AGENTS.md Multi-Tool Specification & Ecosystem Standard

- **Canonical Specification**: `https://agents.md`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Summary**: `AGENTS.md` is an open standard format defining repository context, build/test commands, and architectural constraints for autonomous AI coding agents across developer environments.

---

## 2. Cursor IDE AGENTS.md & Rules Integration

- **Official Source**: `https://cursor.com` and `https://docs.cursor.com/context/rules-for-ai`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Details**:
  - Cursor natively detects and parses `AGENTS.md` at the project root for Agent mode and background execution.
  - Complemented by scoped rules located in `.cursor/rules/*.mdc`.
  - In AI-OS, `.cursor/rules/agents.mdc` provides the direct pointer ensuring Cursor loads `AGENTS.md` as the single source of truth.

---

## 3. GitHub Copilot AGENTS.md & Custom Instructions

- **Official Source**: `https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Details**:
  - GitHub Copilot supports repository-level instructions defined in `AGENTS.md` as well as `.github/copilot-instructions.md`.
  - In AI-OS, `.github/copilot-instructions.md` acts as an adapter referencing canonical `AGENTS.md` to prevent policy drift.

---

## 4. Claude Code Lifecycle Hooks Specification

- **Official Source**: `https://code.claude.com/docs/en/hooks` (Markdown version: `https://code.claude.com/docs/en/hooks.md`)
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Lifecycle Events Utilized**:
  - `SessionStart`: Fires when a session begins or resumes. Passes session context on stdin. Used in AI-OS to print task state summary and token budget metrics.
  - `PreCompact`: Fires before context window compaction. Passes conversation metrics on stdin. Used in AI-OS to record a state checkpoint into `docs/task-state.md`.
  - `PreToolUse`: Fires before tool call execution (Write, Edit, Bash, PowerShell). Input arrives on stdin containing `{"tool_name": "...", "tool_input": { ... }}`. Hook outputs JSON with `permissionDecision: "allow" | "deny"` and `permissionDecisionReason: "..."` to enforce governance boundaries.
  - `Stop`: Fires when Claude finishes responding on a turn.
- **Configuration Schema (`.claude/settings.json`)**:
  ```json
  {
    "hooks": {
      "SessionStart": [
        {
          "matcher": "*",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.ai-os/optional/claude-hooks/session-start.sh"
            }
          ]
        }
      ],
      "PreCompact": [
        {
          "matcher": "*",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.ai-os/optional/claude-hooks/pre-compact.sh"
            }
          ]
        }
      ],
      "PreToolUse": [
        {
          "matcher": "Write|Edit|Bash|PowerShell",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.ai-os/optional/claude-hooks/pre-tool-use.sh"
            }
          ]
        }
      ]
    }
  }
  ```
- **Security Notice**:
  Hook commands run with the permissions of the local user. All AI-OS Claude Code hooks are provided as transparent, reviewable plain scripts in `.ai-os/optional/claude-hooks/` and are strictly opt-in via `--with-claude-hooks` / `-WithClaudeHooks`. Hook scripts never evaluate or execute arbitrary content taken from tool inputs.

---

## 5. Claude Code CLI Headless & Scripting Flags

- **Official Source**: `https://code.claude.com/docs/en/cli-reference` (Markdown: `https://code.claude.com/docs/en/cli-reference.md`)
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Verified Headless Flags**:
  - `-p`, `--print`: Print response without interactive mode / query via SDK, then exit.
  - `--output-format <text|json|stream-json>`: Specify output format for print mode.
  - `--allowedTools <tools>`, `--allowed-tools <tools>`: Tools that execute without prompting for permission.
  - `--permission-mode <mode>`: Permission mode for session (`default`, `plan`, `auto`, `bypassPermissions`).
  - `--dangerously-skip-permissions`: Skip permission prompts (equivalent to `--permission-mode bypassPermissions`).
  - `--permission-prompts <host|none>`: Set who answers permission prompts in print mode (`none` denies in unattended runs).
  - `--max-turns <n>`: Limit number of agentic turns in print mode.
  - `--tools <tools>`: Restrict which built-in tools Claude can use.
- **Unverified / Invalid Flags**:
  - `--non-interactive`: Invalid; does not exist in Claude Code CLI. (Verified non-interactive flag is `-p` / `--print`).
- **Verified Headless Command Strings**:
  - `claude -p`
  - `claude --print`
  - `claude -p --output-format json`
  - `claude --dangerously-skip-permissions -p`

---

## 6. Model Context Protocol (MCP) Server Registries & Pin Maturity

- **Canonical Specification**: `https://modelcontextprotocol.io`
- **Retrieval Date**: 2026-10-28
- **Verification Status**: **VERIFIED**
- **14-Day Maturity Policy**:
  All MCP servers declared in `mcp.json` must be pinned to immutable, exact package versions that were published at least 14 days prior to pinning. This mitigates supply-chain risks and ensures upstream releases are stable.
- **Tracked MCP Packages & Upstream Sources**:
  - `@modelcontextprotocol/server-filesystem`: npm registry (`https://registry.npmjs.org/@modelcontextprotocol/server-filesystem`). Pinned to `1.0.0` (published `2026-10-11T02:44:10Z`, 17 days old).
  - `@modelcontextprotocol/server-memory`: npm registry (`https://registry.npmjs.org/@modelcontextprotocol/server-memory`). Pinned to `1.0.0` (published `2026-10-11T02:42:27Z`, 17 days old).
  - `mcp-server-git`: PyPI repository (`https://pypi.org/pypi/mcp-server-git/json`). Pinned to `2026.10.10` (published `2026-10-11T02:41:46Z`, 17 days old).
  - `mcp-server-fetch`: PyPI repository (`https://pypi.org/pypi/mcp-server-fetch/json`). Pinned to `2026.10.10` (published `2026-10-11T02:41:50Z`, 17 days old).


