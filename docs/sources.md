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

- **Official Source**: `https://code.claude.com/docs/en/cli-reference` (Markdown: `https://code.claude.com/docs/en/cli-reference.md`), `https://code.claude.com/docs/en/permission-modes` (Markdown: `https://code.claude.com/docs/en/permission-modes.md`)
- **Retrieval Date**: 2026-10-28
- **Verification Status**: **VERIFIED**
- **Documented Permission Modes (`--permission-mode <mode>`)**:
  - `default`: Reads only without asking; prompts for edits/commands. Built-in starting permission mode for `claude -p` and SDK runs (narrowest baseline mode).
  - `manual`: Config alias for `default`.
  - `dontAsk`: File reads inside working directories and pre-approved tools only; anything that would prompt is denied. Narrowest mode for locked-down unattended CI and scripts.
  - `acceptEdits`: Reads, file edits, and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`) run without asking.
  - `plan`: Reads and planning commands without edits before approval.
  - `auto`: Autonomous execution with background safety classifier checks.
  - `bypassPermissions`: Skips all checks (equivalent to `--dangerously-skip-permissions`; isolated containers/VMs only).
- **Verified Headless & Permission Flags**:
  - `-p`, `--print`: Print response without interactive mode / query via SDK, then exit.
  - `--output-format <text|json|stream-json>`: Specify output format for print mode.
  - `--permission-mode <mode>`: Permission mode for session (`default`, `manual`, `dontAsk`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`).
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
  - `claude --permission-mode default -p`
  - `claude --permission-mode dontAsk --allowedTools "Bash,Read,Edit" -p`
  - `claude --allowedTools "Bash,Read,Edit" -p`
  - `claude --dangerously-skip-permissions -p`

> ⚠️ **SECURITY WARNING on `--dangerously-skip-permissions`**:
> The `--dangerously-skip-permissions` flag bypasses all interactive confirmation prompts and allows autonomous file modification and command execution. It must NEVER be used on developer workstations or unisolated repositories. In AI-OS evaluation suites, `--dangerously-skip-permissions` is blocked by default and permitted ONLY inside isolated ephemeral sandboxes created outside the repository tree when `AI_OS_EVAL_SANDBOX=1` is explicitly set. In all documented workflows and CI pipelines, prefer the narrowest permission option: `claude -p`, `claude --permission-mode default -p`, or `claude --allowedTools "Bash,Read,Edit" -p`.

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


---

## 7. Dependabot Version Updates Cooldown Configuration

- **Official Source**: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-dependency-updates#cooldown
- **Retrieval Date**: 2026-10-29
- **Verification Status**: **VERIFIED**
- **Details**:
  - Dependabot natively supports a cooldown block under each package ecosystem entry in .github/dependabot.yml.
  - Configured parameters:
    * default-days: 14: Enforces a mandatory 14-day delay after a new version is released before Dependabot opens a pull request.
    * semver-major-days: 14, semver-minor-days: 14, semver-patch-days: 14: Enforces the 14-day maturity floor across all version upgrade severities.
  - Mitigates supply chain risk and ecosystem instability by ensuring automated dependency proposals only introduce packages that have seasoned in production for at least two weeks.
  - Security updates for known vulnerabilities bypass this cooldown automatically and are opened immediately.

---

## 8. GitHub Actions Major-Version Upgrades & Supply-Chain Review (PRs #3, #4, #5, #6)

- **Retrieval Date**: 2026-10-29
- **Verification Status**: **VERIFIED**

### 1. Release Sources & Documentation Endpoints
- **actions/setup-python**:
  - Releases: `https://github.com/actions/setup-python/releases`
  - v6.0.0: `https://github.com/actions/setup-python/releases/tag/v6.0.0`
  - v7.0.0: `https://github.com/actions/setup-python/releases/tag/v7.0.0`
  - v7.1.0: `https://github.com/actions/setup-python/releases/tag/v7.1.0`
- **astral-sh/setup-uv**:
  - Releases: `https://github.com/astral-sh/setup-uv/releases`
  - v6.0.0: `https://github.com/astral-sh/setup-uv/releases/tag/v6.0.0`
  - v7.0.0: `https://github.com/astral-sh/setup-uv/releases/tag/v7.0.0`
  - v8.0.0: `https://github.com/astral-sh/setup-uv/releases/tag/v8.0.0`
  - v9.0.0: `https://github.com/astral-sh/setup-uv/releases/tag/v9.0.0`
  - v10.0.0: `https://github.com/astral-sh/setup-uv/releases/tag/v10.0.0`
  - v10.3.2: `https://github.com/astral-sh/setup-uv/releases/tag/v10.3.2`
- **actions/checkout**:
  - Releases: `https://github.com/actions/checkout/releases`
  - v5.0.0: `https://github.com/actions/checkout/releases/tag/v5.0.0`
  - v6.0.0: `https://github.com/actions/checkout/releases/tag/v6.0.0`
  - v7.0.0: `https://github.com/actions/checkout/releases/tag/v7.0.0`
  - v7.0.1: `https://github.com/actions/checkout/releases/tag/v7.0.1`
- **actions/setup-node**:
  - Releases: `https://github.com/actions/setup-node/releases`
  - v5.0.0: `https://github.com/actions/setup-node/releases/tag/v5.0.0`
  - v6.0.0: `https://github.com/actions/setup-node/releases/tag/v6.0.0`
  - v7.0.0: `https://github.com/actions/setup-node/releases/tag/v7.0.0`
  - v7.1.0: `https://github.com/actions/setup-node/releases/tag/v7.1.0`

### 2. Breaking Changes, Runner Requirements, and Input Deltas
- **`actions/setup-python` (v5.6.0 -> v7.1.0)**:
  - **Node Runtime**: Migrated from Node 20 to Node 24 runtime (v6.0.0).
  - **Minimum Runner Version**: `actions/runner >= v2.327.1`.
  - **Changed Inputs & Architecture**:
    - v6.0.0: Added `pip-version` input.
    - v6.1.0: Added `pip-install` input.
    - v7.0.0: Removed `pip-install` input (breaking); migrated codebase to ECMAScript Modules (ESM).
    - v7.1.0: Added `mirror` and `mirror-token` inputs for custom Python mirror distribution endpoints.
- **`astral-sh/setup-uv` (v5.4.2 -> v10.3.2)**:
  - **Node Runtime**: Migrated from Node 20 to Node 24 runtime (v7.0.0).
  - **Minimum Runner Version**: Standard hosted runner (`ubuntu-latest`, `macos-latest`, `windows-latest`) or updated self-hosted runner.
  - **Changed Inputs & Breaking Changes**:
    - v6.0.0: Removed deprecated `pyproject-file` and `uv-file` inputs; added explicit `activate-environment` boolean input (defaults to false, replacing automatic root venv creation); added `working-directory` input; changed default `cache-dependency-glob`.
    - v7.0.0: Removed deprecated `server-url` input; changed default binary download source to Astral mirror (`releases.astral.sh`).
    - v8.0.0: Removed deprecated custom `manifest-file` format; stopped publishing mutable major/minor tags (`@v8`, `@v8.0`), enforcing immutable exact tags (`v8.0.0`).
    - v9.0.0: Disabled default cache pruning (`prune-cache: false`), increasing cache hit rates at the expense of higher cache storage consumption.
    - v10.0.0: Default `enable-cache: auto` automatically disables cache for `pull_request_target`, `workflow_run`, and `release` events to prevent cache poisoning attacks; added `version: latest-known`.
    - v10.3.2: Added `python-arch` input for selecting target architecture independently of Python version.
- **`actions/checkout` (v4.2.2 -> v7.0.1)**:
  - **Node Runtime**: Migrated to Node 24 runtime (v5.0.0).
  - **Minimum Runner Version**: `actions/runner >= v2.327.1`.
  - **Changed Inputs & Breaking Changes**:
    - v5.0.0: Node 24 runtime transition.
    - v6.0.0: Persists GitHub credentials to a separate credentials file instead of embedding within repository git config.
    - v7.0.0: Security barrier blocking checking out fork pull requests under `pull_request_target` and `workflow_run` triggers.
    - v7.0.1: Escapes git configuration arguments passed to `git config --unset`.
- **`actions/setup-node` (v4.4.0 -> v7.1.0)**:
  - **Node Runtime**: Migrated to Node 24 runtime (v5.0.0).
  - **Minimum Runner Version**: `actions/runner >= v2.327.1`.
  - **Changed Inputs & Breaking Changes**:
    - v5.0.0: Automatic dependency caching enabled when `packageManager` field is detected in `package.json` (can be disabled via `package-manager-cache: false`).
    - v6.0.0: Restricted automatic caching to npm.
    - v7.0.0: Migrated to ESM; added `cache-primary-key` and `cache-matched-key` outputs; eliminated dummy `NODE_AUTH_TOKEN` environment variable export.
    - v7.1.0: Added support for `mise.toml` version detection and absolute path support for `node-version-file`.

### 3. Pinned Commit SHA Verification via GitHub REST API
All commit SHAs proposed in Dependabot PRs were independently queried and verified against GitHub's commit endpoint (`gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`):
| PR | Action Target | Tag | Pinned Commit SHA in PR | API Commit SHA | Verification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **#3** | `actions/setup-python` | `v7.1.0` | `6d4fd22b20465ccc0f7354476588e8df7c9ca0e0` | `6d4fd22b20465ccc0f7354476588e8df7c9ca0e0` | **MATCH (PASS)** |
| **#4** | `astral-sh/setup-uv` | `v10.3.2` | `07a047e608db84b3d8c06cd9a7c7dcc9c355c18e` | `07a047e608db84b3d8c06cd9a7c7dcc9c355c18e` | **MATCH (PASS)** |
| **#5** | `actions/checkout` | `v7.0.1` | `3d3c42e5aac5ba805825da76410c181273ba90b1` | `3d3c42e5aac5ba805825da76410c181273ba90b1` | **MATCH (PASS)** |
| **#6** | `actions/setup-node` | `v7.1.0` | `949feb2413d6458794dcd2491c4babbbce0c15c1` | `949feb2413d6458794dcd2491c4babbbce0c15c1` | **MATCH (PASS)** |

### 4. Recommendation Table & Supply-Chain Triage
| PR | Dependency | Version Jump | Published Date | 14-Day Cooldown Policy | Triage Decision | Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **#3** | `actions/setup-python` | `5.6.0` -> `7.1.0` | 2026-10-22 | **FAIL** (7 days old < 14 days) | **WAIT / REJECT PR** | Violates 14-day supply-chain maturity cooldown; modifies shared workflow files out of sync. |
| **#4** | `astral-sh/setup-uv` | `5.4.2` -> `10.3.2` | 2026-10-22 | **FAIL** (7 days old < 14 days) | **WAIT / REJECT PR** | Violates 14-day supply-chain maturity cooldown; modifies shared workflow files out of sync. |
| **#5** | `actions/checkout` | `4.2.2` -> `7.0.1` | 2026-07-20 | **PASS** (>3 months old) | **WAIT (HOLD FOR BATCH)** | SHA verified, but individual merge creates merge conflicts in `.github/workflows/registry-check.yml` and breaks un-synchronized doctor/test pins. |
| **#6** | `actions/setup-node` | `4.4.0` -> `7.1.0` | 2026-10-08 | **PASS** (21 days old) | **WAIT (HOLD FOR BATCH)** | SHA verified, but individual merge creates merge conflicts in `.github/workflows/registry-check.yml` and breaks un-synchronized doctor/test pins. |

### 5. Proposed Unified Batch Plan
- **Hold Period**: Maintain cooldown until **2026-11-05** when both `actions/setup-python@v7.1.0` and `astral-sh/setup-uv@v10.3.2` cross the 14-day supply-chain maturity threshold.
- **Single Modernization Branch**: Create a dedicated branch `chore/modernize-actions` targeting all 4 upgrades simultaneously.
- **Coordinated File Synchronization**:
  1. Update `.github/workflows/ci.yml` and `.github/workflows/registry-check.yml` to the verified commit SHAs.
  2. Update `scripts/registry-check.sh` and `scripts/registry-check.ps1` to assert the new pinned SHAs.
  3. Update `tests/test_installer.sh` check-runner test expectations.
- **Automated Verification**: Run full multi-platform matrix CI (Ubuntu, macOS, Windows) and ensure 0 warnings across ShellCheck and PSScriptAnalyzer.
- **Supercede & Close**: Merge the atomic PR and close PRs #3, #4, #5, #6 with reference to the atomic modernization commit.
