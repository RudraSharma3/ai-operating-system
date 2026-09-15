# AI Operating System (AI-OS)
**Author:** Rudra Sharma  
**Version:** 2.0  
**Compatibility:** Google Antigravity, Cursor, Claude Code, GitHub Copilot, VS Code, OpenAI Codex / ChatGPT, Windsurf, and Local LLMs.

---

A reusable, versioned operating system for running reliable, context-aware, and self-improving AI coding agents across software engineering projects.

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
1. **Safety First**: Creating a clean GitHub baseline before integration.
2. **1-Step Integration**: Running the safe, non-destructive AI-OS installer for your OS.
3. **Automated Verification**: Diagnostic health check and personalized confirmation greeting.
4. **Kickoff Activation**: The exact initial prompt to paste into any AI IDE to index and graph your codebase.
5. **Daily Workflows**: Prompt auto-refinement, self-learning rules, and multi-agent coordination.

---

## 💡 Core Capabilities

- **Autonomous Codebase & Context Discovery**: Deep 6-stage exploration protocol that reads existing files, dependencies, routes, and database models to generate visual architecture graphs and persistent task state before writing code ([playbooks/codebase-analysis.md](playbooks/codebase-analysis.md)).
- **Canonical Rule Hierarchy**: Single source of truth in [AGENTS.md](AGENTS.md) ensuring consistent execution across Claude, Gemini, Codex, and other LLMs without duplicating rules.
- **Safe Self-Improvement Loop**: Prevents dangerous naive self-modification. Agents log unverified lessons as candidates (`.ai/mistakes-candidates.md`), pass a 10-point quality check, and promote only verified rules (`docs/lessons.md` / `AGENTS.md`).
- **Prompt Auto-Refinement Engine**: Automatically transforms messy, conversational user prompts into rigorous engineering specifications with edge cases and security checks ([playbooks/prompt-refinement.md](playbooks/prompt-refinement.md)).
- **Proportional Effort Complexity Gate (Anti-Over-Engineering)**: Defaults to lightweight Solo Model execution for 95% of routine tasks; reserves Multi-Agent MCP and Stochastic Consensus strictly for complex systems.
- **Multi-Agent MCP Orchestration**: Manager-Worker coordination with contract-first isolation ([playbooks/multi-agent-orchestration.md](playbooks/multi-agent-orchestration.md)).
- **Stochastic Consensus for Strategic Decisions**: Multi-persona ideation and voting mapped to safe bets vs. human judgment calls ([playbooks/stochastic-consensus.md](playbooks/stochastic-consensus.md)).
- **Visual Dependency Graph & Blast Radius Mapping**: Visual Mermaid wiring diagrams in [docs/graph.md](docs/graph.md) for safe refactoring.
- **Token Optimization & Prompt Caching**: Pinned static rule prefix layout cutting latency by 5x and token costs by up to 90% ([playbooks/token-optimization.md](playbooks/token-optimization.md)).
- **Autonomous Self-Healing Test Loop**: Agents auto-remediate syntax/test failures up to 3 iterations before escalating ([playbooks/testing.md](playbooks/testing.md)).
- **Pre-Commit AI Guard**: Automated git hook blocking secret leaks and verifying task state hygiene.
- **Federated Global Learning**: CLI tool syncing universal rules learned across projects back to the master repository.

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
├── playbooks/ (13 Playbooks)  # new-project, feature, bug-fix, codebase-analysis,
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

## 👤 Author & Maintainer

**AI Operating System** is conceived, built, and maintained by **Rudra Sharma**.
Feel free to open issues, contribute playbooks, or share how AI-OS powers your agentic workflows!
