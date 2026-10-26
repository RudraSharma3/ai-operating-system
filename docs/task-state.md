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

## Phase 5 Plan: Honest Routing & Consensus (F7, F8)
1. **Clean & Verify `mcp.json`**:
   - Audit `mcp.json` and `templates/project/mcp.json`: remove fictitious, broken, or unreachable servers. Keep genuine, verified configurations (or realistic stdio MCP configurations with clear setup docs).
2. **Model Routing Matrix (`.ai/routing.md`)**:
   - Create `.ai/routing.md` defining practical, honest routing tiers:
     - Tier 1: Routine tasks (Solo model mode, zero multi-agent overhead).
     - Tier 2: Standard feature implementation (1-Implementer + 1-Verifier).
     - Tier 3: Strategic architecture & cross-cutting changes (Consensus / Multi-agent).
3. **Ground Stochastic Consensus (`playbooks/stochastic-consensus.md`)**:
   - Replace vague subjective model voting with deterministic criteria (compilation passes, type checking, test assertion passes, benchmark/linter validation).
4. **Headless Escape Hatch (`playbooks/prompt-refinement.md`)**:
   - Add clear escape hatch for non-interactive / CI / script-driven environments where interactive Reverse Prompting is disabled.
5. **Verification**:
   - Run tests, verify template drift, and run doctor diagnostics.






