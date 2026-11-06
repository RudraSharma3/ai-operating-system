# AI-OS Handoff

State as of 2026-11-06. Verify this before relying on it: run the commands in section 6 and compare.

## 1. What AI-OS Is

AI-OS is a governance layer for AI coding agents (Claude Code, Gemini, Codex, Cursor, Copilot). It reduces specific, testable failure modes: phantom dependencies, undeclared imports, unverified "tests pass" claims, and secret leaks. It does not fix factual errors in chat answers.

The safety tooling is tested. Its effect on live agent outcomes is **unmeasured**.

## 2. Architecture

| Part | Where | Purpose |
|---|---|---|
| Canonical rules | `AGENTS.md` | Single source of agent instructions; 8,192-byte budget, never raised |
| Thin adapters | `CLAUDE.md`, `GEMINI.md`, `CODEX.md`, `.cursor/rules/agents.mdc`, `.github/copilot-instructions.md` | Point each tool at `AGENTS.md` |
| Template | `templates/project/`, built by `scripts/build-templates.sh` | What downstream repos receive; `--check` detects drift |
| Rule compiler | `scripts/compile-rules.sh`, `.ai/rules/` | Compiles modular rules into `AGENTS.md` |
| Learning loop | `.ai/proposals/`, `scripts/sync-rules.sh`, `scripts/approve-proposal.sh` | Gated rule promotion with a human step |
| Pre-commit guard | `.githooks/pre-commit` | Secret scan, dependency audit, import check |
| Verifier | `scripts/ai_os_verify.py` | `deps`, `imports`, `run`, `evidence`; `--online` only in registry checks |
| Approvals | `.ai/deps-approved.txt` | Human-approved dependencies; the tool never writes it |
| Evidence ledger | `.ai/evidence/` | Local, gitignored, agent-writable run records |
| Claude Code hooks | `.ai-os/optional/claude-hooks/` | Opt-in deny rules; the shell check is best-effort |
| Install and health | `scripts/install.*`, `scripts/doctor.*`, `scripts/upgrade.*` | Install, 27 offline checks, upgrade |
| Evals | `evals/` | Tasks 01 to 08 with negative controls and stub agents |

Threat model: `docs/threat-model.md`. Sources: `docs/sources.md`. Local hooks catch honest mistakes; the real gate is CODEOWNERS plus branch protection requiring code-owner review.

## 3. Current State

- **Release**: v2.5.0, published 2026-11-05 at merge commit `b80cbe1840e1be88031ecbe49a07a34ecf31c0b1`.
- **PR #14**: merged with an owner-authorized admin bypass. It had no code-owner review, because no second code owner exists.
- **CI**: run `42120032947` passed on Linux, macOS, and Windows on the same file tree, before the history rewrite below.
- **PR #17**: merged to `main` after the release as `23fa9c9a07e63819c9b098e2c6105a293cb6d467`, also with an owner-authorized admin bypass. It aligns `docs/dependabot-cooldown-keys.json` with GitHub's 34 documented ecosystem values. It is listed under `[Unreleased]` in the CHANGELOG and is not in v2.5.0.
- **Last full local suite**: commit `91b0125`, Windows 11, all 13 commands exit 0.
- **History**: on 2026-11-06 the owner rewrote every branch and tag so that all commits are authored and committed by `RudraSharma3`. File contents did not change. SHAs in `docs/task-state.md` and other older records predate this rewrite, and old PR pages still show the earlier commits.
- **Access**: `RudraSharma3` is the only collaborator, by the owner's decision. There are no deploy keys or webhooks.
- **Branch protection on main**: strict; required checks are Linux, macOS, and Windows Verification; 1 code-owner review; stale reviews dismissed; `enforce_admins` false; no force pushes or deletions.
- **Hook overhead**: +0.7350s median with 50 staged files, Windows 11. Linux and macOS are not measured.

## 4. Rules For Agents Working Here

1. Commit as `RudraSharma3 <naganoobiea@gmail.com>` with repo-local git config only. Never use `--global`. Never add AI attribution to commits or PR descriptions.
2. Never merge, push to main, tag, release, close PRs, or change repository settings without explicit instruction in the active task text. A vague "continue" is not permission.
3. Never force-push, rewrite pushed history, or use `--no-verify`.
4. Measure, never state: every size, count, or duration comes from a command whose output you show.
5. Run commands exactly as written. If a flag or endpoint does not exist, say so.
6. Test first: show the failing test, then the fix, then the pass. Never weaken or delete a test, and never raise a budget.
7. Default tests, doctor, hooks, and evals make no network calls. Network is allowed only behind `--online`.
8. No sibling repository names, paths, or contents anywhere; counts only.
9. Web claims need a URL, a retrieval date, and a verbatim quote under 25 words fetched that session. Otherwise mark them NOT VERIFIED.
10. SHA tables have four rows: local HEAD, origin branch, GitHub API branch tip, PR headRefOid. For every PR, show the real file list and count.
11. Never write "NOT VERIFIED: None" unless every item was executed and shown. Live agent effectiveness stays NOT VERIFIED until measured.
12. Never write that this project stops hallucination, and never describe the evidence ledger as impossible to alter.

## 5. Open Items

### Needs a decision

- **Sole maintainer**: branch protection requires one approval on every PR, and a PR author cannot approve their own PR. The owner has decided to keep the repository single-person, so every merge needs an admin bypass, which the owner must authorize explicitly each time. No second person reviews these changes.
- **Merge control**: a fine-grained token with Contents write can still merge, per GitHub's REST docs: *"\"Contents\" repository permissions (write)"* (retrieved 2026-11-06). Removing Administration alone does not stop over-merging; required reviews and the rule in `AGENTS.md` do. Whether such a token can use admin bypass is NOT VERIFIED.

### Known defects

- On Windows, the test suite can leave line-ending-only changes in generated files.

### Unfinished measurement

- Cross-repository import counts (Round 4 item D): the comparison repositories could not be read. This repository has 2 tracked code files and 0 flagged imports. The 9 flagged imports in the 28-file repository remain unreconciled.
- `notebook_path` as NotebookEdit's input field is NOT VERIFIED against the fetched docs; it was observed in the tool's schema.

### Open Dependabot PRs (none merged)

Every pinned SHA matches its upstream tag. Each release was at least 14 days old on 2026-11-05. All show `BEHIND` and need updating from `main`. On 2026-11-06, `registry-check.yml` passed when run manually on all four branches.

| PR | Change | Files | Risk |
|---|---|---|---|
| #5 | `actions/checkout` 4.2.2 to 7.0.1 | `ci.yml`, `registry-check.yml` | Lower: required CI exercises it and passed before v2.5.0 |
| #6 | `actions/setup-node` 4.4.0 to 7.1.0 | `registry-check.yml` | Medium: Node 24 runtime; required CI does not run it, but the manual run passed |
| #11 | `actions/setup-python` 5.6.0 to 7.0.0 | `registry-check.yml` | Lower to medium: the removed `pip-install` input is not used here, and the manual run passed |
| #15 | `astral-sh/setup-uv` 5.4.2 to 10.3.1 (replaces #12) | `registry-check.yml` | Medium: five major versions with breaking changes, including cache defaults; the manual run passed |

`registry-check.yml` runs only on a weekly schedule or manual dispatch, so the required checks on #6, #11, and #15 say nothing about the actions they change. Use the manual runs above as the evidence, and repeat them after updating a branch.

## 6. Check The State

```bash
git fetch --all --prune
git log --oneline -5 origin/main
gh pr list --state open
gh release view v2.5.0
bash tests/run_tests.sh
bash scripts/doctor.sh --ci .
bash evals/run_task.sh --task all --reference
bash evals/run_task.sh --task all --negative --expect-fail
```

## 7. Backlog

Do not start these without the owner's go-ahead.

- Live effectiveness comparison with versus without AI-OS, using a headless agent CLI, only inside a container or VM per `evals/README.md`, with credentials stripped.
- CI enforcement of `ai_os_verify.py evidence --require` and a PR-level dependency-approval check.
- Usage monitoring for organizations and PRD-to-app generation are deferred: market feedback said both are crowded and evidence of real need is thin. Real users and customer discovery come first.
