# Security Policy

## Reporting a Vulnerability

We take the security of AI Operating System and the projects using it seriously.

### Reporting via GitHub Private Vulnerability Reporting
Please submit vulnerability reports exclusively through **GitHub Private Vulnerability Reporting**:
1. Navigate to the repository's [Security Advisories tab](https://github.com/RudraSharma3/ai-operating-system/security/advisories).
2. Click **Report a vulnerability** to open a private draft advisory.
3. Include:
   - Detailed description of the vulnerability.
   - Exact steps or minimal reproducer script to reproduce the behavior.
   - Potential impact and threat scenario.
   - Proposed mitigation or patch if available.

> [!NOTE]
> Please do **NOT** post security vulnerabilities in public GitHub issues, discussions, or pull requests until a fix is released. All vulnerability reports must be submitted through GitHub Private Vulnerability Reporting.

### Response & Maintenance Policy
This is an independent, solo-maintained project. Vulnerability reports are handled on a best-effort basis:
- Reports are reviewed and acknowledged when possible.
- There are no guaranteed response timelines or formal SLAs.
- Mitigations, patches, and security advisories are developed as maintainer availability permits.

---

## Supported Versions

Only the current active release receives security updates and patches:

| Version Series | Supported          | Status                                  |
| :---           | :---               | :---                                    |
| `2.4.3`        | :white_check_mark: | Current active release (`VERSION`).     |
| `< 2.4.3`      | :x:                | Unsupported; please upgrade to `2.4.3`. |

---

## Scope

### In Scope
- **Secret Scanning & Leaks**: Flaws or bypasses in the Git pre-commit secret hook (`.githooks/pre-commit`), secret pattern definitions, or repository audit scripts (`scripts/scan-repo-secrets.*`).
- **Rule Engine & Consensus Integrity**: Flaws in the candidate rule gate (`scripts/sync-rules.*`), rule compiler (`scripts/compile-rules.*`), or proposal verification (`scripts/approve-proposal.*`) that allow unauthorized rule promotion or bypass branch protection.
- **Diagnostic Invariants**: Silent failures or false-negative passes in the diagnostic engine (`scripts/doctor.*`) concerning security invariants.
- **Eval Harness & Sandbox Security**: Environment variable stripping failures, unintended token leakage, or credential exposure in evaluation harnesses (`evals/run_task.*`, `evals/run_evals.*`).
- **Supply-Chain & Distribution**: Insecure template synchronization, malicious package installation mechanisms, or unpinned external dependencies.

### Out of Scope
- **Inherent Model Non-Determinism**: General reasoning errors, factual hallucinations, or token limits originating from external LLM providers.
- **Adversarial Prompt Injections with Human Bypass**: Prompt injections where an agent proposes a malicious change but the human reviewer explicitly approves it without inspection.
- **Bypassed Sandbox Protections**: Incidents occurring when the user intentionally overrides security guardrails (e.g., using `--dangerously-skip-permissions` outside an isolated virtual machine or container).
- **Physical or Local Machine Compromise**: Attacks requiring prior root or administrative compromise of the developer's local operating system.
- **Vulnerabilities in Third-Party Dependencies**: Bugs in external MCP servers or upstream packages that do not affect the AI-OS packaging or integration contract (report directly to upstream maintainers).
