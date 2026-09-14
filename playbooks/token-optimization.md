# Token Optimization & Prompt Caching Playbook

This playbook defines the token reduction, prompt caching, and context efficiency architecture implemented across the AI Operating System.

---

## 1. The 4 Token Reduction Pillars

```
┌────────────────────────────────────────────────────────────────────────┐
│ 1. PROMPT CACHING (Prefix-Stable Layout)                               │
│    Static rules placed at the top ──▶ 90% cost cut, 5x faster latency. │
├────────────────────────────────────────────────────────────────────────┤
│ 2. LEAN BASE CONTEXT (On-Demand Loading)                               │
│    Load playbooks/roles on-demand only when matched. Never inlined.    │
├────────────────────────────────────────────────────────────────────────┤
│ 3. PROPORTIONAL EFFORT (Solo Model Fast-Track)                         │
│    Block multi-agent spawning on routine tasks (saves 3x-5x tokens).   │
├────────────────────────────────────────────────────────────────────────┤
│ 4. ADAPTIVE CONTEXT PRUNING & CONCISE OUTPUTS                          │
│    Surgical diffs, focused file reads, zero conversational fluff.      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prompt Caching Architecture (Prefix Stability)

Modern LLMs (Anthropic Claude 3.5/3.7, Google Gemini 1.5/2.0, OpenAI GPT-4o) automatically cache the prefix of your prompt if it matches previous requests.

### File Ordering Strategy:
1. **Top of Context (100% Cached Prefix)**:
   - Level 1 Global Rules (`AGENTS.md`)
   - Non-negotiable security boundaries
   - Coding conventions (`docs/conventions.md`)
2. **Middle of Context**:
   - Project architecture (`docs/architecture.md`)
   - Matched playbook for the active task
3. **Bottom of Context (Dynamic / Changing)**:
   - `docs/task-state.md` (Active progress)
   - Current git diff and latest user prompt

> [!TIP]
> **Impact**: Because the top 80% of context never changes between turns, providers cache it in memory. This reduces per-turn input token costs by **up to 90%** and reduces latency from ~8s to **under 2s**.

---

## 3. On-Demand vs. Inlined Loading

- **Anti-Pattern (Token Waste)**: Pasting all 11 playbooks and 7 role prompts into the system prompt (~20,000 tokens on every turn).
- **AI-OS Standard (Lean Loading)**: The base `AGENTS.md` is kept under **1,000 tokens**. The agent reads specific playbooks (`playbooks/testing.md`, `playbooks/review.md`) **only when executing that specific task**.

---

## 4. Output Token Optimization (Surgical Diffs)

When generating code responses, agents must:
1. **Avoid Rewriting Full Files**: Use targeted line replacements and diff blocks instead of printing 800 lines of existing code.
2. **Keep Explanations Concise**: Report what was changed, commands run, and verification results without repeating documentation text.
