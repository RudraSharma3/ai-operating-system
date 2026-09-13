# Standard Workflow

Every task in an AI-assisted project follows this six-stage engineering lifecycle.

---

```
  [1. Discover]  ───▶  [2. Plan]  ───▶  [3. Build]
                                              │
  [6. Handoff]   ◀───  [5. Learn] ◀───  [4. Verify]
```

---

## 1. Discover

- Read the project's canonical `AGENTS.md`, `docs/architecture.md`, and `docs/task-state.md`.
- Review active learned rules, conventions, and relevant ADRs in `docs/decisions/`.
- Understand system boundaries, dependencies, and constraints before touching code.
- If the codebase is unfamiliar, consult `playbooks/codebase-analysis.md`.

## 2. Plan & Complexity Routing

- When given a brief or informal prompt, automatically optimize it into a formal specification with acceptance criteria and edge cases (`playbooks/prompt-refinement.md`).
- **Route Task Complexity**:
  - **Tier 1 (Routine / Minor)**: Direct single-model plan. Fast-track.
  - **Tier 2 (Standard Feature / Module)**: Architect plan + explicit test criteria in `docs/task-state.md`.
  - **Tier 3 (Strategic Crossroads / Major System)**: Trigger **Stochastic Consensus** (`playbooks/stochastic-consensus.md`) to evaluate trade-offs and author an ADR.

## 3. Build

- **Solo Mode (Default)**: Single **Implementer** (`prompts/implementer.md`) makes surgical changes meeting acceptance criteria.
- **Multi-Agent Mode (Optional)**: If task has decoupled fullstack subcomponents, orchestrate via `playbooks/multi-agent-orchestration.md` using contract-first interfaces.
- Preserve existing intent, naming conventions, and architecture.
- Do not introduce unrelated refactorings or unapproved dependencies.

## 4. Verify

- Execute relevant test suites, typecheckers, linters, and runtime validation.
- Where appropriate, assign an independent **Reviewer** (`prompts/reviewer.md`) and **Tester** (`prompts/tester.md`) to falsify changes.
- Review git diffs thoroughly to ensure no unintended modifications or secrets were introduced.
- Explicitly document what was verified and note any unverified surfaces.

## 5. Learn

- If mistakes, invalid assumptions, or repeated friction occurred, follow `playbooks/learning-loop.md`.
- Log unverified findings as candidates in `.ai/mistakes-candidates.md`.
- If a lesson is verified, reusable, and passes the 10-point quality check, promote it to `docs/lessons.md` or `AGENTS.md`.
- Mark any superseded rules explicitly.

## 6. Handoff

- Update `docs/task-state.md` with final progress, resolved decisions, and test results.
- Provide a clear, concise summary of:
  1. What changed (files and functionality).
  2. How it was verified.
  3. Residual risks or known limitations.
  4. Recommended next steps.
