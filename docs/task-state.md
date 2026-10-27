# AI Operating System Active Task State

This document tracks the current development milestones and task state for the master AI Operating System repository.

---

## Current Epic: Production-Grade AI-OS Hardening & Upgrade

### Operating Rules
- Verify before claiming (every fix must have a runnable command & verified output).
- No unmeasured marketing numbers in documentation.
- Small commits with conventional-commit messages.
- Generated template synchronization from master.
- Milestone checkpoints written to `docs/task-state.md` before/after every phase.

---

## Phase 0 Plan: Safety Net & Test Harness
1. Create `tests/` directory with automated bash test harness (`tests/test-runner.sh`, `tests/test-hook.sh`, `tests/test-installer.sh`) and `tests/fixtures/`.
2. Write test cases that reproduce all aspects of **F2 (Secret Hook flaws)**:
   - Baseline blocked cases (plain `sk-`, root `.env`, private keys).
   - Expected-to-fail / NOT blocked cases (AWS `AKIA...`, GitHub `ghp_...`, Stripe `sk_live_...`, Google `AIza...`, Anthropic `sk-ant-...`, OpenAI `sk-proj-...`, DB connection strings with credentials, nested `apps/web/.env`, secrets inside `.githooks/`).
   - False positives that must pass (.env.example, git commit that only deletes a leaked key).
3. Write test cases that reproduce all aspects of **F3 (Installer flaws)**:
   - Preserves existing `core.hooksPath` (e.g. `.husky`) via chaining instead of silently overwriting.
   - Non-destructive `.gitignore` merge preserving existing rules and appending AI-OS rules.
   - Non-destructive per-file copy into an existing `docs/` folder (testing both `install.sh` and `install.ps1`).
4. Execute test suite against current codebase to capture and document genuine failure modes.
5. Create `.gitattributes` enforcing LF endings for shell scripts and hooks, and mark all shell scripts/hooks as executable in Git index (`+x`).

---

## Phase Handoffs & Log

### Phase 0 Handoff
- **What Changed**:
  - Created `tests/` directory with test harness (`test_helpers.sh`, `test_hook.sh`, `test_installer.sh`, `run_tests.sh`).
  - Added test reproduction suites for F2 (14 hook test cases) and F3 (3 installer test cases).
  - Added `.gitattributes` (enforcing LF line endings on all `*.sh` and `.githooks/*` files) in root and `templates/project/`.
  - Set executable mode `100755` in Git index on all shell scripts and hooks (`scripts/*.sh`, `tests/*.sh`, `templates/project/.githooks/pre-commit`).
- **What Was Verified**:
  - `tests/test_hook.sh`: Successfully reproduced 11 failures (AWS AKIA, GitHub ghp_, Stripe sk_live_, Google AIza, Anthropic sk-ant-, OpenAI sk-proj-, Database credentials, nested apps/web/.env, secrets in .githooks/, false-positive on .env.example, false-positive on deleting leaked key).
  - `tests/test_installer.sh`: Successfully reproduced 3 installer failures (overwriting core.hooksPath from .husky, failing to merge .gitignore, install.ps1 skipping template docs when docs/ exists).
  - `git ls-files --stage`: Verified mode `100755` on all 8 shell scripts/hooks.
- **Known Risks**:
  - Hook currently fails to protect against modern API tokens until Phase 1 fixes are implemented.
  - Existing installers still have platform divergence until Phase 2.

---

### Phase 1 Handoff
- **What Changed**:
  - Created `.ai/secret-patterns.txt` and `.ai/secret-allowlist.txt` in root and `templates/project/.ai/`.
  - Rewrote `templates/project/.githooks/pre-commit` with:
    - `gitleaks` wrapper detection.
    - Added-lines-only diff scanning (`git diff --cached -U0 | grep -E '^\+[^+]'`).
    - Pattern matching against POSIX ERE-compliant signatures (OpenAI `sk-` and `sk-proj-`, Anthropic `sk-ant-`, AWS `AKIA`/`ASIA`, GitHub `ghp_`/`gho_`/`github_pat_`, Stripe `sk_live_`, Google `AIza`, Slack, Private Keys, DB URLs with credentials, JWTs).
    - Allowlist checking via `.ai/secret-allowlist.txt`.
    - Deep nested `.env` scanner with allowlist for `.env.example`, `.env.sample`, `.env.template`, `.env.dist`.
    - Sanitized remediation messages (never echoes the raw secret).
    - Removed misleading task state claims from hook header.
  - Mirrored hook to `.githooks/pre-commit` and maintained executable bit `100755`.
- **What Was Verified**:
  - `tests/test_hook.sh`: **14/14 tests PASSED** (0 failed).
    - Blocked: Plain OpenAI sk-, root .env, RSA private keys, AWS AKIA, GitHub ghp_, Stripe sk_live_, Google AIza, Anthropic sk-ant-, OpenAI sk-proj-, Database URLs, nested apps/web/.env, secrets in .githooks/.
    - Allowed: .env.example/.sample/.template, and diffs only deleting a leaked token.
- **Known Risks**:
  - Installer scripts (`install.sh` and `install.ps1`) must now be updated in Phase 2 to ensure downstream projects receive all playbooks/prompts under `.ai-os/`, properly chain Git hooks, and merge `.gitignore`.

---

### Phase 2 Handoff
- **What Changed**:
  - Packaged downstream distribution: `playbooks/` and `prompts/` placed under `templates/project/.ai-os/playbooks/` and `templates/project/.ai-os/prompts/`.
  - Updated command references across `.claude/commands/`, `templates/project/.claude/commands/`, and `playbooks/codebase-analysis.md`.
  - Upgraded `scripts/install.sh` and `scripts/install.ps1`:
    - Full recursive per-file no-clobber copy preserving existing user files and existing `docs/` directories.
    - Non-destructive `.gitignore` merge using `# --- AI-OS START ---` block.
    - Safe Git hook chaining: detects existing `core.hooksPath` (e.g., `.husky`) and chains execution instead of overwriting.
    - Sets execution permissions (`chmod +x`).
  - Added `scripts/bootstrap.sh` and `scripts/bootstrap.ps1` for lightweight team clone setup.
  - Rewrote `scripts/doctor.sh` and `scripts/doctor.ps1`:
    - 14-point diagnostic engine with parity across Bash and PowerShell.
    - Full tracked file secret scanning and `.env` tracker detection.
    - `--ci` flag (fails fast with non-zero exit code) and `--json` flag.
    - Dynamic ARMOR status (`[ARMED]` vs `[UNARMED]`).
  - Added CI matrix workflow `.github/workflows/ci.yml` running on `ubuntu-latest` and `windows-latest`.
  - Expanded `tests/test_installer.sh` with 7 comprehensive installer tests covering bash and powershell installers.
- **What Was Verified**:
  - `tests/run_tests.sh`: **26/26 tests PASSED** (19 hook tests + 7 installer tests).
  - `scripts/doctor.ps1 --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/doctor.sh --ci`: **14/14 checks PASSED**, exit code 0.
- **Known Risks**:
  - `templates/project/` is currently manually synchronized with master until Phase 3 build generator (`scripts/build-templates.*`) is created.

---

---

### Phase 3 Handoff
- **What Changed**:
  - **Versioning & Licensing**: Added canonical `VERSION` (2.1.0), `CHANGELOG.md` (Keep a Changelog format), and MIT `LICENSE` (Copyright Rudra Sharma).
  - **Provider Adapters**: Standardized Cursor (`.cursorrules`, `.cursor/rules/agents.mdc`) and GitHub Copilot (`.github/copilot-instructions.md`) adapters pointing to `AGENTS.md` in both master and template repositories. Updated doctor check 2 to verify all adapters.
  - **Single Source of Truth Generator**: Created `scripts/build-templates.sh` and `scripts/build-templates.ps1` with deterministic `--check` mode verifying zero drift between master files and `templates/project/`.
  - **Cryptographic Manifest & Upgrade Engine**:
    - Created `.ai-os/manifest.json` indexing 48 upstream files with cross-platform normalized SHA256 checksums.
    - Implemented `scripts/upgrade.sh` and `scripts/upgrade.ps1` supporting three-way checksum comparison: safely upgrades untouched upstream files while preserving local user customizations (and generating `.ai-os-update` candidates).
  - **Rule Modularization Compiler**:
    - Modularized canonical rules under `.ai/rules/0001-read-existing-files.md`, `0002-never-write-secrets.md`, `0003-run-verification-checks.md`.
    - Created `scripts/compile-rules.sh` and `scripts/compile-rules.ps1` with `--check` mode to synchronize modular rule files into canonical `AGENTS.md` learned rules blocks.
  - **Template `AGENTS.md` Hardening**: Completely overhauled downstream `templates/project/AGENTS.md` to remove unsafe "Immediately append" instructions and install the production self-correcting rules engine, 10-point quality test gate, and safe self-modification constraints.
  - **Automated Verification**: Expanded `tests/test_installer.sh` with 3 new automated tests: upgrader customization preservation, template drift verification, and rule compiler synchronization. Updated CI matrix workflow.
- **What Was Verified**:
  - `tests/run_tests.sh`: **29/29 tests PASSED** (19 hook tests + 10 installer/upgrader/drift tests).
  - `scripts/doctor.ps1 --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/doctor.sh --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/build-templates.sh --check`: **PASS** (Zero drift detected).
  - `scripts/build-templates.ps1 -Check`: **PASS** (Zero drift detected).
  - `scripts/compile-rules.sh --check`: **PASS** (Zero drift detected).
  - `scripts/compile-rules.ps1 -Check`: **PASS** (Zero drift detected).
- **Known Risks**:
  - Syncing rules from downstream projects back to master still relies on prototype script (`scripts/sync-rules.ps1`) until Phase 4 federated PR proposal workflow is implemented.

---

---

### Phase 4 Handoff
- **What Changed**:
  - **Federated Proposal Workflow**:
    - Replaced prototype `scripts/sync-rules.ps1` with production cross-platform proposal generators (`scripts/sync-rules.sh` and `scripts/sync-rules.ps1`).
    - Downstream rule synchronization now creates structured, auditable proposals under `proposals/` (`YYYYMMDD-HHMMSS-slug.md`) instead of performing silent direct writes to master.
  - **10-Point Mechanical Quality Gate**:
    - Implemented automated gate verifying: category validity, rationale separator, actionable statement length, general scope (no local file paths), non-conflicting check against active master rules, safe instruction source, zero secret patterns (checked against master regex registry), durability, canonical syntax, and cross-stack reusability.
  - **Proposal Promotion Engine**:
    - Created `scripts/approve-proposal.sh` and `scripts/approve-proposal.ps1` to promote accepted proposals from `proposals/` into `.ai/rules/NNNN-slug.md`, automatically recompile `AGENTS.md` via `compile-rules`, and synchronize templates via `build-templates`.
  - **Automated Test Coverage**:
    - Created dedicated test suite `tests/test_sync.sh` covering secret rejection, missing rationale rejection, local path rejection, duplicate skipping, and proposal generation.
    - Updated master test runner `tests/run_tests.sh`.
- **What Was Verified**:
  - `tests/run_tests.sh`: **34/34 tests PASSED** (19 hook tests + 10 installer/upgrader/drift tests + 5 sync gate tests).
  - `tests/test_sync.sh`: **5/5 tests PASSED**.
  - `scripts/doctor.ps1 --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/doctor.sh --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/build-templates.ps1 -Check`: **PASS** (Zero drift detected).
- **Known Risks**:
  - `mcp.json` and model routing configuration still contain prototype/placeholder items until Phase 5 fixes.

---

---

### Phase 5 Handoff
- **What Changed**:
  - **Clean & Verified MCP Architecture (`mcp.json`)**:
    - Removed non-standard placeholder packages (`@google/gemini-mcp-server`) and broken daemons (`ollama serve`) from `mcp.json` and `templates/project/mcp.json`.
    - Standardized on verified, official `@modelcontextprotocol` servers (`server-filesystem`, `server-git`, `server-fetch`).
  - **Honest Model Routing Matrix (`.ai/routing.md`)**:
    - Created canonical `.ai/routing.md` (in master and `templates/project/.ai/`) specifying complexity tiers (Tier 1 Solo Model, Tier 2 Feature Pair, Tier 3 Architecture Consensus).
    - Codified anti-overkill rules forbidding multi-agent swarms for simple tasks or using LLM votes for deterministic facts.
  - **Deterministic Consensus (`playbooks/stochastic-consensus.md`)**:
    - Replaced subjective LLM vote counting with deterministic engineering verification (compilation, type checks, lint checks, test pass rates, benchmark budgets) before recording ADRs.
  - **Headless Escape Hatch (`playbooks/prompt-refinement.md`)**:
    - Added Section 5 providing explicit non-interactive / CI / autonomous escape hatches: auto-selects documented defaults without hanging in chat, records them under `### ⛓️ CONSTRAINTS` with `[HEADLESS AUTO-RESOLVED DEFAULT]`, and proceeds surgically.
  - **Template Synchronization**:
    - Rebuilt `templates/project/` using `build-templates` (manifest updated with 49 tracked files, zero drift verified).
- **What Was Verified**:
  - `tests/run_tests.sh`: **34/34 tests PASSED** (19 hook tests + 10 installer/upgrader/drift tests + 5 sync gate tests).
  - `scripts/doctor.ps1 --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/doctor.sh --ci`: **14/14 checks PASSED**, exit code 0.
  - `scripts/build-templates.ps1 -Check`: **PASS** (Zero drift detected).
- **Known Risks**:
  - Documentation still contains legacy speculative numbers (e.g. unbenchmarked token savings) until Phase 6 metric audit.

---

---

### Phase 6 Handoff
- **What Changed**:
  - **Empirical Measurement Scripts**:
    - Implemented cross-platform footprint tools `scripts/token-report.sh` and `scripts/token-report.ps1` measuring characters, lines, words, bytes, and estimated tokens across 29 core files.
    - Verified that canonical `AGENTS.md` (10,495 bytes / ~2,624 est. tokens) is strictly within the 15,360 byte token budget.
  - **Metric Audit Across All Docs**:
    - Audited `README.md`, `playbooks/token-optimization.md`, and `docs/AI-OS-COMPLETE-SPECIFICATION.md`.
    - Removed unbenchmarked marketing claims (`95%`, `5x`, `70-80%`, `up to 90%`) and clearly labeled provider caching mechanisms as `(design target, unbenchmarked)`.
  - **Reproducible Evaluation Suite (`evals/`)**:
    - Created `evals/README.md`, `evals/run_evals.sh`, and `evals/run_evals.ps1` establishing benchmark tests for:
      1. Token Budget Compliance.
      2. Secret Defense Multi-Vendor Accuracy.
      3. Diagnostic Doctor Execution Latency (<4.0s).
      4. Prompt Contract 4-Part Structural Integrity.
      5. Template Zero Drift Verification.
  - **Template Synchronization**:
    - Rebuilt `templates/project` via `build-templates` to synchronize cleaned docs.
- **What Was Verified**:
  - `evals/run_evals.sh`: **5/5 benchmarks PASSED**.
  - `evals/run_evals.ps1`: **4/4 benchmarks PASSED**.
  - `scripts/token-report.sh`: **PASS** (`AGENTS.md`: 10,495 bytes / limit 15,360 bytes).
  - `scripts/token-report.ps1`: **PASS** (`AGENTS.md`: 10,495 bytes / limit 15,360 bytes).
  - `tests/run_tests.sh`: **34/34 tests PASSED**.
- **Known Risks**:
  - Registry files (`registry/projects.md`) may still contain local paths from the initial prototype environment.

---

## Phase 7 & 8 Plan: Harness Enforcement & Final Production Cleanup
1. **Sanitize Machine-Specific Paths**:
   - Audit `registry/projects.md` and repository markdown files for hardcoded local user paths (e.g. `C:\Users\rudra\...`, `/Users/rudra/...`) and replace with generic portable placeholders (`<project-root>`, `./projects/`).
2. **Comprehensive Tool & Execution Audit**:
   - Verify `scripts/init-project.sh` and `scripts/init-project.ps1` work cleanly with the updated template structure.
   - Verify all file permissions and `.gitattributes` LF enforcement.
3. **End-to-End Test & Diagnostic Verification**:
   - Run `tests/run_tests.sh` (all 34 integration tests).
   - Run `evals/run_evals.sh` and `evals/run_evals.ps1` (all benchmarks).
   - Run `scripts/doctor.sh --ci` and `scripts/doctor.ps1 -Ci` (14/14 checks).
   - Run `scripts/build-templates.sh --check` and `scripts/build-templates.ps1 -Check` (zero drift).
   - Run `scripts/scan-repo-secrets.sh` (0 false positives, 0 leaked tokens).
4. **Final Task State & Repository Sign-off**:
   - Record comprehensive final state in `docs/task-state.md` and produce final engineering report.

---

### Phase 7 & 8 Handoff (Final Production Sign-Off)
- **What Changed**:
  - **Path Sanitization**:
    - Sanitized machine-specific link in `registry/projects.md` (`file:///C:/Users/HP/...`) to relative markdown link `docs/decisions/001-ai-operating-system-architecture.md`.
    - Verified repo-wide absence of hardcoded user or absolute OS paths.
  - **Project Scaffolding Hardening**:
    - Added executable permissions ensure step `chmod +x .githooks/pre-commit 2>/dev/null || true` to `scripts/init-project.sh`.
    - Added CI matrix steps in `.github/workflows/ci.yml` running both Linux (`evals/run_evals.sh`) and Windows (`evals/run_evals.ps1`) empirical evaluation suites.
  - **Template Parity & Synchronized Artifacts**:
    - Recompiled rule modules and rebuilt template distributions using `build-templates` (manifest tracking 49 files, verified 0 drift).
- **What Was Verified**:
  - `tests/run_tests.sh`: **34/34 tests PASSED** (19 hook tests + 10 installer/upgrader/drift tests + 5 sync gate tests).
  - `evals/run_evals.sh`: **5/5 benchmarks PASSED**.
  - `evals/run_evals.ps1`: **4/4 benchmarks PASSED**.
  - `scripts/doctor.ps1 -Ci`: **14/14 checks PASSED**.
  - `scripts/doctor.sh --ci`: **14/14 checks PASSED**.
  - `scripts/build-templates.sh --check`: **PASS** (Zero drift).
  - `scripts/build-templates.ps1 -Check`: **PASS** (Zero drift).
  - `scripts/scan-repo-secrets.sh`: **PASS** (0 matches / 0 false positives).
---

## Hardening End-to-End Progress (Steps 1–6)

### Step 1: Prove AGENTS.md Reduction Kept Safety Content
- **What Changed**:
  - Created `tests/test_agents_contract.sh` asserting all 8 required criteria in both master `AGENTS.md` and shipped `templates/project/AGENTS.md`:
    1. Candidate learning gate (`.ai/mistakes-candidates.md` and no direct rule append).
    2. Safe self-modification & prompt-injection defense.
    3. Never-record-secrets security mandate.
    4. Conflict detection protocol.
    5. 4-part prompt contract (`GOAL`, `CONSTRAINTS`, `FORMAT`, `FAILURE`).
    6. Instruction priority hierarchy.
    7. On-demand loading pointer to `.ai-os/playbooks`.
    8. Non-interactive escape for reverse prompting.
  - Demonstrated test failing against a stripped test copy, then restored compact wording in both master and template files.
  - Re-measured footprint: Master `AGENTS.md` = **4,760 bytes**; Template `AGENTS.md` = **3,601 bytes** (both strictly under the **8,192-byte** budget).
- **What Was Verified**:
  - `tests/test_agents_contract.sh`: **3/3 Passed** (contract validation, master budget enforcement, template budget enforcement).
  - Included `test_agents_contract.sh` into `tests/run_tests.sh`.
- **Not Verified**:
  - CI execution on GitHub Actions (pending Step 3 push).

### Step 2: Make the CI Approval Gate Real
- **What Changed**:
  - Updated `scripts/approve-proposal.sh` and `scripts/approve-proposal.ps1`:
    - In CI (`--pr-review` / `-PrReview`), queries the GitHub API (`gh api` or `Invoke-RestMethod` with `$GITHUB_TOKEN`) for PR details and reviews.
    - Rejects PRs without approvals.
    - Rejects author self-approval (`user.login == pr_author`).
    - Enforces `.github/CODEOWNERS` mapping for rule promotion paths (`AGENTS.md`, `.ai/rules/`, `*`).
    - Added `AI_OS_MOCK_GH_API` test hook for hermetic mock execution.
  - Added mocked API tests in `tests/test_sync.sh` covering:
    1. Rejects PR with no approval (`COMMENTED` only).
    2. Rejects author self-approval.
    3. Rejects non-CODEOWNER approval.
    4. Promotes rule when approved by CODEOWNER.
  - Documented sole maintainer multi-account / admin bypass rules in `docs/branch-protection.md`.
- **What Was Verified**:
  - `tests/test_sync.sh`: **18/18 Passed** (including all 4 mocked approval scenarios).
  - `scripts/doctor.ps1` & `scripts/doctor.sh`: **17/17 Passed**.
  - `scripts/build-templates.ps1 -Check`: **0 drift**.
- **Not Verified**:
  - Live GitHub API response against real pull request on github.com (pending Step 3 PR creation).

### Step 3: Push and Get CI Green
- **What Changed**:
  - Authenticated `workflow` scope on account `RudraSharma3`.
  - Pushed branch to `refs/heads/hardening` and opened Pull Request #1 (`https://github.com/RudraSharma3/ai-operating-system/pull/1`).
  - Added `git config core.hooksPath .githooks` and `PYTHONIOENCODING: "utf-8"` into `.github/workflows/ci.yml`.
  - Added `100755` executable mode on `tests/test_agents_contract.sh` and explicit bash invocation in `tests/run_tests.sh`.
  - Added `.mdc` to `text_extensions` in `scripts/build-templates.sh` and `scripts/build-templates.ps1` to prevent CRLF vs LF hash divergence.
  - Hardened `scripts/upgrade.sh` against Windows `cp1252` encoding by adding `sys.stdout.reconfigure(encoding='utf-8')` and ASCII indicators.
  - Robustified `evals/run_evals.ps1` Prompt Contract regex to match ASCII section headers across PowerShell versions.
- **What Was Verified**:
  - GitHub Actions Workflow Run URL: [https://github.com/RudraSharma3/ai-operating-system/actions/runs/40471271168](https://github.com/RudraSharma3/ai-operating-system/actions/runs/40471271168)
  - `Windows Verification (Windows Server)`: **SUCCESS (PASS)** in 1m29s (Job ID: `122078686831`)
    - Set up job: PASS
    - Checkout code: PASS
    - Configure Git identity: PASS
    - Run Doctor Diagnostics (PowerShell): PASS (17/17 checks)
    - Verify Template Drift (PowerShell): PASS (0 drift)
    - Verify Rule Compiler Synchronization (PowerShell): PASS
    - Run Empirical Evals & Benchmarks (PowerShell): PASS (4/4 benchmarks)
    - Run Bootstrap (PowerShell): PASS
    - Run Test Harness (Git Bash on Windows): PASS (52/52 tests)
  - `Linux Verification (Ubuntu)`: **SUCCESS (PASS)** in 11s (Job ID: `122078687038`)
    - Set up job: PASS
    - Checkout code: PASS
    - Configure Git identity: PASS
    - Run Master Test Harness: PASS (52/52 tests)
    - Run AI-OS Doctor Diagnostics (--ci): PASS (17/17 checks)
    - Audit Tracked Files for Leaks: PASS (0 secrets)
    - Run Empirical Evals & Benchmarks: PASS (5/5 benchmarks)
- **Not Verified**:
  - None. Both Linux and Windows CI runners are completely green on GitHub Actions.











