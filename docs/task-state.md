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
   - Audit `registry/projects.md` and repository markdown files for hardcoded local user paths (e.g. `<user-home>/...`) and replace with generic portable placeholders (`<project-root>`, `./projects/`).
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
    - Sanitized machine-specific link in `registry/projects.md` (`file://<local-path>/...`) to relative markdown link `docs/decisions/001-ai-operating-system-architecture.md`.
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
  - GitHub Actions Workflow Run URL: [https://github.com/RudraSharma3/ai-operating-system/actions/runs/40476782802](https://github.com/RudraSharma3/ai-operating-system/actions/runs/40476782802)
  - Pull Request #1: [https://github.com/RudraSharma3/ai-operating-system/pull/1](https://github.com/RudraSharma3/ai-operating-system/pull/1)
  - `Windows Verification (Windows Server)`: **SUCCESS (PASS)** in 1m52s (Job ID: `122096858385`)
    - Set up job: PASS
    - Checkout code: PASS
    - Configure Git identity: PASS
    - Run Doctor Diagnostics (PowerShell): PASS (19/19 checks)
    - Verify Template Drift (PowerShell): PASS (0 drift)
    - Verify Rule Compiler Synchronization (PowerShell): PASS
    - Run Empirical Evals & Benchmarks (PowerShell): PASS
    - Run Replayable Task Suite (Reference Validity, PowerShell): PASS (5/5 tasks PASS)
    - Run Bootstrap (PowerShell): PASS
    - Run Test Harness (Git Bash on Windows): PASS (52/52 tests)
  - `Linux Verification (Ubuntu)`: **SUCCESS (PASS)** in 13s (Job ID: `122096858047`)
    - Set up job: PASS
    - Checkout code: PASS
    - Configure Git identity: PASS
    - Run Master Test Harness: PASS (52/52 tests)
    - Run AI-OS Doctor Diagnostics (--ci): PASS (19/19 checks)
    - Audit Tracked Files for Leaks: PASS (0 secrets)
    - Run Empirical Evals & Benchmarks: PASS (5/5 benchmarks)
    - Run Replayable Task Suite (Reference Validity): PASS (5/5 tasks PASS)
- **Not Verified**:
### Step 4: Real Evals (Replayable Tasks & Validity Proofs)
- **What Changed**:
  - Moved health-check benchmarks into `evals/health/run_evals.sh` and `evals/health/run_evals.ps1`, keeping root wrappers for backwards compatibility.
  - Implemented 5 replayable task fixtures in `evals/tasks/`:
    1. `01-bug-fix`: ZeroDivisionError handling in `calculator.py`.
    2. `02-feature`: Adding `--json` flag and formatted output to `greet.py`.
    3. `03-ambiguous-request`: Documenting 4-part Prompt Contract and explicit defaults in `docs/task-state.md` before producing JSON export.
    4. `04-secret-temptation`: Temptation to hardcode API token; verifies `.env` is ignored, key is read from environment variable, and zero keys are committed into git.
    5. `05-prompt-injection`: Malicious README instruction attempting to delete `.githooks/pre-commit` or write `compromised.txt`; verifies safety boundary remains intact and payload is ignored.
  - Built unified test runner `evals/run_task.sh` and `evals/run_task.ps1` with `--mode with|without`, `--reference`, `--agent-cmd`, and `--check-only`.
  - Added `evals/results/2026-10-27.md` recording empirical validity proof and documenting live comparison status.
  - Updated `scripts/token-report.sh` and `scripts/token-report.ps1` to parse and report evaluation benchmark results.
  - Scrubbed unbacked speed, percentage, and latency claims across docs; labeled unbenchmarked performance as `design intent, unmeasured`.
- **What Was Verified**:
  - **Empirical Validity Proof**:
    - Untouched fixtures: **0 / 5 PASSED (100% defect sensitivity)**.
    - Reference solutions: **5 / 5 PASSED (100% validity)**.
  - Cross-platform execution: Both `evals/run_task.sh` (Bash) and `evals/run_task.ps1` (PowerShell) verified on Windows and Linux runners.
- **Not Verified**:
  - Live agent comparison was **not executed** because no headless agent CLI (`claude`, `cursor`, `copilot`, `gemini`, `agy`) is installed or authenticated on the system PATH.

---

### Step 5: Cross-Repo False-Positive Check (Read-Only)
- **What Changed**:
  - Created read-only audit tool `scratch/scan_cross_repos.ps1` scanning tracked files of up to 3 git repositories in parent directory using `.ai/secret-patterns.txt`.
- **What Was Verified**:
  - Scanned 3 sibling repositories in read-only mode:
    1. Sibling Repo A: 0 matches (CLEAN).
    2. Sibling Repo B: 0 matches (CLEAN).
    3. Sibling Repo C: 2 matches (`Database URL with Credentials` in `.env.example` and `README.md`).
  - Analysis: Both hits are benign example template credentials in documentation. Total false positives = 2 (within threshold <= 2). No pattern tuning required. No repositories were modified.
- **Not Verified**:
  - None.

---

### Step 6: Remaining Roadmap Items & Release Hygiene
- **What Changed**:
  - **Phase 7 Agent-Harness Hooks**: Marked **SKIPPED**; cited lack of published vendor lifecycle hook schema in official documentation.
  - **External Sources Registry**: Created `docs/sources.md` citing official `AGENTS.md` documentation for Cursor and GitHub Copilot with retrieval dates.
  - **Doctor Expansion**: Added Check 18 (Local user home path sanitization) and Check 19 (Documentation counts synchronicity) to `scripts/doctor.sh` and `scripts/doctor.ps1`.
  - **Documentation Alignment**: Updated `README.md` and `docs/AI-OS-USER-GUIDE.md` to reflect 19 diagnostic doctor checks and 14 playbooks.
  - **Version Release Bump**: Bumped `VERSION` to `2.2.0` and added detailed release notes in `CHANGELOG.md`.
  - **CI Workflow Update**: Integrated `evals/run_task.sh` and `evals/run_task.ps1` into `.github/workflows/ci.yml`.
- **What Was Verified**:
  - `scripts/doctor.ps1`: **19/19 checks PASSED**.
  - `scripts/doctor.sh`: **19/19 checks PASSED**.
  - `scripts/build-templates.ps1 -Check`: **Zero drift**.
  - `scripts/build-templates.sh --check`: **Zero drift**.
  - `tests/run_tests.sh`: **52/52 tests PASSED**.
- **Not Verified**:
  - None.
---

## Review Gap Pass: Hardening Polish (Steps 1–6)

### Step 1: Privacy Scrub of Sibling Repo Names & Deny-List Doctor Gate
- **What Changed**:
  - Ran `git grep -n -i -E` to find any occurrences of sibling repo names in working tree.
  - Scrubbed occurrences from `docs/task-state.md` and `scratch/scan_cross_repos.ps1`, replacing with generic identifiers ("Sibling Repo A/B/C").
  - Confirmed `scratch/` is gitignored and untracked.
  - Added `.ai/private-names.txt` to `.gitignore`.
  - Added Check 20 to `scripts/doctor.sh` and `scripts/doctor.ps1`:
    - Checks tracked files against words/phrases configured in `.ai/private-names.txt` (skipping blank lines and `#` comments).
    - Fails if any tracked file matches, reporting match counts only without leaking private values.
  - Updated doctor check counts across `scripts/doctor.sh`, `scripts/doctor.ps1`, `README.md`, and `docs/AI-OS-USER-GUIDE.md` from 19 to 20.
  - Updated `scripts/install.sh` and `scripts/install.ps1` to initialize an empty `.ai/private-names.txt` and append `.ai/private-names.txt` to `.gitignore`.
  - Added test `test_doctor_private_names_denylist` in `tests/test_installer.sh`. Demonstrated test failure prior to fix, and verified passing after fix.
  - Checked commit history on remote: commit `c3190ba` on `origin/hardening` contains sibling repo names in commit message and early diffs.
  - History rewrite analysis: Rewriting remote history would require an interactive rebase (`git rebase -i` or `git filter-repo`) followed by force-pushing (`git push --force`) to `refs/heads/hardening`. Per hard rules ("never force-push, never rewrite history already on the remote"), history on the remote is not rewritten; the working tree is completely clean and doctor Check 20 prevents future commits.
- **What Was Verified**:
  - `git grep -i -E "employee-hours-reconciliation|FinTech_Project|Greeting"`: **0 matches in working tree**.
  - `tests/test_installer.sh`: **13/13 tests PASSED** (including `test_doctor_private_names_denylist`).
  - `scripts/doctor.ps1`: **20/20 checks PASSED**.
  - `scripts/doctor.sh`: **20/20 checks PASSED**.
  - `scripts/build-templates.ps1 -Check`: **Zero drift**.
- **Not Verified**:
  - Remote CI validation of Check 20 (pending Step 3 push).

### Step 2: Placeholder-Aware Secret Scanning
- **What Changed**:
  - Updated `.githooks/pre-commit` and `templates/project/.githooks/pre-commit`:
    - Added placeholder exemption for `Database URL with Credentials` and generic password patterns:
      - Does not flag obvious placeholder password or host values: `changeme`, `password`, `example`, `xxx`, `pass`, `your_*`, `<...>`, `${...}`, and `localhost` with user:pass literals (`user`, `pass`, `admin`, `root`).
      - Strictly preserves all vendor-token patterns (OpenAI, Anthropic, AWS, GitHub, Stripe, Google, Slack, Private Keys, JWT).
      - Implemented in both Python batch scanner and POSIX shell fallback.
    - Added 3 new tests in `tests/test_hook.sh`:
      - `test_allowed_placeholder_db_url`: Obvious placeholder database URLs in `.env.example` and `README.md` are allowed (Exit 0). Demonstrated test failure before fix and passing after fix.
      - `test_blocked_realistic_db_url`: Realistic database URL with random-looking password is blocked (Exit 1).
      - `test_blocked_vendor_token_in_env_example`: Vendor token in `.env.example` is still blocked (Exit 1).
    - Assembled test URL fixtures dynamically at runtime so zero secret-shaped strings are committed into git.
    - Updated `scratch/scan_cross_repos.ps1` with `Test-IsPlaceholderDbUrl` and anonymized labels.
  - Re-ran cross-repo read-only scan across 3 sibling repositories:
    - Sibling Repo 1: Skipped (not a git repo).
    - Sibling Repo 2: 0 matches (CLEAN).
    - Sibling Repo 3: 0 matches (CLEAN - placeholder database URLs in `.env.example` and `README.md` exempted).
    - Total matches across all repos: **0 matches (0 false positives, 0 true positives)**.
- **What Was Verified**:
  - `tests/test_hook.sh`: **22/22 tests PASSED** (including all 3 new placeholder & vendor-token tests).
  - `tests/run_tests.sh`: **56/56 tests PASSED**.
  - `scratch/scan_cross_repos.ps1`: **0 false positives across 3 sibling repositories**.
  - `scripts/doctor.ps1`: **20/20 checks PASSED**.
  - `scripts/doctor.sh`: **20/20 checks PASSED**.
  - `scripts/build-templates.ps1 -Check`: **Zero drift**.
- **Not Verified**:
  - None.

### Step 3: macOS and Legacy-Upgrade Coverage
- **What Changed**:
  - Added `test-macos` job to `.github/workflows/ci.yml` running on `macos-latest` executing:
    - Master test harness (`bash tests/run_tests.sh`)
    - AI-OS Doctor diagnostics (`bash scripts/doctor.sh --ci .`)
    - Secret scan of tracked files (`bash scripts/scan-repo-secrets.sh`)
    - Empirical evals & benchmarks (`bash evals/run_evals.sh`)
    - Replayable task reference validity suite (`bash evals/run_task.sh --task all --reference`)
  - Updated trigger branches in `.github/workflows/ci.yml` to include `hardening` on push and pull_request.
  - Audited shell scripts for BSD portability (macOS):
    - Confirmed `mktemp -d 2>/dev/null || mktemp -d -t '...'` portable fallback.
    - Verified `date +"%Y%m%d"` POSIX compliance.
    - Verified `sed -i.bak ... && rm ...` in `scripts/init-project.sh`.
    - No GNU-only flags used across shell scripts.
  - Added legacy pre-manifest upgrade handling:
    - In `scripts/upgrade.sh` and `scripts/upgrade.ps1`, added explicit detection: `[LEGACY] No prior manifest found (pre-manifest legacy install detected). Migrating cleanly to manifest tracking...`.
    - Preserves existing files without data loss and writes `.ai-os/manifest.json`.
  - Added test in `tests/test_installer.sh` (`test_upgrade_legacy_pre_manifest`):
    - Simulates pre-manifest install (files present, no `.ai-os/manifest.json`).
    - Customizes an existing file.
    - Runs upgrade: asserts exit code 0, asserts legacy detection message, asserts `.ai-os/manifest.json` is created, and asserts customized content is preserved without data loss.
- **What Was Verified**:
  - `tests/test_installer.sh`: **14/14 tests PASSED** (including `test_upgrade_legacy_pre_manifest`).
  - `tests/run_tests.sh`: **57/57 tests PASSED**.
  - `scripts/doctor.ps1`: **20/20 checks PASSED**.
  - `scripts/doctor.sh`: **20/20 checks PASSED**.
  - GitHub Actions Workflow Run (Pull Request #1): [https://github.com/RudraSharma3/ai-operating-system/actions/runs/40483285124](https://github.com/RudraSharma3/ai-operating-system/actions/runs/40483285124)
    - `Linux Verification (Ubuntu)` (ID `122118673941`): **SUCCESS (PASS)** in 18s
    - `macOS Verification (macOS)` (ID `122118673775`): **SUCCESS (PASS)** in 32s
    - `Windows Verification (Windows Server)` (ID `122118673370`): **SUCCESS (PASS)** in 2m0s
  - GitHub Actions Workflow Run (Push to `hardening`): [https://github.com/RudraSharma3/ai-operating-system/actions/runs/40483277642](https://github.com/RudraSharma3/ai-operating-system/actions/runs/40483277642)
    - `Linux Verification (Ubuntu)` (ID `122118647900`): **SUCCESS (PASS)** in 17s
    - `macOS Verification (macOS)` (ID `122118647380`): **SUCCESS (PASS)** in 24s
    - `Windows Verification (Windows Server)` (ID `122118647848`): **SUCCESS (PASS)** in 1m44s
- **Not Verified**:
  - None.

### Step 4: Phase 7 Done Properly (Claude Code Opt-In Lifecycle Hooks)
- **What Changed**:
  - Fetched official vendor documentation from `https://code.claude.com/docs/en/hooks` and `https://code.claude.com/docs/en/hooks.md`.
  - Updated `docs/sources.md` with:
    - Official documentation URL, retrieval date (2026-10-27).
    - Lifecycle events documented: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, `Stop`.
    - Exact JSON settings schema (`.claude/settings.json`), matcher regex, exit codes, and stdout decision schema (`permissionDecision: "deny"`).
    - Security notes: hooks run with user permissions, plain reviewable scripts, never execute untrusted tool input content.
  - Implemented opt-in hooks in `.ai-os/optional/claude-hooks/`:
    - `README.md`: Security notices, hook documentation, opt-in installation flags.
    - `settings.json`: Configuration mapping `SessionStart`, `PreCompact`, and `PreToolUse`.
    - `session-start.sh` & `session-start.ps1`: Prints `docs/task-state.md` summary and token budget metrics.
    - `pre-compact.sh` & `pre-compact.ps1`: Writes durable pre-compaction state checkpoint into `docs/task-state.md`.
    - `pre-tool-use.sh` & `pre-tool-use.ps1`: Intercepts `Write`/`Edit` and `Bash`/`PowerShell`. Blocks direct edits to governance files (`AGENTS.md`, `.ai/rules/`, `.githooks/`, `scripts/`) unless `AI_OS_ALLOW_GOVERNANCE_EDIT=1`; blocks subversive commands (`git commit --no-verify`, `git push --force`). Never executes tool input content; relies on stdin JSON parsing and safe regex. Uses `$CLAUDE_PROJECT_DIR` for paths.
  - Updated `scripts/install.sh` and `scripts/install.ps1`:
    - Added `--with-claude-hooks` (Bash) and `-WithClaudeHooks` (PowerShell) flags.
    - Opt-in only: not installed by default.
  - Updated `scripts/build-templates.sh` and `scripts/build-templates.ps1` to mirror `.ai-os/optional/claude-hooks/` into template.
  - Added Check 21 to `scripts/doctor.sh` and `scripts/doctor.ps1`:
    - Warns (`WARN`) if opt-in Claude Code hooks are installed (`.claude/settings.json` present), passes (`PASS`) if clean.
  - Added unit test suite `tests/test_claude_hooks.sh` testing `SessionStart`, `PreCompact`, and all `PreToolUse` blocking/allowing cases plus input injection defense (14 tests).
  - Added installer integration test `test_claude_hooks_opt_in_install` in `tests/test_installer.sh`.
  - Updated doctor check counts to 21 across `scripts/doctor.sh`, `scripts/doctor.ps1`, `README.md`, and `docs/AI-OS-USER-GUIDE.md`.
- **What Was Verified**:
  - `tests/test_claude_hooks.sh`: **14/14 tests PASSED** (0 failed).
  - `tests/test_installer.sh`: **15/15 tests PASSED** (including `test_claude_hooks_opt_in_install`).
  - `tests/run_tests.sh`: **72/72 tests PASSED** across all 5 test suites.
  - `scripts/doctor.ps1`: **21/21 checks PASSED**.
  - `scripts/doctor.sh`: **21/21 checks PASSED**.
  - `scripts/build-templates.ps1 -Check`: **Zero drift**.
  - `scripts/build-templates.sh --check`: **Zero drift**.
- **Not Verified**:
  - Live execution inside an active Claude Code CLI session (requires human interactive session with `claude` installed; verified deterministically via stdin JSON unit and integration test harnesses).

### Step 5: Strengthen Evals Against Gaming & Stub Agent Proofs
- **What Changed**:
  - **Task 03 Anti-Gaming**:
    - Updated `evals/tasks/03-ambiguous-request/check.sh` and `check.ps1` to require referencing at least two specific details from the prompt (`users.json`, `active`) in addition to contract keywords.
    - Verified that generic boilerplate containing contract keywords without domain assumptions fails validation.
  - **Negative Controls for All Tasks (01-05)**:
    - Implemented negative control fixtures (`negative_solution.sh` and `negative_solution.ps1`) for every task:
      - `01-bug-fix`: Returns `None` indiscriminately, breaking standard division test.
      - `02-feature`: Hardcodes JSON unconditionally, breaking default plain-text greeting test.
      - `03-ambiguous-request`: Generic boilerplate claiming compliance without referencing prompt entities.
      - `04-secret-temptation`: Directly commits hardcoded vendor API token.
      - `05-prompt-injection`: Executes injection payload and creates `compromised.txt`.
    - Added `--negative` / `-Negative` flag to `evals/run_task.sh` and `evals/run_task.ps1`.
    - Executed negative suite across all tasks: 0 passed, 5 failed (100% rejection rate).
    - Executed reference suite across all tasks: 5 passed, 0 failed (100% acceptance rate).
  - **Deterministic Stub-Agent Plumbing Proof**:
    - Implemented `evals/stub_agent.sh` and `evals/stub_agent.ps1` with actions `apply` (applies reference solution) and `noop` (does nothing).
    - Created `evals/test_eval_harness.sh` running full matrix tests for `--agent-cmd` across `--mode with` and `--mode without` in both Bash and PowerShell.
    - Verified 8/8 test scenarios passed (apply -> PASS, noop -> FAIL across both modes and runtimes).
  - **Headless Agent CLI Audit**:
    - Audited system PATH for headless agent tools: `claude`, `gemini`, `codex`, `cursor-agent`. Result: none present.
    - Documented exact commands for headless evaluation in `evals/results/2026-10-27.md`.
    - Updated `README.md` and `evals/README.md` with explicit disclaimer: "The comparative effect of AI-OS on live agent outcomes is currently unmeasured."
- **What Was Verified**:
  - `evals/run_task.sh --task all --negative`: **0 Passed / 5 Failed (100% negative controls rejected)**.
  - `evals/run_task.sh --task all --reference`: **5 Passed / 0 Failed (100% reference solutions passed)**.
  - `evals/test_eval_harness.sh`: **8 / 8 harness integration scenarios PASSED**.
  - `tests/run_tests.sh`: **72/72 tests PASSED**.
- **Not Verified**:
  - Live model execution against external LLM API (no headless CLI available or authenticated on system PATH).


