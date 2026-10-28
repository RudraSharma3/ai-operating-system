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
- **Retrieval Date**: 2026-10-28
- **Verification Status**: **VERIFIED**
- **Verified Headless & Permission Flags**:
  - `-p`, `--print`: Print response without interactive mode / query via SDK, then exit.
  - `--output-format <text|json|stream-json>`: Specify output format for print mode.
  - `--permission-mode <mode>`: Permission mode for session (`default`, `plan`, `auto`, `bypassPermissions`).
  - `--allowedTools <tools>`, `--allowed-tools <tools>`: Narrowly restrict tools that execute without prompting for permission (e.g. `--allowedTools "Bash,Read,Edit"`).
  - `--permission-prompts <host|none>`: Set who answers permission prompts in print mode (`none` denies in unattended runs).
  - `--max-turns <n>`: Limit number of agentic turns in print mode.
  - `--tools <tools>`: Restrict which built-in tools Claude can use.
  - `--dangerously-skip-permissions`: Skip all permission prompts (equivalent to `--permission-mode bypassPermissions`). Documented strictly as a last resort.
- **Unverified / Invalid Flags**:
  - `--non-interactive`: Invalid; does not exist in Claude Code CLI. (Verified non-interactive flag is `-p` / `--print`).
- **Verified Headless Command Strings**:
  - `claude -p`
  - `claude --print`
  - `claude -p --output-format json`
  - `claude --permission-mode auto -p`
  - `claude --allowedTools "Bash,Read,Edit" -p`
  - `claude --dangerously-skip-permissions -p`

> ⚠️ **SECURITY WARNING on `--dangerously-skip-permissions`**:
> The `--dangerously-skip-permissions` flag bypasses all interactive confirmation prompts and allows autonomous file modification and command execution. It must NEVER be used on developer workstations or unisolated repositories. In AI-OS evaluation suites, `--dangerously-skip-permissions` is blocked by default and permitted ONLY inside isolated ephemeral sandboxes created outside the repository tree when `AI_OS_EVAL_SANDBOX=1` is explicitly set. In all documented workflows and CI pipelines, prefer the narrowest permission option: `claude -p`, `claude --permission-mode auto -p`, or `claude --allowedTools "Bash,Read,Edit" -p`.

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

- **Major Version Transition (2.x -> 1.0.0 Downgrade Rationale & Breaking Changes)**:
  - **Pin Reconciliation**: `mcp.json` previously pinned `@modelcontextprotocol/server-filesystem@2.0.1` and `@modelcontextprotocol/server-memory@2.0.0`. These were published on 2026-10-19 and 2026-10-25 (only 3-9 days old as of 2026-10-28), violating the 14-day maturity requirement (cutoff: 2026-10-14). To restore strict supply-chain hygiene, both servers were downgraded to `1.0.0` (published 2026-10-11, 17 days old).
  - **Breaking Changes Between 1.0.0 and 2.x**:
    - **Official Source**: npm package metadata and GitHub release ledger (`https://github.com/modelcontextprotocol/servers`, retrieval date 2026-10-28).
    - **TypeScript SDK v2 Migration**: Version 2.0.0 upgraded internal server dependencies from TS SDK v1 to `@modelcontextprotocol/server` ^2.3.1 (TS SDK v2) and raised the runtime engine floor to `node >= 24`. Version 1.0.0 maintains broader Node.js runtime compatibility (`node >= 18`).
    - **Strict Roots Protocol Capabilities**: Version 2.0.0 enforces client `capabilities.roots` dynamic negotiation. If dynamic roots resolution leaves behind no valid root directories, file operations are rejected with `"Access denied - no allowed directories"`. In contrast, version 1.0.0 relies on directory arguments passed on process startup (`./`), ensuring deterministic headless execution without complex client roots protocol handshakes.
    - **Symlink & Path Traversal Restrictions**: Version 2.0.0 introduced stricter symlink traversal barriers within configured roots.
    - **Diff / Patch Schema**: Version 2.0.0 updated the schema of `edit_file` to support formal dryRun diff outputs.
  - **Python Server Releases (`mcp-server-git`, `mcp-server-fetch`)**:
    - Downgraded from `2026.10.19`/`2026.10.24` to `2026.10.10` (published 2026-10-11) for 14-day maturity compliance. Separate upstream changelog files on PyPI: **NOT VERIFIED** (PyPI metadata does not provide dedicated changelog endpoints for these calver versions beyond release upload timestamps).


