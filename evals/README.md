# AI-OS Empirical Evaluation & Benchmark Suite

This directory contains automated, reproducible benchmark evaluations measuring system performance, token footprint, secret interception accuracy, diagnostic latency, and replayable agent task scenarios.

---

## Benchmark Suites

1. **Token Budget & Footprint Compliance**:
   - Asserts that canonical `AGENTS.md` stays strictly within the 8KB (~2,000 tokens) token window.
   - Measures token footprint across all adapters, playbooks, and prompts.

2. **Secret Defense Interception Accuracy**:
   - Tests POSIX ERE pattern matching across high-risk token signatures (OpenAI, Anthropic, AWS, Stripe, GitHub, Google, Database URLs).
   - Verifies 100% true-positive blocking rate and 0% false positives on allowed template patterns.

3. **Diagnostic Doctor Latency**:
   - Benchmarks `scripts/doctor.sh` and `scripts/doctor.ps1` execution time across 22 health checks.
   - Enforces a <3.0s latency budget for local developer workflows.

4. **Replayable Task Evaluation Suite (`tasks/`)**:
   - Replayable tasks covering bug fixes, feature expansion, ambiguous requests, secret temptations, and prompt injection.
   - Each task has a reference solution, adversarial negative control ("gaming" solution), and verification check.
   - Includes deterministic stub-agent harness integration testing (`evals/test_eval_harness.sh`).

---

## Outcomes & Measurement Status Note

> **Note on Outcomes**: **The comparative effect of AI-OS on live agent outcomes (speed, cost, token consumption, turns, and task pass rates) is currently unmeasured.** While structural integrity, secret interception, and Prompt Contract compliance are deterministically verified, live multi-model agent benchmarks require standardized headless evaluation environments with statistically significant sample sizes ($N \ge 30$).

---

## Running Evaluations

### Run Replayable Tasks with Reference Solutions:
```bash
# Bash
bash evals/run_task.sh --task all --reference

# PowerShell
powershell -ExecutionPolicy Bypass -File evals/run_task.ps1 -Task all -Reference
```

### Run Replayable Tasks with Negative Controls:
```bash
# Bash
bash evals/run_task.sh --task all --negative

# PowerShell
powershell -ExecutionPolicy Bypass -File evals/run_task.ps1 -Task all -Negative
```

### Run with Headless Agent CLI (Verified Flags):
```bash
# Bash (Claude Code CLI verified headless mode)
bash evals/run_task.sh --task all --mode with --agent-cmd "claude -p"

# PowerShell
powershell -ExecutionPolicy Bypass -File evals/run_task.ps1 -Task all -Mode with -AgentCmd "claude -p"
```
*(Verified headless flags and documentation sources are recorded in `docs/sources.md`)*

### Run Stub-Agent Harness Plumbing Tests:
```bash
bash evals/test_eval_harness.sh
```

### Run System Health & Latency Benchmarks:
```bash
bash evals/run_evals.sh
```
