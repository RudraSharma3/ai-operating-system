# AI-OS Empirical Evaluation & Benchmark Suite

This directory contains automated, reproducible benchmark evaluations measuring system performance, token footprint, secret interception accuracy, and diagnostic latency.

---

## Benchmark Suites

1. **Token Budget & Footprint Compliance**:
   - Asserts that canonical `AGENTS.md` stays strictly within the 15KB (~3,750 tokens) token window.
   - Measures token footprint across all adapters, playbooks, and prompts.

2. **Secret Defense Interception Accuracy**:
   - Tests POSIX ERE pattern matching across high-risk token signatures (OpenAI, Anthropic, AWS, Stripe, GitHub, Google, Database URLs).
   - Verifies 100% true-positive blocking rate and 0% false positives on allowed template patterns.

3. **Diagnostic Doctor Latency**:
   - Benchmarks `scripts/doctor.sh` and `scripts/doctor.ps1` execution time across 14 health checks.
   - Enforces a <3.0s latency budget for local developer workflows.

4. **Prompt Contract Structural Integrity**:
   - Validates that Prompt Contract generation specifications contain all 4 mandatory components (`GOAL`, `CONSTRAINTS`, `FORMAT`, `FAILURE`).

---

## Running Evaluations

### On Linux / macOS / Git Bash:
```bash
bash evals/run_evals.sh
```

### On Windows PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File evals/run_evals.ps1
```
