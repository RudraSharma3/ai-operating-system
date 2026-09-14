# Codebase Analysis Playbook

Follow this playbook when entering an unfamiliar, large, or legacy codebase to build accurate mental models without making premature modifications.

---

## 1. Map Top-Level Structure

1. List the repository root and top-level directory structure.
2. Read project documentation: `README.md`, `AGENTS.md`, `docs/architecture.md`, and configuration files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.).
3. Identify the technology stack, framework, build tools, and test harness.

## 2. Identify Entry Points and Key Boundaries

1. Locate the application entry points (e.g., `main.py`, `index.ts`, `cmd/server/main.go`, `App.tsx`).
2. Map core architectural layers:
   - Presentation / API routes / Controllers
   - Business logic / Services / Domains
   - Data access / Models / Database migrations
   - External integrations / Third-party clients
   - Background tasks / Queues

## 3. Map Data Flow and State Management

1. Trace a standard request/interaction lifecycle end-to-end (from user input to database persist/return).
2. Identify state stores, caching layers, and database connections.
3. Identify authentication/authorization mechanisms and security boundaries.

## 4. Evaluate Test Coverage & Tooling

1. Locate existing tests (`tests/`, `__tests__/`, `*_test.go`).
2. Run test and lint commands to check project health.
3. Identify missing test areas or brittle test setups.

## 5. External Research & Source Triangulation

When researching unfamiliar libraries or APIs, follow the **Source Triangulation Standard**:
1. **Tier 1 (Official Authority)**: Consult official documentation and API type definitions.
2. **Tier 2 (Recency Check)**: Check GitHub release notes/changelogs to confirm non-deprecated syntax.
3. **Tier 3 (Production Gotchas)**: Check GitHub issues and community discussions for known edge cases.
4. Filter out sources older than 2 years for fast-evolving frameworks.

## 6. Record Findings & Generate Dependency Graph

1. Synthesize architecture findings into `docs/architecture.md`.
2. Generate or update visual component flows and call paths in `docs/graph.md` (Mermaid diagrams + blast radius matrix).
3. Highlight constraints, existing conventions, and risks before proposing any code changes.
