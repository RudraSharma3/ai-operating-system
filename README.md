# AI Operating System (AI-OS)
**Author:** Rudra Sharma  
**Version:** 2.0  
**Compatibility:** Google Antigravity, Cursor, Claude Code, GitHub Copilot, VS Code, OpenAI Codex / ChatGPT, Windsurf, and Local LLMs.

---

A reusable, versioned operating system for running reliable, context-aware, and self-improving AI coding agents across software engineering projects.

---

## ⚡ Quickstart: Install in 3 Commands

Install AI-OS into any existing or new project repository:

```bash
# 1. Clone AI-OS
git clone https://github.com/RudraSharma3/ai-operating-system.git
cd ai-operating-system

# 2. Install into your target project repository
bash scripts/install.sh /path/to/your/project
# (On Windows PowerShell: .\scripts\install.ps1 -TargetPath C:\path\to\your\project)

# 3. Verify health and armed protections
bash scripts/doctor.sh --ci /path/to/your/project
# (On Windows PowerShell: .\scripts\doctor.ps1 -Ci -TargetPath C:\path\to\your\project)
```

### What You Will See
- **`[ARMED]` Secret Guard**: Real-time pre-commit hook scanning added lines for multi-vendor API credentials (`sk-`, `sk-ant-`, `AKIA`, `ghp_`, `AIza`, `sk_live_`, DB URLs), private keys, and unencrypted `.env` files.
- **`[ARMED]` Dependency & Import Verifier**: Pre-commit validation ensuring every newly added dependency in manifests (`package.json`, `requirements*.txt`, `pyproject.toml`) is pre-approved in `.ai/deps-approved.txt`, and validating that static imports resolve without phantom packages.
- **`[ARMED]` 27-Point Doctor Diagnostic**: Automated health engine verifying hook paths, executable bits, CODEOWNERS coverage, pinned action SHAs, and rule budgets.
- **Evidence Runner**: Structured, tamper-evident execution proofs generated in `.ai/evidence/` via `scripts/ai-os-run` to substantiate task completion.

### What AI-OS Does and Does NOT Do
- ✅ **DOES Target Specific Coding-Agent Failure Modes**:
  - **Phantom Dependencies**: Reduces supply-chain risks (including slopsquatting) by blocking unvetted or hallucinated package additions.
  - **Undeclared Imports**: Flags code that imports libraries not declared in project manifests.
  - **Stale or Guessed APIs**: Discourages signature guessing from stale LLM weights by requiring local source inspection and runtime test verification.
  - **False Completion Claims**: Rejects unverified "all tests pass" assertions unless corroborated by an execution evidence record.
  - **Secret Leaks**: Intercepts credential exposure deterministically before commit.
- ❌ **Does NOT Do**:
  - Does **not** eliminate general conversational factual inaccuracies or reasoning errors in general chat answers.
  - Does **not** replace server-side CI/CD security boundaries or human CODEOWNER reviews.
  - Does **not** depend on external networks (core verification and diagnostic tools run 100% offline).

---

## ⚡ Quick Links & Documentation

- 📘 **[AI-OS Complete User Guide & Integration Manual (docs/AI-OS-USER-GUIDE.md)](docs/AI-OS-USER-GUIDE.md)**: **Start Here!** The official handbook for integrating AI-OS into your projects, GitHub baseline safety, personalized confirmation greeting, and the kickoff prompt.
- 🏛️ **[AI-OS Complete Technical Specification (docs/AI-OS-COMPLETE-SPECIFICATION.md)](docs/AI-OS-COMPLETE-SPECIFICATION.md)**: Deep systems architecture, mathematical consensus models, token caching layout, and multi-agent coordination contracts.
- 📊 **[Architecture & Operational Graph (docs/graph.md)](docs/graph.md)**: Visual Mermaid graphs and blast-radius dependency maps.

---

## 👁️ The Vision

Modern AI coding agents are powerful but often session-dependent. Without a standardized operational framework, every new chat session starts from zero: instructions drift, conventions are forgotten, mistakes repeat, and naive self-modification risks prompt injection or rule corruption.

The **AI Operating System** acts as a durable, self-correcting operational layer between software engineers and AI coding agents:

```
                  USER / ENGINEER
                        │
                        ▼
               AI Operating System
     (Canonical Rules, Roles, Playbooks, ADRs)
                        │
      ┌─────────────────┼─────────────────┐
      ▼                 ▼                 ▼
 Claude Adapter   Gemini Adapter   Codex Adapter
 (CLAUDE.md)       (GEMINI.md)       (CODEX.md)
      │                 │                 │
      └─────────────────┼─────────────────┘
                        ▼
             Consistent Project Execution
```

---

## 🚀 How to Integrate AI-OS into Your Project

Whether you have an **existing repository** or are starting a **brand new project**, AI-OS is designed to integrate cleanly without modifying your existing business logic.

👉 **To get started, follow the official step-by-step developer tutorial in [docs/AI-OS-USER-GUIDE.md](docs/AI-OS-USER-GUIDE.md).**

### What the User Guide covers:
1. **Quick Clone**: Getting the AI-OS repository locally (`git clone`).
2. **Safety First**: Creating a clean GitHub baseline on your existing project before integration.
3. **1-Step Integration**: Running the safe, non-destructive AI-OS installer for your OS.
4. **Automated Verification**: Diagnostic health check and personalized confirmation greeting.
5. **Kickoff Activation**: The exact initial prompt to paste into any AI IDE to index and graph your codebase.
6. **Daily Workflows**: Prompt auto-refinement, self-learning rules, and multi-agent coordination.

---

## 💡 Core Capabilities

- **Autonomous Codebase & Context Discovery**: Deep 6-stage exploration protocol that reads existing files, dependencies, routes, and database models to generate visual architecture graphs and persistent task state before writing code ([playbooks/codebase-analysis.md](playbooks/codebase-analysis.md)).
- **Canonical Rule Hierarchy**: Single source of truth in [AGENTS.md](AGENTS.md) ensuring consistent execution across Claude, Gemini, Codex, and other LLMs without duplicating rules.
- **Safe Self-Improvement Loop**: Prevents dangerous naive self-modification. Agents log unverified lessons as candidates (`.ai/mistakes-candidates.md`), pass a 10-point quality check, and promote only verified rules (`docs/lessons.md` / `AGENTS.md`).
- **Reverse Prompting & Prompt Contract Engine**: Automatically asks clarifying questions for ambiguous requests and transforms messy prompts into formal 4-part Prompt Contracts (`GOAL`, `CONSTRAINTS`, `FORMAT`, `FAILURE`) with forbidden-shortcut defense ([playbooks/prompt-refinement.md](playbooks/prompt-refinement.md)).
- **Proportional Effort Complexity Gate (Anti-Over-Engineering)**: Defaults to lightweight Solo Model execution for routine tasks; reserves Multi-Agent MCP and Stochastic Consensus strictly for complex systems ([.ai/routing.md](.ai/routing.md)).
- **Multi-Agent MCP Orchestration**: Manager-Worker coordination with contract-first isolation ([playbooks/multi-agent-orchestration.md](playbooks/multi-agent-orchestration.md)).
- **Deterministic Consensus for Strategic Decisions**: Multi-persona ideation paired with deterministic engineering verification matrices ([playbooks/stochastic-consensus.md](playbooks/stochastic-consensus.md)).
- **Visual Dependency Graph & Blast Radius Mapping**: Visual Mermaid wiring diagrams in [docs/graph.md](docs/graph.md) for safe refactoring.
- **Token Optimization & Prompt Caching**: Pinned static rule prefix layout maximizing provider server-side prompt cache hits (design target; see [playbooks/token-optimization.md](playbooks/token-optimization.md)).
- **Autonomous Self-Healing Test Loop**: Agents auto-remediate syntax/test failures up to 3 iterations before escalating ([playbooks/testing.md](playbooks/testing.md)).
- **Smart Pre-Commit Secret Armor & Actionable Remediation**: Real-time git hook that intercepts credential leaks, identifies offending files, and provides instant copy-paste resolution commands.
- **Federated Global Learning & Gate**: Mechanical 10-point gate creating auditable proposals in `proposals/` instead of silent direct mutations ([scripts/sync-rules.sh](scripts/sync-rules.sh)).
- **Replayable Evaluation & Anti-Gaming Benchmark Suite**: Replayable tasks (`evals/`) verifying bug fixes, features, prompt contracts, secret defense, and injection resilience with reference solutions, negative controls, and deterministic stub agents.

> **Measurement Status Note**: The comparative effect of AI-OS on live agent outcomes (speed, cost, token efficiency, and task pass rates across large model samples) is currently unmeasured pending standardized multi-agent headless benchmarks.

---

## ⚖️ How AI-OS Differs from Related Tools

| Dimension | GitHub Spec Kit | Native AGENTS.md in Tools | Gitleaks / Secret Scanners | Tool-Native Analytics | AI-OS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary Scope** | Specification scaffolding | Provider rule discovery | Pre-commit credential detection | Usage tracking & telemetry | End-to-end agent operational guardrails |
| **Gated Rule Learning** | ❌ No | ❌ No (static files) | ❌ No | ❌ No | ✅ 10-point mechanical gate + human approval (`sync-rules`) |
| **Cross-Tool Portability** | ⚠️ Partial (spec docs) | ⚠️ Tool-dependent | N/A | ❌ Proprietary | ✅ Unified adapters (Claude, Cursor, Gemini, Copilot, Codex) |
| **Cross-Tool Installer & Doctor** | ❌ No | ❌ No | ❌ Standalone tool | ❌ No | ✅ 27-check doctor & multi-repo installer/upgrader |
| **Dependency Approval Gate** | ❌ No | ❌ No | ❌ No | ❌ No | ✅ Pre-commit manifest & AST audit (`deps-approved.txt`) |
| **Evidence Ledger** | ❌ No | ❌ No | ❌ No | ⚠️ Proprietary telemetry | ✅ Local, offline run records (`.ai/evidence/`) |
| **Overlaps & Boundaries** | Overlaps in PRD/spec structure; AI-OS adds runtime hooks. | Overlaps in root `AGENTS.md` file format; AI-OS adds compilation & token budgeting. | Overlaps in secret regex detection; AI-OS integrates gitleaks where present with POSIX fallback. | Overlaps in tracking tasks; AI-OS operates locally without external SaaS logging. | Designed to augment existing linters, git hooks, and CI workflows. |

---

## 🗺️ Repository Structure

```
ai-operating-system/
├── AGENTS.md                  # Canonical agent operating rules & learned rules engine
├── CLAUDE.md                  # Claude / Anthropic adapter
├── GEMINI.md                  # Gemini / Google adapter
├── CODEX.md                   # Codex / OpenAI adapter
├── principles.md              # Non-negotiable engineering & agent principles
├── workflow.md                # Standard 6-stage delivery lifecycle
├── stack-preferences.md       # Technical defaults & preferences
├── docs/
│   ├── AI-OS-USER-GUIDE.md             # Complete user guide & manual (Start Here!)
│   ├── AI-OS-COMPLETE-SPECIFICATION.md # Complete technical specification
│   ├── architecture.md                 # System architecture doc
│   ├── conventions.md                  # Engineering & git conventions
│   ├── graph.md                        # Architecture & operational dependency graph
│   ├── lessons.md                      # Verified permanent lessons
│   ├── task-state.md                   # Active task progress tracker
│   └── decisions/
│       └── 001-ai-operating-system-architecture.md # Formal ADR 001
├── playbooks/ (14 Playbooks)  # new-project, feature, bug-fix, codebase-analysis,
│                              # testing, review, architecture-decisions,
│                              # learning-loop, prompt-refinement,
│                              # multi-agent-orchestration, stochastic-consensus,
│                              # token-optimization, interview, release-and-learn
├── prompts/ (7 Roles)         # architect, implementer, reviewer, tester,
│                              # researcher, security-reviewer, data-ai-specialist
├── scripts/
│   ├── install.ps1            # Project integrator & doctor installer (PowerShell)
│   ├── install.sh             # Project integrator & doctor installer (Bash)
│   ├── init-project.ps1       # One-shot project initializer (PowerShell)
│   ├── init-project.sh        # One-shot project initializer (Bash)
│   ├── sync-rules.ps1         # Federated global rule synchronizer
│   ├── doctor.ps1             # Diagnostic health check (PowerShell)
│   └── doctor.sh              # Diagnostic health check (Bash)
├── registry/
│   └── projects.md            # Index of downstream projects
└── templates/
    └── project/               # Project starter kit for new repositories
        ├── .ai/mistakes-candidates.md # Candidate lessons log
        ├── .githooks/pre-commit       # Secret scanning guard
        ├── .claude/commands/          # Slash commands (/feature, /audit, /sync-state, /interview)
        ├── docs/ (architecture, conventions, graph, lessons, task-state, decisions)
        ├── mcp.json                   # MCP server configuration template
        ├── .gitignore                 # Starter gitignore
        ├── AGENTS.md                  # Canonical project instructions
        ├── CLAUDE.md                  # Claude adapter
        ├── GEMINI.md                  # Gemini adapter
        └── CODEX.md                   # Codex adapter
```

---

## ⚠️ Limits of the Eval Sandbox

The evaluation runner temporary directory isolates only the repository working directory. **It is not a security sandbox.**

Specifically:
- An agent executing commands can still read, modify, or delete any files accessible to the current operating system user (including the home directory, SSH keys, shell configuration, and credentials).
- The harness does not restrict or firewall outbound network access.
- Environment variable stripping removes common secret signatures from child processes, but does not provide OS-level or containerized isolation.

### Recommendations for Live Agent Execution
When testing untrusted or autonomous agent runs:
1. **Execute inside an isolated Container or VM**:
   Use Docker or a disposable VM to enforce true filesystem, user privilege, and network boundaries:
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
   Always configure the narrowest verified permission mode from [`docs/sources.md`](docs/sources.md) (e.g., `claude --permission-mode default -p` or `claude --allowedTools "Bash,Read,Edit" -p`). Documented dangerous flags (such as `--dangerously-skip-permissions`) should never be used on developer workstations.

---

## 👤 Author & Maintainer

**AI Operating System** is conceived, built, and maintained by **Rudra Sharma**.
Feel free to open issues, contribute playbooks, or share how AI-OS powers your agentic workflows!
