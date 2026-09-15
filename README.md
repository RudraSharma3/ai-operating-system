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

## 🚀 How to Use AI-OS (Copy-Paste Quickstart)

Choose your scenario below:

---

### 📦 Case 1: Adding AI-OS to an EXISTING Project

If you already have a project folder (e.g. `my-existing-app`) and want to equip it with AI-OS:

#### Step 1: Copy AI-OS files into your project
Open your terminal and run the command for your OS:

**On Windows (PowerShell):**
```powershell
# Replace 'C:\path\to\your-project' with your actual project folder path:
$dest = "C:\path\to\your-project"
$src = "C:\Users\HP\OneDrive\Desktop\ai-operating-system\templates\project"
Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force
Copy-Item -Path "$src\.ai" -Destination $dest -Recurse -Force
Copy-Item -Path "$src\.claude" -Destination $dest -Recurse -Force
Copy-Item -Path "$src\.githooks" -Destination $dest -Recurse -Force
```

**On Windows (Command Prompt / CMD):**
```cmd
xcopy /E /I /Y "C:\Users\HP\OneDrive\Desktop\ai-operating-system\templates\project\*" "C:\path\to\your-project\"
```

**On macOS / Linux (Terminal):**
```bash
cp -r /path/to/ai-operating-system/templates/project/. /path/to/your-project/
```

#### Step 2: Open your project in your AI IDE
Open your project folder in **Antigravity**, **Cursor**, **Claude Code**, or **VS Code**.

#### Step 3: Copy-paste this Kickoff Prompt into your AI Chat:
```markdown
Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze this repository. 
Please map our existing codebase and update docs/architecture.md, docs/conventions.md, and docs/graph.md with our current components, stack, and data flow.
```

---

### ✨ Case 2: Starting a BRAND NEW Project from Scratch

If you want to create a brand new project in 2 seconds:

#### Step 1: Run the 1-Shot Scaffolding Command

**On Windows (PowerShell):**
```powershell
powershell -File "C:\Users\HP\OneDrive\Desktop\ai-operating-system\scripts\init-project.ps1" -Name "my-new-app" -Stack "Next.js + Tailwind + Supabase"
```

**On macOS / Linux (Bash):**
```bash
./scripts/init-project.sh "my-new-app" "Next.js + Tailwind + Supabase"
```

#### Step 2: Open the newly created folder in your AI IDE

#### Step 3: Copy-paste your prompt in chat:
```markdown
I want to build my-new-app using Next.js, Tailwind, and Supabase. Please review docs/architecture.md and start Phase 1.
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
- **Visual Dependency Graph & Blast Radius Mapping**: Visual Mermaid wiring diagrams in `docs/graph.md` for safe refactoring.
- **Token Optimization & Prompt Caching**: Pinned static rule prefix layout cutting latency by 5x and token costs by up to 90%.
- **Autonomous Self-Healing Test Loop**: Agents auto-remediate syntax/test failures up to 3 iterations before escalating.
- **Pre-Commit AI Guard**: Automated git hook blocking secret leaks and verifying task state hygiene.
- **Federated Global Learning**: CLI tool syncing universal rules learned across projects back to the master repository.

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
