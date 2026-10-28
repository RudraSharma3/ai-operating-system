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
   - Benchmarks `scripts/doctor.sh` and `scripts/doctor.ps1` execution time across 23 health checks.
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
# Bash (verify all negative controls are rejected)
bash evals/run_task.sh --task all --negative --expect-fail

# PowerShell
powershell -ExecutionPolicy Bypass -File evals/run_task.ps1 -Task all -Negative -ExpectFail
```

### Run with Headless Agent CLI (Verified Flags):
```bash
# Bash (Claude Code CLI verified headless mode with narrow permission)
bash evals/run_task.sh --task all --mode with --agent-cmd "claude --permission-mode default -p"

# PowerShell
powershell -ExecutionPolicy Bypass -File evals/run_task.ps1 -Task all -Mode with -AgentCmd "claude --permission-mode default -p"
```
*(Verified headless flags and narrow permission options are recorded in `docs/sources.md`. The dangerous bypass flag `--dangerously-skip-permissions` is restricted as a last resort and blocked unless `AI_OS_EVAL_SANDBOX=1` is set in an isolated sandbox).*

### Run Stub-Agent Harness Plumbing Tests:
```bash
bash evals/test_eval_harness.sh
```

### Run System Health & Latency Benchmarks:
```bash
bash evals/run_evals.sh
```

---

## Limits of the Eval Sandbox

The evaluation runner temporary directory isolates only the repository working directory. **It is not a security sandbox.**

Specifically:
- An agent executing commands can still read, modify, or delete any files accessible to the current operating system user (including the home directory, SSH keys, shell configuration, and credentials).
- The harness does not restrict or firewall outbound network access.
- Environment variable stripping removes common secret signatures from child processes, but does not provide OS-level or containerized isolation.

### Recommendations for Live Runs
For executing untrusted or autonomous agent runs:
1. **Run inside a Container or VM**:
   Use Docker or a disposable virtual machine to enforce filesystem, user privilege, and network boundaries:
   ```dockerfile
   # Minimal example Dockerfile (untested):
   FROM debian:bookworm-slim
   RUN apt-get update && apt-get install -y git curl python3 bash && rm -rf /var/lib/apt/lists/*
   RUN useradd -m -s /bin/bash sandboxuser
   USER sandboxuser
   WORKDIR /home/sandboxuser/workspace
   ```
   Or via Docker CLI:
   ```bash
   # Example docker invocation (untested):
   docker run --rm -it --network none -v "$PWD:/workspace" -w /workspace debian:bookworm-slim /bin/bash
   ```
2. **Use Narrow Permission Modes**:
   Always configure the narrowest verified permission mode from [`docs/sources.md`](../docs/sources.md) (e.g., `claude --permission-mode default -p` or `claude --allowedTools "Bash,Read,Edit" -p`). Documented dangerous flags (such as `--dangerously-skip-permissions`) should never be used on developer workstations.
