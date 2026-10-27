# Multi-Agent MCP Orchestration Playbook

This playbook establishes the operational protocol for coordinating multiple specialized AI models using the **Model Context Protocol (MCP)** under a Manager-Worker or Router architecture, strictly constrained by `.ai/routing.md` and `mcp.json`.

---

## 1. Principles & Complexity Gate

Before engaging multiple agents, verify against `.ai/routing.md`:
1. **Tier 1 (Routine Tasks)**: Use **Solo Model Mode** directly. Zero coordination overhead. Multi-agent orchestration is strictly forbidden.
2. **Tier 2 (Standard Features)**: Use **1-Implementer + 1-Verifier** (`playbooks/feature.md`).
3. **Tier 3 (Strategic Architecture)**: Dispatch decoupled subcomponents only when boundaries are contractually separated.

---

## 2. MCP Tool Providers (`mcp.json`)

All agent tooling must map directly to verifiable, pinned servers declared in `mcp.json`:

- **`filesystem`** (`@modelcontextprotocol/server-filesystem@2.0.1` via `npx`): Sandboxed file tree reads, scoped modifications, and workspace inspection (Node.js/npm).
- **`memory`** (`@modelcontextprotocol/server-memory@2.0.0` via `npx`): Structured graph-based state tracking across long-horizon architectural evaluations (Node.js/npm).
- **`git`** (`mcp-server-git==2026.10.19` via `uvx`): Git repository reads, commit inspection, and history analysis (Python/PyPI).
- **`fetch`** (`mcp-server-fetch==2026.10.24` via `uvx`): Web content fetching, API documentation conversion, and URL reading (Python/PyPI).


---

## 3. Architecture Overview

```
                      TASK INPUT
                          │
                          ▼
             ┌─────────────────────────┐
             │   ROUTER DECISION HUB   │
             │   (.ai/routing.md)      │
             └────────────┬────────────┘
                          │
       ┌──────────────────┴──────────────────┐
       ▼                                     ▼
Needs Focused Implementation?         Needs Dual Verification?
(Implementer)                         (Verifier)
       │                                     │
       ▼                                     ▼
[filesystem] Tool Operations          [memory] Context State
       │                                     │
       └──────────────────┬──────────────────┘
                          ▼
            ┌───────────────────────────┐
            │   COLLECT & VALIDATE      │
            │   (Deterministic Suite)   │
            └─────────────┬─────────────┘
                          │
                   Tests Passing?
                   ├── Yes ──▶ Commit Changes ──▶ Done
                   └── No  ──▶ Implementer Fixes Failures
```

---

## 4. The Core Roles

1. **The Lead / Architect (Planner & Reasoner)**:
   - Owns task decomposition, prompt contract generation (`playbooks/prompt-refinement.md`), and interface boundary definition.
   - Authors the contract specification in `docs/architecture.md` before dispatching.
2. **The Implementer (Execution Specialist)**:
   - Implements changes within explicitly assigned file boundaries using the `filesystem` MCP tool.
   - Never writes secrets or unverified dependencies.
3. **The Verifier (Falsification Specialist)**:
   - Runs deterministic test suites, doctor checks, and linters.
   - Verifies against the failure checklist in the prompt contract.

---

## 5. Non-Negotiable Contract-First Protocol

1. **Manager Authors Contract First**: Interface types, schemas, and API boundaries are committed to `docs/architecture.md` before workers begin.
2. **Strict File Isolation**: Two parallel workers must never edit the same file concurrently.
3. **Deterministic Verification Over Voting**: Never use model consensus to decide questions that compilers, typecheckers, or test harnesses answer definitively.
