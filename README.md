# AI Operating System

A reusable, versioned operating system for running reliable, context-aware, and self-improving AI coding agents across software engineering projects.

---

## The Vision

Modern AI coding agents are powerful but often session-dependent. Without an operational framework, each session starts from zero: instructions drift, conventions are forgotten, mistakes repeat, and naive self-modification risks prompt injection or rule corruption.

The **AI Operating System** acts as a durable operational layer between engineers and AI agents:

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

## 📚 Essential Documentation

- **[AI-OS Complete Technical Specification](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/docs/AI-OS-COMPLETE-SPECIFICATION.md)**: Deep technical architecture, mathematical consensus mapping, 4-level context hierarchy, and complete systems design.
- **[AI-OS Complete User Guide](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/docs/AI-OS-USER-GUIDE.md)**: Step-by-step handbook, daily workflow tutorials, prompt refinement examples, multi-agent recipes, and cheat sheets.

---

## Core Capabilities

- **Canonical Rule Hierarchy**: Single source of truth in [AGENTS.md](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/AGENTS.md) ensuring consistent execution across Claude, Gemini, Codex, and other LLMs without duplicating rules.
- **Safe Self-Improvement Loop**: Prevents dangerous naive self-modification. Agents log unverified lessons as candidates (`.ai/mistakes-candidates.md`), pass a 10-point quality check, and promote only verified rules (`docs/lessons.md` / `AGENTS.md`).
- **Prompt Auto-Refinement Engine**: Automatically transforms messy, conversational user prompts into rigorous engineering specifications with edge cases and security checks ([playbooks/prompt-refinement.md](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/playbooks/prompt-refinement.md)).
- **Proportional Effort Complexity Gate (Anti-Over-Engineering)**: Defaults to lightweight Solo Model execution for 95% of routine tasks; reserves Multi-Agent MCP and Stochastic Consensus strictly for complex systems.
- **Multi-Agent MCP Orchestration**: Manager-Worker coordination with contract-first isolation ([playbooks/multi-agent-orchestration.md](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/playbooks/multi-agent-orchestration.md)).
- **Stochastic Consensus for Strategic Decisions**: Multi-persona ideation and voting mapped to safe bets vs. human judgment calls ([playbooks/stochastic-consensus.md](file:///C:/Users/HP/OneDrive/Desktop/ai-operating-system/playbooks/stochastic-consensus.md)).
- **Autonomous Self-Healing Test Loop**: Agents auto-remediate syntax/test failures up to 3 iterations before escalating.
- **Pre-Commit AI Guard**: Automated git hook blocking secret leaks and verifying task state hygiene.
- **Federated Global Learning**: CLI tool syncing universal rules learned across projects back to the master repository.

---

## Quick Start: Scaffolding a New Project in 2 Seconds

**On Windows (PowerShell):**
```powershell
.\scripts\init-project.ps1 -Name "my-app" -Stack "Next.js + Tailwind + Supabase"
```

**On macOS / Linux (Bash):**
```bash
./scripts/init-project.sh "my-app" "Next.js + Tailwind + Supabase"
```

Then open `my-app` in your AI IDE and prompt:
> *"I want to build my-app using Next.js, Tailwind, and Supabase."*

---

## Repository Map

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
│   ├── AI-OS-COMPLETE-SPECIFICATION.md # Complete technical specification
│   ├── AI-OS-USER-GUIDE.md             # Complete user guide & manual
│   └── decisions/
│       └── 001-ai-operating-system-architecture.md # Formal ADR 001
├── playbooks/                 # Step-by-step repeatable work procedures
│   ├── new-project.md         # Bootstrapping new repositories
│   ├── feature.md             # Feature implementation lifecycle
│   ├── bug-fix.md             # Root-cause analysis & minimal bug fixing
│   ├── codebase-analysis.md   # Safe codebase exploration and mapping
│   ├── testing.md             # Change falsification & self-healing test loop
│   ├── review.md              # Independent code & architecture review
│   ├── architecture-decisions.md # Trade-off evaluation & ADR creation
│   ├── learning-loop.md       # Candidate logging, evaluation, & promotion
│   ├── prompt-refinement.md   # Auto-refinement of messy prompts
│   ├── multi-agent-orchestration.md # Manager-worker MCP protocol
│   ├── stochastic-consensus.md # Multi-persona consensus mapping
│   └── token-optimization.md  # Prompt caching & token reduction architecture
├── prompts/                   # Multi-agent role prompts
│   ├── architect.md           # System design & trade-off analysis
│   ├── implementer.md         # Single-owner code implementation with self-healing
│   ├── reviewer.md            # Independent inspection & review
│   ├── tester.md              # Test execution & falsification
│   ├── researcher.md          # Investigation & codebase discovery
│   ├── security-reviewer.md   # Threat modeling & injection defense
│   └── data-ai-specialist.md  # AI/ML integration & prompt pipelines
├── scripts/
│   ├── init-project.ps1       # One-shot project initializer (PowerShell)
│   ├── init-project.sh        # One-shot project initializer (Bash)
│   └── sync-rules.ps1         # Federated global rule synchronizer
├── registry/
│   └── projects.md            # Index of downstream projects
└── templates/
    └── project/               # Project starter kit for new repositories
        ├── .ai/mistakes-candidates.md # Candidate lessons log
        ├── .githooks/pre-commit       # Secret scanning guard
        ├── .claude/commands/          # Slash command definitions (/feature, /audit, /sync-state)
        ├── docs/ (architecture, conventions, lessons, task-state, decisions)
        ├── mcp.json                   # MCP server configuration template
        ├── .gitignore                 # Starter gitignore
        ├── AGENTS.md                  # Canonical project instructions
        ├── CLAUDE.md                  # Claude adapter
        ├── GEMINI.md                  # Gemini adapter
        └── CODEX.md                   # Codex adapter
```
