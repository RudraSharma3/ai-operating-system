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

## Phase 3 Plan: Single Source of Truth, Versioning & Upgrade (F5, F8, F9)
1. **Versioning & Licensing**:
   - Add `VERSION` file (set to `2.1.0`).
   - Add `CHANGELOG.md` following Keep a Changelog standard.
   - Add `LICENSE` (MIT).
2. **Single Source of Truth Generator**:
   - Implement `scripts/build-templates.sh` and `scripts/build-templates.ps1` to programmatically assemble `templates/project/` from master source files (master `AGENTS.md`, `playbooks/`, `prompts/`, `.ai/`, `.githooks/`, etc.).
   - Add CI drift check (`scripts/build-templates.sh --check` or `git diff --exit-code`) to fail if `templates/project/` drifts from master.
3. **Manifest & Upgrade Engine**:
   - Generate `.ai-os/manifest.json` recording release version, file list, and SHA256 hashes of upstream-managed files.
   - Implement `scripts/upgrade.sh` and `scripts/upgrade.ps1` (or add `--upgrade` flag to installer): checks version against manifest, compares local sha256 to detect local customizations vs unmodified files, prompts/merges cleanly without clobbering user project modifications.
4. **Template `AGENTS.md` Hardening**:
   - Update template `AGENTS.md` to include all production sections: Safe self-modification, never learn secrets, conflict detection, learned rule quality test, minimal self-modification. Remove unsafe "Immediately append" instructions.
5. **Rule Files Modularization**:
   - Implement individual rule files under `.ai/rules/NNNN-slug.md`.
   - Implement compiler script (`scripts/compile-rules.sh` / `.ps1`) that assembles `.ai/rules/*.md` into the canonical `## Learned Rules` block in `AGENTS.md`.
6. **Provider Adapters**:
   - Add Cursor adapter (`.cursor/rules` / `.cursorrules`) and GitHub Copilot adapter (`.github/copilot-instructions.md`) pointing to `AGENTS.md`.
7. **Verification**: Run `tests/run_tests.sh`, verify template builder clean diff, run doctor diagnostics.




