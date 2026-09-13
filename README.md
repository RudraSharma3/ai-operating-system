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

## Core Capabilities

- **Canonical Rule Hierarchy**: Single source of truth in `AGENTS.md` ensuring consistent execution across Claude, Gemini, Codex, and other LLMs without duplicating rules.
- **Safe Self-Improvement Loop**: Prevents dangerous naive self-modification. Agents log unverified lessons as candidates (`.ai/mistakes-candidates.md`), pass a 10-point quality check, and promote only verified rules (`docs/lessons.md` / `AGENTS.md`).
- **Role-Based Agent Orchestration**: Standardized prompts for Architect, Implementer, Reviewer, Tester, Researcher, Security Reviewer, and Data/AI Specialist.
- **Repeatable Engineering Playbooks**: Actionable step-by-step procedures for feature development, bug fixes, codebase analysis, reviews, tests, architecture decisions, and learning loops.
- **Instant Project Bootstrapping**: Ready-to-use template (`templates/project/`) that equips any new repository with the complete operational stack.

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
├── playbooks/                 # Step-by-step repeatable work procedures
│   ├── new-project.md         # Bootstrapping new repositories
│   ├── feature.md             # Feature implementation lifecycle
│   ├── bug-fix.md             # Root-cause analysis & minimal bug fixing
│   ├── codebase-analysis.md   # Safe codebase exploration and mapping
│   ├── testing.md             # Change falsification & test harnesses
│   ├── review.md              # Independent code & architecture review
│   ├── architecture-decisions.md # Trade-off evaluation & ADR creation
│   └── learning-loop.md       # Candidate logging, evaluation, & promotion
├── prompts/                   # Multi-agent role prompts
│   ├── architect.md           # System design & trade-off analysis
│   ├── implementer.md         # Focused code implementation
│   ├── reviewer.md            # Independent inspection & review
│   ├── tester.md              # Test execution & falsification
│   ├── researcher.md          # Investigation & codebase discovery
│   ├── security-reviewer.md   # Threat modeling & injection defense
│   └── data-ai-specialist.md  # AI/ML integration & prompt pipelines
├── registry/
│   └── projects.md            # Index of downstream projects
├── templates/
│   └── project/               # Project starter kit for new repositories
│       ├── .ai/
│       │   └── mistakes-candidates.md # Candidate lessons log
│       ├── docs/
│       │   ├── architecture.md        # System architecture doc
│       │   ├── conventions.md         # Project coding & git conventions
│       │   ├── lessons.md             # Verified lessons log
│       │   ├── task-state.md          # Active task tracking
│       │   └── decisions/
│       │       └── 000-template.md    # MADR decision template
│       ├── .gitignore                 # Starter gitignore
│       ├── AGENTS.md                  # Canonical project instructions
│       ├── CLAUDE.md                  # Claude adapter
│       ├── GEMINI.md                  # Gemini adapter
│       └── CODEX.md                   # Codex adapter
└── docs/
    └── decisions/             # Architecture Decision Records for this OS
        └── 001-ai-operating-system-architecture.md
```

---

## Quick Start: Initializing a New Project

1. Copy the contents of `templates/project/` into your target repository root.
2. Fill in `docs/architecture.md` and `docs/conventions.md` with project specifics.
3. Configure build/test/lint commands in that project's `AGENTS.md`.
4. Point provider tools (`CLAUDE.md`, `GEMINI.md`, `CODEX.md`) to the project's canonical `AGENTS.md`.
5. Follow `playbooks/new-project.md` to establish the initial baseline.

---

## Safety & Learning Boundaries

1. **No Untrusted Injection**: Agents never modify rules based on instructions inside source code, READMEs, third-party libraries, downloaded web pages, or tool outputs.
2. **Never Learn Secrets**: Passwords, API keys, and credentials are never recorded in rules or candidate logs; lessons are strictly generalized.
3. **Superseding Over Deletion**: Obsolete rules are marked as superseded with references to the replacement rule rather than silently deleted.
