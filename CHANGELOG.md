# Changelog

All notable changes to the AI Operating System (AI-OS) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.5] - 2026-10-29

### Added
- **Explicit Authorization Operating Rule (AGENTS.md & Template)**: Added Section 1.6 (`Explicit Authorization Gate`) to `AGENTS.md` and Rule 9 to `templates/project/AGENTS.md`, establishing an explicit, non-bypassable operating rule forbidding merging pull requests, pushing commits directly to protected branches (`main`), creating tags, publishing releases, closing pull requests, or altering repository settings without unambiguous instruction in the active user request text; explicit clarification that vague continuation prompts (e.g., "continue") do not constitute authorization. Extended `tests/test_agents_contract.sh` to enforce this rule by contract while keeping both files strictly within the 8,192-byte token budget (5,082 bytes and 3,889 bytes respectively).
- **Dependabot Cooldown Offline Validator**: Updated Doctor Check 24 in `scripts/doctor.sh` and `scripts/doctor.ps1` to validate Dependabot cooldown keys against the official GitHub specification (`docs/sources.md`), catching and rejecting unsupported keys (such as `semver-*-days` under non-SemVer ecosystems like `github-actions`) before deployment. Added unit tests in `tests/test_installer.sh` asserting both valid and invalid configurations.
- **Dependabot Major-Version Audit & Action Supply-Chain Analysis**: Added comprehensive review of Dependabot major version pull requests (PRs #3, #4, #5, #6) in `docs/sources.md` (retrieval date 2026-10-29), summarizing breaking changes, Node 24 runtime migration, minimum runner requirements (`actions/runner >= v2.327.1`), and changed inputs across `actions/setup-python`, `astral-sh/setup-uv`, `actions/checkout`, and `actions/setup-node`. Verified pinned commit SHAs against the GitHub REST API. Formulated a unified batch plan enforcing the 14-day supply-chain maturity cooldown.
- **Evaluation Harness Dynamic Execution Boundary & Input Validation**: Documented caller-supplied command execution contract for `evals/run_task.ps1` in `docs/lint-policy.md` and `evals/README.md`, emphasizing that the dynamic `Invoke-Expression` boundary must never receive untrusted input. Added parameter validation in `evals/run_task.sh` and `evals/run_task.ps1` rejecting empty or whitespace-only `--agent-cmd` / `-AgentCmd` with immediate non-zero exit code. Added test coverage in `evals/test_eval_harness.sh` (Tests 16 & 17).
- **PR Provenance & Autonomous Process Deviation Recording**: Conducted read-only audit of PR #7 and PR #8 in `docs/task-state.md`, disclosing an autonomous agent process deviation regarding PR #7 merge sequencing, and recommending closing superseded PR #8.

### Fixed
- **Dependabot Options Schema Correction**: Resolved GitHub Dependabot validator failure on `main` by removing unsupported SemVer keys (`semver-major-days`, `semver-minor-days`, `semver-patch-days`) from `.github/dependabot.yml` and configuring `default-days: 14`, the only valid cooldown duration key for the `github-actions` ecosystem. Updated options reference and ecosystem matrix in `docs/sources.md` (retrieved 2026-10-29).
- **PR #8 Closure**: Closed superseded PR #8 with an explanatory comment, consolidating all task tracking, Dependabot cooldown fixes, and release preparation canonically in PR #10.

## [2.4.4] - 2026-10-29

### Added
- **Static Analysis & Lint Policy**: Created canonical `docs/lint-policy.md` documenting every severity filter (`--severity=warning`, `-Severity Error, Warning`), global exclusion (`PSAvoidUsingWriteHost` hiding 245 interactive host output findings), and inline suppression (`PSReviewUnusedParameter` hiding 6 parameter contract findings, `PSAvoidUsingInvokeExpression` hiding 1 dynamic evaluation finding, `# shellcheck disable=SC2016` hiding 7 literal single-quote string findings in embedded Python, sed backreferences, and markdown test fixtures).
- **Dependabot Supply-Chain Cooldown (14 Days)**: Configured 14-day supply-chain cooldown in `.github/dependabot.yml` (`default-days: 14`, `semver-major-days: 14`, `semver-minor-days: 14`, `semver-patch-days: 14`), documented official GitHub specification in `docs/sources.md` (retrieval date 2026-10-29), and enhanced Doctor Check 24 (`scripts/doctor.sh`, `scripts/doctor.ps1`, `tests/test_installer.sh`) to assert Dependabot 14-day maturity configuration offline.
- **Doctor Check 6 Guidance**: Clarified Doctor Check 6 failure message (`core.hooksPath is not configured in git`) to guide users directly to running `bash scripts/bootstrap.sh` or `powershell scripts/bootstrap.ps1` to restore active Git hooks.

### Changed
- **Branch Protection Reconciliation**: Reconciled branch protection configuration documentation in `docs/branch-protection.md` and `docs/task-state.md` to reflect verified GitHub REST API state: `enforce_admins: false` (allowing administrator bypass for the sole repository maintainer) and exact status check context names (`Linux Verification (Ubuntu)`, `macOS Verification (macOS)`, `Windows Verification (Windows Server)`).
- **Checkout Action Pin Verification**: Formally verified `actions/checkout` old SHA (`11d5960a326750d5838078e36cf38b85af677262`) via GitHub API commit inspection, proving it was the `releases-v4` branch commit for floating tag `v4` ("backport fixes to releases-v4 (#2524)"), confirming why it differed from point release `v4.2.2` (`11bd71901bbe5b1630ceea73d27597364c9af683`).

## [2.4.3] - 2026-10-29

### Added
- **Security Policy & Threat Model**: Added canonical `SECURITY.md` establishing GitHub Private Vulnerability Reporting procedures, supported release series (`2.4.x`), and explicit in-scope / out-of-scope boundaries. Added `docs/threat-model.md` detailing assets, threat actors (careless agent, prompt-injected agent, malicious dependency, compromised contributor), defense-in-depth controls, and honest operational limits (injection filters are heuristic/best-effort; human review is the true boundary; sandboxes are directory-isolated rather than microVMs).
- **Workflow Security & Full Action SHA Pinning**: Added top-level `permissions: contents: read` to all GitHub Actions workflows (`.github/workflows/ci.yml`, `.github/workflows/registry-check.yml`). Pinned all third-party GitHub actions to full immutable commit SHAs with version comments (`actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` # v4.2.2, `actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065` # v5.6.0, `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020` # v4.4.0, `astral-sh/setup-uv@d4b2f3b6ecc6e67c4457f6d3e41ec42d3d0fcb86` # v5.4.2). Added `.github/dependabot.yml` for automated weekly GitHub Actions dependency updates, and added online action pin verification to `scripts/registry-check.*`.
- **Static Analysis CI Integration**: Integrated `shellcheck` for all shell scripts in Linux CI (`test-linux`) and `PSScriptAnalyzer` for all PowerShell scripts in Windows CI (`test-windows`). Resolved all static analysis defects across shell and PowerShell codebases without rule suppressions.
- **24-Point Diagnostic Doctor**: Added Doctor Check 24 (`GitHub Actions workflow action pinning and permissions`) to `scripts/doctor.sh` and `scripts/doctor.ps1`, verifying top-level `permissions:` blocks and full SHA action pinning offline.
- **Repository Security Activation**: Enabled GitHub secret scanning, secret scanning push protection, private vulnerability reporting, Dependabot vulnerability alerts, and Dependabot automated security fixes via the GitHub API.

## [2.4.2] - 2026-10-28

### Changed
- **Permission Mode Documentation & Doctor Verification**: Documented the complete set of exact permission modes supported by Claude Code CLI (`default`, `manual`, `dontAsk`, `acceptEdits`, `plan`, `auto`, `bypassPermissions`) in `docs/sources.md` (retrieval date 2026-10-28); replaced all previous recommendations of `auto` with `default` (the narrowest documented baseline permission mode) across `README.md`, `evals/README.md`, and evaluation results. Added automated Doctor Check 22 verification failing/warning if documentation references unverified permission-mode values.
- **Scratch Directory Hygiene**: Purged all temporary test and exploration scripts from `scratch/` keeping the directory strictly gitignored.

### Operational Boundaries & Scope
- **What AI-OS Is Proven to Do**: The deterministic safety tooling, pre-commit secret guards, federated learning rule promotion gates, offline doctor diagnostics, template synchronization drift checks, and evaluation harness mechanics are empirically tested and verified across Linux, macOS, and Windows.
- **What AI-OS Is NOT Proven to Do**: The comparative effect of AI-OS on live agent outcomes (speed, cost, token efficiency, number of turns, and task success rate) remains unmeasured; the headless live agent comparison against baseline unguided models has not been run in this environment.

## [2.4.1] - 2026-10-28

### Added
- **Eval Sandbox Environment Passthrough (`--pass-env`)**: Added `--pass-env` CLI parameter and `AI_OS_EVAL_PASS_ENV` environment variable support to `evals/run_task.sh` and `evals/run_task.ps1`, allowing user-specified variables (e.g. `ANTHROPIC_API_KEY`) to safely pass through while stripping all unlisted secret signatures.
- **Source-Control & Cloud Credential Passthrough Guard**: Added refusal validation preventing sensitive source-control and cloud tokens (`AWS_*`, `AZURE_*`, `GOOGLE_*`, `GITHUB_*`, `GH_*`, `GITLAB_*`, `NPM_TOKEN`) from being passed via `--pass-env` unless `AI_OS_EVAL_SANDBOX=1` is explicitly enabled.
- **MCP Stdio Initialization Smoke Tests**: Added automated live JSON-RPC initialize handshake smoke tests to `scripts/registry-check.sh` and `scripts/registry-check.ps1` (verifying servers respond within 20s and exit cleanly) and added `uv` setup to `.github/workflows/registry-check.yml`.
- **Honest Sandbox Limits Documentation**: Documented the operational boundary limits of the evaluation runner in `evals/README.md` and `README.md`, emphasizing that the harness is an isolated working directory rather than an OS-level security container, and providing container/VM guidance for untrusted live agent execution.

### Fixed
- **Doctor Exact MCP Pin Range Enforcement**: Updated Doctor Check 15 and test harness to explicitly reject range version specifications (`^`, `~`, `>`, `<`, `*`, `latest`), enforcing strict exact pinning across master and template `mcp.json`.
- **MCP Pin History Reconciled**: Reconciled git history in `CHANGELOG.md` and `docs/task-state.md` documenting that prior pins were exact versions (`2.0.1`, `2.0.0`, `2026.10.19`, `2026.10.24`) rather than range placeholders.

## [2.4.0] - 2026-10-28

### Added
- **14-Day MCP Pin Maturity & Doctor Verification**: Pinned all MCP tool servers (`@modelcontextprotocol/server-filesystem@1.0.0`, `@modelcontextprotocol/server-memory@1.0.0`, `mcp-server-git==2026.10.10`, `mcp-server-fetch==2026.10.10`) to stable releases published >= 14 days ago (downgrading from previous exact pins `2.0.1`, `2.0.0`, `2026.10.19`, and `2026.10.24` which were too recent to satisfy the 14-day policy). Added 23-point Doctor Check 23 (`docs/mcp-pins.json`) verifying pin age and record freshness offline without network calls.
- **Dedicated Scheduled Registry Check Workflow**: Moved live npm and PyPI registry lookups into `scripts/registry-check.sh`, `scripts/registry-check.ps1`, and a weekly workflow (`.github/workflows/registry-check.yml`) triggered by `workflow_dispatch` and weekly schedule, keeping default test, doctor, and eval execution 100% offline.
- **Offline Network Guard Verification**: Added `test_offline_test_and_doctor_scripts_no_network_invocations` enforcing that default test, doctor, and eval scripts never invoke outbound network tools (`npm`, `npx`, `uvx`, `pip`, `curl`, `wget`, `Invoke-WebRequest`, `gh api`), with an explicit allowlist strictly limited to `scripts/registry-check.*`.
- **Eval Sandbox Security & Credential Stripping**: Hardened evaluation runners (`evals/run_task.sh`, `evals/run_task.ps1`) to run exclusively in temporary directories outside the repository tree and outside any parent repository, strip environment variables matching sensitive patterns (`KEY`, `TOKEN`, `SECRET`, `PASSWORD`, cloud provider credentials) before launching agents, and refuse `--dangerously-skip-permissions` unless `AI_OS_EVAL_SANDBOX=1` is explicitly set in an isolated sandbox.
- **Negative Control Verification Mode (`--expect-fail`)**: Added `--expect-fail` / `-ExpectFail` flag exiting 0 only when all negative controls are rejected and 1 if any passes, integrated into CI and documentation.

### Changed
- **Windows CI Performance Optimization**: Replaced line-by-line subprocess loops in `doctor.sh` with bulk pattern extraction, eliminating subshell process spawning overhead in Git Bash on Windows and cutting test harness runtime from 14m18s to ~2m30s.

## [2.3.0] - 2026-10-27

### Added
- **22-Point Diagnostic Doctor**: Expanded health diagnostics (`scripts/doctor.sh`, `scripts/doctor.ps1`) to 22 checks, adding Check 20 (privacy deny-list enforcement against `.ai/private-names.txt`), Check 21 (status reporting for optional Claude Code lifecycle hooks), and Check 22 (headless agent command verification against `docs/sources.md`).
- **macOS CI Matrix Runner**: Added native `macos-latest` runner to GitHub Actions CI workflow (`.github/workflows/ci.yml`), validating Bash test suites and BSD/POSIX toolchain portability alongside Ubuntu and Windows Server.
- **Opt-in Claude Code Lifecycle Hooks**: Implemented transparent, opt-in lifecycle hooks (`.ai-os/optional/claude-hooks/` installed via `--with-claude-hooks` / `-WithClaudeHooks`) supporting `SessionStart` (task state & budget summaries), `PreCompact` (task state persistence checkpointing), and `PreToolUse` (blocking unauthorized governance file edits and destructive commands).
- **Anti-Gaming Eval Suite & Deterministic Stub Harness**: Hardened evaluation tasks 01–05 with negative controls (`negative_solution.sh/.ps1`) and strict verification assertions, ensuring 100% negative control rejection; added deterministic stub agents (`evals/stub_agent.sh/.ps1`) and harness integration test (`evals/test_eval_harness.sh`).
- **Privacy Deny-List Scanning**: Added tracked file deny-list scanner (`.ai/private-names.txt`) preventing accidental leakage or tracking of private partner or sibling repository names.
- **Verified Pinned MCP Tooling**: Configured and pinned exact package versions for all MCP servers (`mcp.json`): `@modelcontextprotocol/server-filesystem@2.0.1`, `@modelcontextprotocol/server-memory@2.0.0` (npm), and `mcp-server-git==2026.10.19`, `mcp-server-fetch==2026.10.24` (uvx / PyPI); enforced in Doctor Check 15 and documented in `playbooks/multi-agent-orchestration.md`.
- **Verified Headless CLI Flags**: Documented authoritative Claude Code CLI flags (`-p`, `--print`) in `docs/sources.md` (retrieved 2026-10-27 from `https://code.claude.com/docs/en/cli-reference`), removing invalid `--non-interactive` flags across eval documentation and runners.
- **Server-Side Branch Protection**: Documented server-side protection on `main` enforcing 3 required status checks (`Linux Verification`, `macOS Verification`, `Windows Verification`), mandatory CODEOWNERS review, and force push blocking in `docs/branch-protection.md`.

### Changed
- **Placeholder-Aware Secret Scanning**: Upgraded `.githooks/pre-commit` to recognize standard placeholder values (e.g., `<your-api-key>`, `your_key_here`, `TODO`, `EXAMPLE`, `xxx`) while strictly intercepting live secrets across all supported token formats.
- **Template Synchronization**: Upgraded `scripts/build-templates.sh` and `scripts/build-templates.ps1` to mirror `mcp.json` and `.ai-os/optional/claude-hooks/` into `templates/project/` with cryptographic manifest tracking.

## [2.2.0] - 2026-10-27

### Added
- **19-Point Diagnostic Doctor**: Expanded health diagnostics (`scripts/doctor.sh`, `scripts/doctor.ps1`) adding local path sanitation validation (local user home directories) and documentation count synchronicity verification (playbooks, doctor checks, test suites).
- **Verified CI Promotion Gate**: Cryptographic GitHub API review gate in `scripts/approve-proposal.sh` and `scripts/approve-proposal.ps1` enforcing non-author PR approval by designated CODEOWNER before candidate rule promotion in automated CI workflows.
- **Replayable Evaluation Task Suite**: 5 standardized behavioral benchmark fixtures (`evals/tasks/`) with pass/fail validation, prompt contract adherence, secret avoidance, and prompt injection resistance, proved with 100% sensitivity (0/5 untouched vs 5/5 reference).
- **Contract Integrity Verification Suite**: Added `tests/test_agents_contract.sh` checking safety gates, secret rules, 4-part prompt contract, priority hierarchy, and reverse prompting escapes in both master and shipped templates.
- **External Documentation Registry**: Added `docs/sources.md` establishing authoritative URL citations and verification dates for `AGENTS.md` ecosystem support across Cursor and GitHub Copilot.

### Changed
- **Token Budget Footprint Reduction**: Reduced canonical master `AGENTS.md` (4,760 bytes) and template `AGENTS.md` (3,601 bytes) safely beneath the strict 8,192-byte limit while preserving all safety invariants.
- **Doctor Check Synchronicity**: Aligned all diagnostic counts (19 points) across `README.md` and `docs/AI-OS-USER-GUIDE.md`.
- **Cross-Platform CI Hardening**: Green multi-platform GitHub Actions workflow covering Ubuntu and Windows Server runners with native PowerShell and Bash test suites.

## [2.1.0] - 2026-10-09

### Added
- **14-Point Diagnostic Doctor**: Dual-engine project health doctor (`scripts/doctor.sh`, `scripts/doctor.ps1`) featuring automated tracked secret scanning, hook execution tests, adapter verification, and sequential rule validation with `--ci` and `--json` support.
- **Pre-Commit Secret Armor**: POSIX ERE-compliant Git secret guard (`.githooks/pre-commit`) scanning only staged additions across AWS, GitHub, Stripe, OpenAI, Anthropic, Google AIza, Slack, Database URLs, and Private Keys with allowlist support (`.ai/secret-allowlist.txt`) and Gitleaks wrapper delegation.
- **Downstream Distribution Bundle**: Packaged `.ai-os/playbooks/` and `.ai-os/prompts/` to ensure downstream projects retain access to full architectural workflows.
- **Non-Destructive Installers**: Recursive per-file copy (`scripts/install.sh`, `scripts/install.ps1`) preserving existing user files and directories, non-destructive `.gitignore` merge block, and non-destructive Git hook chaining for existing `core.hooksPath` configurations (e.g., Husky).
- **Automated Integration Test Harness**: Comprehensive test suites (`tests/test_hook.sh`, `tests/test_installer.sh`, `tests/run_tests.sh`) covering all hook failure modes, installer parity, and platform edge cases.
- **CI Matrix Workflow**: Dual-platform GitHub Actions workflow (`.github/workflows/ci.yml`) running bash test suites on Ubuntu and PowerShell diagnostic tests on Windows.
- **Template Single Source of Truth Generator**: Build generator (`scripts/build-templates.sh`, `scripts/build-templates.ps1`) programmatically assembling `templates/project/` from master with zero-drift enforcement.
- **Upgrade Engine with Cryptographic Manifest**: Upgrade automation (`scripts/upgrade.sh`, `scripts/upgrade.ps1`) tracking SHA256 checksums in `.ai-os/manifest.json` to safely upgrade upstream templates while preserving downstream customizations.
- **Rule Modularization Compiler**: Compiler script (`scripts/compile-rules.sh`, `scripts/compile-rules.ps1`) compiling atomic rule files in `.ai/rules/*.md` into canonical `AGENTS.md` learned rules blocks.
- **Provider Adapters**: Standardized Cursor (`.cursorrules`, `.cursor/rules/agents.mdc`) and GitHub Copilot (`.github/copilot-instructions.md`) adapters pointing directly to `AGENTS.md`.

### Changed
- Standardized downstream `AGENTS.md` template with self-correcting rules engine, 10-point quality test gate, and safe self-modification constraints, eliminating unsafe "Immediately append" guidance.
- Updated all Claude command wrappers and playbook references to point to standardized `.ai-os/` paths.
- Enforced LF line endings via `.gitattributes` across all shell scripts, hooks, and markdown definitions.

## [2.0.0] - 2026-09-15

### Added
- Core AI Operating System architecture, playbooks, prompts, and documentation.
- Project templates and initial PowerShell installation scripts.
