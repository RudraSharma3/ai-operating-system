# Server-Side Branch Protection & Security Boundaries

This document defines the mandatory server-side branch protection policies and security boundaries governing the AI Operating System.

---

## 1. The True Security Boundary: Server-Side PR Review

Local terminal checks (such as `[ -t 0 ]` in shell scripts or `[Environment]::UserInteractive` in PowerShell) are valuable client-side safeguards, but they are **defense-in-depth, not a formal cryptographic security boundary**. A local subshell or autonomous agent with terminal emulation tools (such as `pty`, `script`, or pseudo-TTY pipes) can simulate an interactive terminal session.

Therefore, the **canonical, non-bypassable security gate** for rule promotion and system hardening is **Server-Side GitHub Branch Protection**:

1. Direct pushes to `main` are strictly prohibited.
2. All changes modifying core rules, hooks, or scripts must arrive via Pull Request.
3. Every Pull Request touching protected paths requires mandatory human sign-off from designated CODEOWNERS.

---

## 2. Protected Files and CODEOWNERS Mapping

As configured in `.github/CODEOWNERS`:

| Protected Path | Owner | Rationale |
|---|---|---|
| `AGENTS.md` | `@RudraSharma3` | Canonical prompt instructions; prevents untrusted agent self-modification. |
| `.ai/rules/` | `@RudraSharma3` | Modular rules repository; prevents unvetted candidate rule promotions. |
| `.githooks/` | `@RudraSharma3` | Pre-commit secret armor; prevents weakening or disabling credential scanning. |
| `scripts/` | `@RudraSharma3` | Core compilers, upgrader, doctor, and sync engine; prevents backdoor introduction. |
| `.github/workflows/` | `@RudraSharma3` | CI/CD pipeline automation; prevents bypassing test or lint verification. |

---

## 3. GitHub Branch Protection Policy for `main`

On `github.com/RudraSharma3/ai-operating-system`:

- **Require a pull request before merging**:
  - Require approvals: Minimum 1 approved review.
  - Require review from Code Owners: **Checked (Mandatory)**.
  - Dismiss stale pull request approvals when new commits are pushed: **Checked**.
  - Require review from users other than the PR author: **Checked**.
- **Require status checks to pass before merging**:
  - `Linux Verification (Ubuntu)`
  - `Windows Verification (Windows Server)`
- **Do not allow bypassing the above settings**: Enforced for all administrators and automated bots.
