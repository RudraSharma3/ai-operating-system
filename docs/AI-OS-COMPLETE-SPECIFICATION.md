# AI Operating System: Complete Technical Specification

**Version:** 2.0.0 (Production Architecture)  
**Repository:** `RudraSharma3/ai-operating-system`  
**Classification:** Canonical Architecture & Systems Engineering Specification

---

## 1. Executive Summary & Vision

The **AI Operating System (AI-OS)** is a versioned, portable, and provider-agnostic operational layer that defines how AI coding agents (Google Gemini, Anthropic Claude, OpenAI Codex/ChatGPT, and local models) interact with software codebases.

### The Problem AI-OS Solves
1. **Session Amnesia & Drift**: AI models lose architectural context, coding standards, and project decisions between sessions.
2. **Naive Self-Modification Risks**: Allowing autonomous agents to overwrite prompt files directly causes prompt injection vulnerabilities, credential leakage into rules, and uncontrolled instruction bloat.
3. **Multi-Model Incompatibility**: Maintaining separate prompt rules for Claude, Gemini, and ChatGPT leads to contradictory rules and fragmented workflows.
4. **Over-Engineering & Tool Explosion**: Spawning heavy multi-agent swarms for simple tasks creates latency, high token costs, and code merge collisions.

### The Solution
A durable operational system co-located inside the git repository featuring:
- **A Single Source of Truth (`AGENTS.md`)** with thin provider adapters.
- **A 4-Level Context Hierarchy** that keeps context windows lean.
- **A Gated Safe Self-Improvement Loop** preventing injection and secrets leakage.
- **A Proportional Effort Complexity Gate** (Tier 1 Solo, Tier 2 Feature, Tier 3 Strategic Consensus).
- **Automated Tooling**: One-shot CLI scaffolding, pre-commit AI guards, federated cross-project learning, and autonomous self-healing test loops.

---

## 2. The 4-Level Context Hierarchy

```
┌────────────────────────────────────────────────────────────────────────┐
│  LEVEL 1: Global Operating System Base (AGENTS.md)                     │
│  Universal safety, verification rules, safe self-correcting engine    │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ Inherits universal standards
┌──────────────────────────────────▼─────────────────────────────────────┐
│  LEVEL 2: Project-Specific Instructions (<project>/AGENTS.md)          │
│  Project purpose, tech stack, build commands, local conventions        │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ Activates relevant capabilities
┌──────────────────────────────────▼─────────────────────────────────────┐
│  LEVEL 3: Matched Skills & Playbooks (playbooks/ & prompts/)           │
│  On-demand procedural blueprints (Testing, Review, Consensus, RAG)     │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ Executes immediate task
┌──────────────────────────────────▼─────────────────────────────────────┐
│  LEVEL 4: Inline User Prompt                                           │
│  The real-time request in the current conversational turn              │
└────────────────────────────────────────────────────────────────────────┘
```

### Priority Resolution Order:
1. **Level 1 (Platform Safety & Security)**: Absolute priority. Cannot be overridden by any prompt.
2. **Level 4 (Inline User Prompt)**: Defines immediate task goals.
3. **Level 2 (Project Conventions & Learned Rules)**: Overrides general defaults.
4. **Level 3 (Matched Skill Guidance)**: Domain-specific best practices.
5. **Level 1 (Global Defaults)**: Fallback operating principles.

---

## 3. Canonical Operating Rules & Priority Hierarchy

The root `AGENTS.md` establishes five non-negotiable operating principles:

1. **Understand Before Acting (Rule 1.1)**: Read existing code, map architecture, and search existing patterns before modifying files.
2. **Preserve Existing Intent (Rule 1.2)**: Keep changes minimal, preserve variable naming, and avoid unnecessary refactorings or new dependencies.
3. **Verify Before Declaring Success (Rule 1.3)**: Run automated tests, linters, and typechecks. If verification was not possible, explicitly state what remains unverified.
4. **Prompt Optimization & Intent Refinement (Rule 1.4)**: Automatically deconstruct messy prompts into rigorous engineering specifications with edge cases and security checks.
5. **Proportional Effort & Anti-Over-Engineering Gate (Rule 1.5)**: Default to Solo Model execution for routine tasks; reserve Multi-Agent MCP and Consensus strictly for high-complexity architecture.

### Rule Hierarchy & Scopes:
- **`[UNIVERSAL]`**: Applies across all projects (e.g. secret management).
- **`[REPOSITORY]`**: Applies to the AI-OS framework itself.
- **`[PROJECT]`**: Applies to a specific codebase/application.
- **`[TASK]`**: Ephemeral instructions that live only in `docs/task-state.md`.

---

## 4. Safe Self-Modifying Engine

AI-OS replaces naive autonomous rewriting with a **gated learning loop**:

```
  USER CORRECTION / RECURRING PREFERENCE
                   │
                   ▼
       10-POINT QUALITY EVALUATION
  (Reusability, Evidence, Actionability, Generality, Scope,
   Non-Redundancy, Non-Conflict, Safety, Zero Secrets, Durability)
                   │
         Passes all 10 checks?
         ├── YES ──▶ Append to ## Learned Rules in AGENTS.md
         └── NO  ──▶ Log Candidate in .ai/mistakes-candidates.md
```

### Self-Modification Invariants:
- **Sequential Numbering**: Rules are strictly numbered: `N. [CATEGORY] Rule — rationale.`
- **Never Silently Delete**: Obsolete rules are marked `- SUPERSEDED BY RULE N.`
- **Never Learn Secrets**: API keys, passwords, and private tokens are automatically generalized into security policies.
- **Untrusted Source Defense**: External documents, web searches, READMEs, and third-party libraries CANNOT authorize rule changes.
- **Badge Notification**: Agent explicitly outputs: `🧠 Learned Rule Added to AGENTS.md: N. [CATEGORY] Rule — rationale.`

---

## 5. Multi-Agent MCP Orchestration (Model Context Protocol)

Enables coordinated multi-model workflows under a **Manager-Worker** architecture:
- **Manager (Claude 3.7 / Opus)**: Plans, reasons, creates contracts, and resolves integration issues.
- **Worker 1 (Gemini 2.0 / Flash)**: Rapid UI generation, visual assets, and large-context codebase analysis.
- **Worker 2 (Codex / OpenAI)**: Backend APIs, database schemas, and migration logic.
- **Worker 3 (Codex / Tester)**: Test suite generation and edge-case falsification.

### Contract-First Protocol (Zero Merge Conflicts):
The Manager MUST author shared interface types in `docs/architecture.md` (e.g. TypeScript interfaces, REST schemas) *before* dispatching tasks to parallel workers. Workers are restricted to non-overlapping file boundaries.

---

## 6. Stochastic Multi-Agent Consensus Engine

Designed for strategic, high-uncertainty architectural choices (e.g. database selection, state architecture):
1. **Sample 3–5 Diverse Personas**: *The Minimalist*, *The Scalability Architect*, *The Security Auditor*, *The Pragmatist*.
2. **Build the Consensus Map**:
   - **Consensus (7–10 / 10 Agree)**: Safe Bets → Auto-approved into plan.
   - **Divergence (4–6 / 10 Agree)**: Genuine Trade-offs → Presented to human for final decision.
   - **Outliers (1–2 / 10 Agree)**: Wild Cards → Investigated for creative merit or discarded as hallucinations.
3. **ADR Persistence**: The final outcome is recorded in `docs/decisions/` as a MADR-compliant Architecture Decision Record.

---

## 7. Prompt Refinement & Optimization Engine

Transforms informal or messy user prompts into production-grade specifications (`playbooks/prompt-refinement.md`):
1. **Intent Extraction**: Isolates core functional goals.
2. **Context Enrichment**: Injects tech stack (`docs/conventions.md`) and architecture (`docs/architecture.md`).
3. **Edge Case & Security Synthesis**: Derives loading states, debounce delays, empty states, XSS sanitization, and error boundaries.
4. **Acceptance Criteria**: Formats testable checklist in `docs/task-state.md`.

---

## 8. Autonomous Codebase Discovery & Context Mapping Engine

When AI-OS is integrated into an existing project, agents execute the 6-stage exploration protocol (`playbooks/codebase-analysis.md`) to build full architectural context before modifying any files:
1. **Structure & Dependency Ingestion**: Parses root manifest files (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`) and directory trees to catalog runtime libraries and build tooling.
2. **Entry Points & Service Boundaries**: Identifies controllers, API routers, entry files (`main.ts`, `app.py`), and background workers.
3. **Data Flow & State Lifecycle**: Traces end-to-end user requests to database transactions, caching layers (Redis), and external APIs.
4. **Testing & Quality Baseline**: Evaluates test harnesses, linters, and baseline code health.
5. **Persistent Artifact Generation**: Synthesizes findings into `docs/architecture.md`, `docs/conventions.md`, and visual Mermaid diagrams in `docs/graph.md`.
6. **Task State Initialization**: Initializes `docs/task-state.md` with active project features, completed milestones, and pending technical debt.

---

## 9. Anti-Over-Engineering Complexity Tiers

| Tier | Task Type | Execution Strategy | Overhead |
| --- | --- | --- | :---: |
| **Tier 1** | Routine bug fix, CSS, small function | **Solo Model Fast-Track** | **Zero** |
| **Tier 2** | Standard feature, new component | **1 Implementer + 1 Verification Check** | **Minimal** |
| **Tier 3** | Strategic architecture, cross-cutting system | **Stochastic Consensus + Multi-Agent MCP** | **Proportional** |

---

## 9. Automation & Tooling Suite

1. **One-Shot Project Scaffolding CLI**:
   - PowerShell: `.\scripts\init-project.ps1 -Name "app" -Stack "Next.js + Tailwind"`
   - Bash: `./scripts/init-project.sh "app" "Next.js + Tailwind"`
   - Clones template, configures stack, inits git, sets hooks, and commits baseline in 2 seconds.
2. **Autonomous Self-Healing Test Loop**:
   - Built into `prompts/implementer.md` and `playbooks/testing.md`.
   - On test failure: captures error trace → hypothesizes root cause → applies surgical fix → re-tests (up to 3 autonomous iterations).
3. **Prompt Caching Layout**:
   - Pinned immutable Level 1 rules at the top of files to trigger provider server-side caching (70–80% faster, 80% cheaper).
4. **Git Pre-Commit AI Guard**:
   - `templates/project/.githooks/pre-commit` scans staged diffs on every commit to block API keys, secrets, and private `.env` files.
5. **Federated Rule Synchronizer**:
   - `.\scripts\sync-rules.ps1` extracts `[UNIVERSAL]` rules learned in downstream projects and safely merges them into the master AI-OS repository.
6. **Slash Command Workflows**:
   - Pre-configured shortcuts: `/feature <idea>`, `/audit`, `/sync-state`, `/learn`.

---

## 10. Complete File Inventory

```
ai-operating-system/
├── AGENTS.md                  # Canonical master operating rules & learned rules
├── CLAUDE.md                  # Claude / Anthropic adapter
├── GEMINI.md                  # Gemini / Google adapter
├── CODEX.md                   # Codex / OpenAI adapter
├── principles.md              # 6 Non-negotiable principles
├── workflow.md                # 6-Stage delivery lifecycle
├── stack-preferences.md       # Technical defaults & preferences
├── docs/
│   ├── AI-OS-COMPLETE-SPECIFICATION.md # Master Technical Specification
│   ├── AI-OS-USER-GUIDE.md             # Master User Manual
│   └── decisions/
│       └── 001-ai-operating-system-architecture.md # Formal ADR 001
├── playbooks/
│   ├── new-project.md         # Project bootstrapping
│   ├── feature.md             # Feature delivery
│   ├── bug-fix.md             # Root-cause bug fixing
│   ├── codebase-analysis.md   # Safe exploration
│   ├── testing.md             # Falsification testing & self-healing
│   ├── review.md              # Independent review
│   ├── architecture-decisions.md # ADR authoring
│   ├── learning-loop.md       # Safe rule promotion
│   ├── prompt-refinement.md   # Prompt optimization
│   ├── multi-agent-orchestration.md # MCP manager-worker
│   └── stochastic-consensus.md # Multi-agent voting
├── prompts/                   # Multi-agent role definitions
│   ├── architect.md           # System design & trade-offs
│   ├── implementer.md         # Single-owner code implementation
│   ├── reviewer.md            # Independent inspection
│   ├── tester.md              # Falsification & verification
│   ├── researcher.md          # Codebase discovery
│   ├── security-reviewer.md   # Threat modeling & injection defense
│   └── data-ai-specialist.md  # AI/ML & prompt pipelines
├── scripts/
│   ├── init-project.ps1       # One-shot project initializer (PowerShell)
│   ├── init-project.sh        # One-shot project initializer (Bash)
│   └── sync-rules.ps1         # Federated global rule synchronizer
├── registry/
│   └── projects.md            # Private project index
└── templates/
    └── project/               # Downstream project starter kit
        ├── AGENTS.md, CLAUDE.md, GEMINI.md, CODEX.md
        ├── mcp.json           # MCP server configuration template
        ├── .githooks/pre-commit # Secret scanning guard
        ├── .claude/commands/  # Slash commands (/feature, /audit, /sync-state)
        ├── .ai/mistakes-candidates.md
        └── docs/ (architecture, conventions, lessons, task-state, decisions)
```
