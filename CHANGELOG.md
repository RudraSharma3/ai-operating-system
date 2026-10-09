# Changelog

All notable changes to the AI Operating System (AI-OS) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
