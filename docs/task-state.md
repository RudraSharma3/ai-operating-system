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

## Phase 2 Plan: Installer, Doctor & Downstream Playbooks (F1, F3, F4)
1. **Downstream Package Structure (F1)**:
   - Package all `playbooks/` and `prompts/` under `.ai-os/` (e.g. `.ai-os/playbooks/` and `.ai-os/prompts/`) or equivalent single folder for downstream projects.
   - Update references in template `AGENTS.md`, `.claude/commands/`, README, user guide, and installation prompts.
2. **Installer Parity & Non-Destructiveness (F3)**:
   - Make `install.sh` and `install.ps1` perform identical per-file no-clobber copies (preserving user's existing files including existing `docs/` directories).
   - Merge `.gitignore`: Append missing AI-OS rules inside a clearly marked `# --- AI-OS START ---` block without altering existing rules.
   - Hook chaining: If `core.hooksPath` is already configured (e.g., `.husky`), do NOT overwrite it. Instead, create a chain script or hook delegation, and print clear manual instructions.
   - Add `scripts/bootstrap.sh` and `scripts/bootstrap.ps1` to configure `core.hooksPath` for fresh team clones.
3. **Doctor Parity & Real Verification (F4)**:
   - Implement identical 14-point health checks in `doctor.sh` and `doctor.ps1`.
   - Verify hook installation, executable bit, and active `core.hooksPath`.
   - Secret scan all tracked files using the secret pattern engine.
   - Verify `.env` files are not tracked by Git via `git ls-files`.
   - Verify all referenced playbooks/prompts paths exist.
   - Dynamic `ARMOR` status based on actual doctor checks rather than hardcoded text.
   - Support `--ci` / `-Ci` and `--json` flags and exit with nonzero code on any failure.
4. Run `tests/test_installer.sh` and doctor validations to verify 100% PASS.



