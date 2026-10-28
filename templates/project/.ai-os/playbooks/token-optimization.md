# Token Optimization, Context Architecture & Model Routing Playbook

This playbook defines the context efficiency, token compression defense, and cost-reduction architecture implemented across the AI Operating System.

---

## 🏔️ 1. The Iceberg Context Technique

AI models perform best with lean, focused context. AI-OS divides all repository information using the **10/90 Iceberg Model**:

```
                       ▲
                      / \
                     /   \
  ABOVE WATER       / 10% \    IN IMMEDIATE CONTEXT:
  (Always Hot)     /       \   • AGENTS.md & Provider Adapters
  ─────────────────────────────────────────────────────────────────
  BELOW WATER      \       /   ACCESSIBLE ON-DEMAND VIA TOOLS:
  (On-Demand)       \ 90% /    • Full Codebase (via Grep / Glob)
                     \   /     • Specific File Slices (via Targeted Read)
                      \ /      • Skills & Playbooks Library (Auto-Matched)
                       ▼       • Git History & Deep Test Traces
```

### The Golden Rule:
> **Only surface what matters NOW.** Never dump full 10,000-line files or all playbooks into the prompt at once.

---

## ⚡ 2. Naive vs. Strategic Context Loading

| Dimension | ❌ Naive Approach (What amateurs do) | ✅ Strategic AI-OS Approach (How senior devs build) |
|---|---|---|
| **Codebase Ingestion** | Dumps entire codebase into prompt (Context overflow). | Uses targeted `grep` and reads only relevant function slices. |
| **Playbooks & Skills** | Inlines all 13 playbooks into system prompt (~25k tokens). | Keeps base `AGENTS.md` lean (<1k tokens); loads playbooks on-demand. |
| **Tool Results** | Stores massive raw logs (10,000 lines of build output). | Summarizes tool results into actionable diffs and error traces. |
| **Result** | **Frequent context crashes, amnesia, high token costs.** | **3x–5x more effective, low latency, room to work.** |

---

## 🗜️ 3. Context Compression Defense (Disk-First Persistence)

When an AI conversation reaches ~80% context window capacity, AI systems trigger **Auto-Compaction** (compressing the chat history from ~50K tokens to ~15K tokens).

```
  FRESH CONVERSATION ──▶ AUTO-COMPACT TRIGGERED ──▶ COMPRESSION ──▶ COMPRESSED CONTEXT
  (50K tokens, full)     (80% full, pressure)      (LLM drops tool  (~15K tokens, loss
                                                    outputs & logs)  of exact errors)
```

### ⚠️ What Gets Lost During Compaction:
Exact compiler error messages, nuanced architectural reasoning, and intermediate step progress.

### 🛡️ The AI-OS Solution (Checkpoint Before Compaction):
AI-OS enforces **Disk-First Persistence**:
1. **Never keep state in memory only**: Immediately write all milestones, architectural findings, and task checklists to `docs/task-state.md` and `docs/architecture.md`.
2. When compaction triggers, the AI reads the disk files and resumes with **zero information loss**!

---

## 🎯 4. Model Routing: The 60 / 30 / 10 Rule

To minimize token consumption while maintaining implementation quality, AI-OS structures agent tasks into 3 complexity tiers (see [.ai/routing.md](../.ai/routing.md)):

```
                          ┌──▶ TIER 1: FAST / LOCAL WORKERS
                          │    Triage, classification, git pre-commit scans, mechanical checks
                          │
  AGENT ROUTER ───────────┼──▶ TIER 2: PRIMARY WORKHORSE
  (Complexity Gate)       │    Code generation, feature implementation, refactoring, test writing
                          │
                          └──▶ TIER 3: DEEP ARCHITECTURAL REASONING
                               Strategic system architecture, consensus ADRs, threat modeling
```

### Allocation Breakdown:
1. **Tier 1 Tasks (Fast & Cost-Efficient)**:
   - Git pre-commit secret scanning (`.githooks/pre-commit`)
   - Health doctor diagnostics (`scripts/doctor.ps1`, `scripts/doctor.sh`)
   - Simple file lookups, test execution, and triage
2. **Tier 2 Tasks (Core Workhorse)**:
   - 1-Implementer code generation (`playbooks/feature.md`)
   - Autonomous bug-fixing & test writing (`playbooks/bug-fix.md`)
3. **Tier 3 Tasks (Heavyweight Reasoning)**:
   - Strategic Stochastic Consensus (`playbooks/stochastic-consensus.md`)
   - Architecture Decision Records (`docs/decisions/`)
   - Threat modeling & multi-agent orchestrations

---

## 🚀 5. Prompt Caching (Prefix Stability)

Modern LLM providers (Anthropic, Gemini, OpenAI) offer **server-side prompt caching**:

- **Pinned Prefix (Top of Context - Static Cached)**:
  - Canonical Operating Rules (`AGENTS.md`)
  - Team Conventions (`docs/conventions.md`)
  - Static Architecture Tokens (`docs/architecture.md`)
- **Dynamic Suffix (Bottom of Context - Changing)**:
  - Active task status (`docs/task-state.md`) and latest user prompt

> ℹ️ **Design Target**: When provider prompt caching (e.g. Anthropic Prompt Caching or OpenAI Prefix Caching) is active, stable prefix layouts enable cache read pricing (typically up to 90% input discount per provider published rate cards, unbenchmarked).

