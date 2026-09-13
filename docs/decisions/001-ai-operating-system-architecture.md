# ADR 001: Architecture of the AI Operating System & Safe Self-Improvement Loop

- **Status**: Accepted
- **Date**: 2026-09-13
- **Author**: Antigravity / AI Systems Architect
- **Deciders**: Rudra Sharma & AI Operating System Engineering Team

---

## 1. Context and Problem Statement

Modern software engineering increasingly relies on AI coding agents across multiple LLM providers (Google Gemini, Anthropic Claude, OpenAI Codex/ChatGPT). However, AI development workflows suffer from:
1. **Session Amnesia & Drift**: Each session starts from scratch without persistent architectural memory, coding conventions, or role boundaries.
2. **Instruction Duplication & Fragility**: Maintaining separate prompt files for different LLMs leads to contradictory rules and maintenance overhead.
3. **Naive Self-Modification Hazards**: Allowing agents to directly rewrite their instructions upon encountering user corrections leads to prompt injection vulnerability, duplicate/contradictory rules, secret leakage, and uncontrolled prompt bloat.

We need a unified, portable, and safe operating system layer that manages agent behaviors across projects and LLM providers.

---

## 2. Considered Options

- **Option A: Provider-Specific Rule Files (Independent CLAUDE.md, GEMINI.md, CODEX.md)**
  - *Pros*: Highly tailored to specific tools.
  - *Cons*: High rule duplication, high maintenance burden, inevitable drift and contradiction between providers.
- **Option B: Autonomous Direct-Editing Rules Engine**
  - *Pros*: Immediate rule updates when user provides feedback.
  - *Cons*: Severe security vulnerability (prompt injection via code or web data), accidental rule permanentization of temporary instructions, credential leaks into prompts.
- **Option C: Canonical Rule Engine with Provider Adapters & Safe Gated Learning Loop (Chosen)**
  - *Pros*: Single canonical source of truth (`AGENTS.md`), thin provider adapters, gated candidate lesson logging (`.ai/mistakes-candidates.md`), 10-point quality verification before rule promotion, superseding history rather than silent deletion.
  - *Cons*: Requires structured 2-step logging for candidate lessons before permanent promotion.

---

## 3. Decision Outcome

We chose **Option C: Canonical Rule Engine with Provider Adapters & Safe Gated Learning Loop**.

### Core Architecture Components:

1. **Canonical Source of Truth (`AGENTS.md`)**:
   - Universal operating rules (Understand Before Acting, Preserve Intent, Verify Before Declaring Success).
   - Priority hierarchy (Platform Safety > Explicit User Instructions > Project Requirements > Validated Learned Rules > Agent Defaults).
   - Rule classification scopes (`UNIVERSAL`, `REPOSITORY`, `PROJECT`, `TASK`).
   - Categorized and sequentially numbered learned rules.
   - Superseding mechanism where obsolete rules are marked as superseded rather than silently erased.

2. **Zero-Duplication Provider Adapters (`CLAUDE.md`, `GEMINI.md`, `CODEX.md`)**:
   - Point directly to canonical `AGENTS.md` and contain only tool-specific runner configurations.

3. **Safe Gated Learning Loop**:
   - Observations, mistakes, or friction are captured as candidates in `.ai/mistakes-candidates.md`.
   - Before promotion, candidates must satisfy the 10-point quality check (Reusability, Evidence, Actionability, Generality, Scope, No Redundancy, No Conflict, Safety, Zero Secrets, Durability).
   - Verified project-level lessons are promoted to `docs/lessons.md`.
   - Universal lessons are promoted to `AGENTS.md`.

4. **Multi-Agent Role Prompts (`prompts/`) & Playbooks (`playbooks/`)**:
   - Standardized roles (Architect, Implementer, Reviewer, Tester, Researcher, Security Reviewer, Data/AI Specialist).
   - Standardized playbooks for project creation, feature development, bug fixes, codebase analysis, reviews, tests, architecture decisions, and learning loops.

5. **Portable Downstream Project Template (`templates/project/`)**:
   - Ready-to-copy package enabling any new repository to inherit the full operational stack immediately.

### Consequences

- **Positive**: Consistent behavior across all AI coding tools; robust protection against prompt injection and secret leakage; permanent audit trail of decisions and lessons.
- **Trade-offs**: Agents must follow the structured candidate logging workflow rather than directly modifying operating rules.
