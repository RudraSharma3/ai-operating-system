# AI Operating System: Architecture & Operational Graph

This graph maps the structural components, execution lifecycle, and cross-cutting subsystems of the **AI Operating System**.

---

## 1. High-Level System Architecture Graph

```mermaid
graph TD
    User([User / Engineer]) --> InlinePrompt[Level 4: Inline Prompt]
    
    subgraph AI_OS [AI Operating System Operational Layer]
        Canonical[Level 1: Canonical AGENTS.md]
        Adapters[Provider Adapters: CLAUDE.md / GEMINI.md / CODEX.md]
        Protocols[Level 3: Playbooks & Role Prompts]
        Refiner[Prompt Refinement & Optimization Engine]
        Gate[Proportional Effort Complexity Gate]
        RulesEngine[Safe Self-Correcting Rules Engine]
    end
    
    subgraph Execution_Tiers [Execution Tiers]
        Tier1[Tier 1: Solo Model Fast-Track]
        Tier2[Tier 2: 1-Implementer + 1-Verifier]
        Tier3A[Tier 3: Stochastic Consensus]
        Tier3B[Tier 3: Multi-Agent MCP Orchestration]
    end
    
    subgraph Downstream_Project [Target Project Repository]
        ProjectInstructions[Level 2: Project AGENTS.md]
        Docs[docs/ architecture, graph, task-state, decisions]
        SrcCode[Source Code & Tests]
    end
    
    InlinePrompt --> Refiner
    Refiner --> Gate
    Canonical --> Adapters
    Adapters --> ProjectInstructions
    
    Gate -->|Routine Task| Tier1
    Gate -->|Standard Feature| Tier2
    Gate -->|Strategic Crossroads| Tier3A
    Gate -->|Decoupled Fullstack| Tier3B
    
    Tier1 --> SrcCode
    Tier2 --> SrcCode
    Tier3A --> Docs
    Tier3B --> SrcCode
    
    SrcCode -->|Feedback / Correction| RulesEngine
    RulesEngine -->|Learned Rule| ProjectInstructions
```

---

## 2. Multi-Agent MCP Orchestration Graph

```mermaid
graph TD
    TaskInput[Optimized Feature Task] --> Manager[Manager: Claude Planner & Reasoner]
    
    Manager --> Contract[Contract-First Specification in docs/architecture.md]
    
    Contract --> W1[Worker 1: Gemini UI Specialist]
    Contract --> W2[Worker 2: Codex Backend API Specialist]
    Contract --> W3[Worker 3: Codex Test & Falsification Specialist]
    
    W1 --> UI_Files[Frontend Files: src/components/]
    W2 --> API_Files[Backend Files: src/api/]
    W3 --> Test_Files[Test Files: tests/]
    
    UI_Files --> Collector[Manager Validation & Integration Check]
    API_Files --> Collector
    Test_Files --> Collector
    
    Collector --> TestSuite{Automated Tests Pass?}
    TestSuite -->|Yes| Merge[Merge & Commit Changes]
    TestSuite -->|No| SelfHealing[Autonomous Self-Healing Fix Loop]
    SelfHealing --> TestSuite
```

---

## 3. Stochastic Consensus Decision Graph

```mermaid
graph TD
    DecisionTrigger[Architectural Decision Needed] --> Swarm[Spawn 3-5 Diverse Personas]
    
    Swarm --> P1[Minimalist Persona]
    Swarm --> P2[Scalability Architect]
    Swarm --> P3[Security & Reliability Auditor]
    Swarm --> P4[DX & Pragmatist]
    
    P1 --> VoteAggregator[Consensus Map Aggregator]
    P2 --> VoteAggregator
    P3 --> VoteAggregator
    P4 --> VoteAggregator
    
    VoteAggregator --> SafeBets[Consensus 7-10: Safe Bets ──▶ Auto-Approve]
    VoteAggregator --> Tradeoffs[Divergence 4-6: Trade-offs ──▶ User Decides]
    VoteAggregator --> Outliers[Outlier 1-2: Wild Cards ──▶ Experiment/Discard]
    
    SafeBets --> ADR[Record MADR in docs/decisions/]
    Tradeoffs --> ADR
    Outliers --> ADR
```

---

## 4. Subsystem & File Dependency Matrix

| AI-OS Subsystem | File References | Primary Role | Downstream Artifact |
| --- | --- | --- | --- |
| **Canonical Rules Engine** | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `CODEX.md` | Single source of truth | `<project>/AGENTS.md` |
| **Prompt Refinement** | `playbooks/prompt-refinement.md` | Upgrades raw messy prompts | `<project>/docs/task-state.md` |
| **Multi-Agent MCP** | `playbooks/multi-agent-orchestration.md` | Coordinates parallel workers | `<project>/mcp.json` |
| **Stochastic Consensus** | `playbooks/stochastic-consensus.md` | Eliminates hallucinations | `<project>/docs/decisions/` |
| **Token Optimization** | `playbooks/token-optimization.md` | Prompt caching & lean context | 5x faster generation |
| **Scaffolding CLI** | `scripts/init-project.ps1`, `scripts/init-project.sh` | One-shot setup in 2s | New project workspace |
| **Federated Learning** | `scripts/sync-rules.ps1` | Propagates universal rules | Master `AGENTS.md` |
| **Pre-Commit Guard** | `templates/project/.githooks/pre-commit` | Blocks secret leaks | Git commit safety |
