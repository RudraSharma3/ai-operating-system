# Model Routing & Orchestration Policy

This policy establishes honest, cost-aware, and capability-matched model routing rules across the AI Operating System.

---

## 1. Principles of Honest Routing

1. **Zero Cost Inflation**: Never invoke multi-model orchestration, multi-agent swarms, or parallel sampling for tasks solvable by a single focused model call.
2. **Proportional Effort**: Match model capability and reasoning depth to the actual task complexity.
3. **Deterministic Verification Over Voting**: Prefer deterministic tool verification (compiler, test suites, static analysis, linters, types) over subjective model consensus votes.

---

## 2. Complexity Routing Tiers

| Tier | Task Scope | Examples | Execution Mode | Verification Gate |
|------|------------|----------|----------------|-------------------|
| **Tier 1** | Routine & Mechanical | Typo fixes, CSS adjustment, small utility functions, single unit test updates | **Solo Model Mode** (single model pass, zero orchestration overhead) | Run targeted tests / linters directly |
| **Tier 2** | Standard Features & Modules | New API route, database schema migration, component build, end-to-end integration | **1-Implementer + 1-Verifier** (`playbooks/feature.md`) | Automated test harness + Doctor |
| **Tier 3** | Strategic Architecture | Core framework changes, multi-repository contracts, high-risk trade-offs | **Consensus & Multi-Agent** (`playbooks/stochastic-consensus.md`) | Dual-path deterministic benchmark matrix + ADR |

---

## 3. Recommended Model Profiles (2026 Baseline)

- **Primary Implementer (Solo & Feature Work)**: Claude 3.5 Sonnet / Claude 3.7 Sonnet / GPT-4o / Gemini 1.5/2.0 Flash / Pro.
- **Deep Architectural Reasoning**: Claude 3.7 Sonnet (Thinking) / o1 / o3-mini / DeepSeek-R1.
- **Fast / Local Verification & Linting**: Claude Haiku / GPT-4o-mini / Qwen 2.5 Coder 32B (via local Ollama).

---

## 4. Anti-Patterns (Strictly Forbidden)

- **No Multi-Agent Swarms on Simple Fixes**: Never spin up 3+ agents to vote on a simple bug fix or button placement.
- **No LLM Voting on Deterministic Truth**: Never use model consensus to decide questions that `npm test`, `git status`, or typecheckers can answer definitively.
- **No Infinite Polling**: Always prefer event-driven and reactive wakeups over busy-polling loops.
