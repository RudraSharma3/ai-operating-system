# Prompt Refinement, Reverse Prompting & Prompt Contract Playbook

Follow this playbook whenever the user provides an informal, brief, ambiguous, or messy prompt. The AI Operating System automatically transforms conversational input into a rigorous, production-grade **Prompt Contract** (GOAL, CONSTRAINTS, FORMAT, FAILURE) and applies **Reverse Prompting** to eliminate blind assumptions before modifying code.

---

## 🔄 The Complete Prompt Optimization Lifecycle

```
                     MESSY / AMBIGUOUS USER PROMPT
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  PHASE 1: REVERSE PROMPTING (Clarification Gate)                │
  │  • Detect ambiguities & implicit assumptions                    │
  │  • Ask 3–5 sharp clarifying questions (with recommendations)    │
  └────────────────────────────────┬────────────────────────────────┘
                                   │ User Answers / Clarifies
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  PHASE 2: PROMPT CONTRACT FORMULATION                           │
  │  • 🎯 GOAL:        Quantifiable success & concrete deliverable   │
  │  • ⛓️ CONSTRAINTS: Tech stack, performance limits, typing rules │
  │  • 📁 FORMAT:      Exact file paths, component structure        │
  │  • ❌ FAILURE:     Forbidden shortcuts & mandatory edge cases   │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  PHASE 3: TRANSPARENT CONTRACT PRESENTATION                     │
  │  • Display structured Prompt Contract to user in chat           │
  │  • Record active contract into docs/task-state.md               │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  PHASE 4: SURGICAL EXECUTION & ANTI-SHORTCUT VERIFICATION       │
  │  • Implement against contract as hard engineering spec          │
  │  • Verify every single FAILURE condition is avoided             │
  └─────────────────────────────────────────────────────────────────┘
```

---

## 1. Phase 1: Reverse Prompting (The Clarification Gate)

Whenever a task has multiple viable architectures or missing requirements, **never silently guess**. Execute Reverse Prompting:

### When to Trigger:
- Core data models, auth boundaries, or external APIs are unspecified.
- User says: *"Build a notification system"*, *"Add checkout flow"*, *"Make an analytics dashboard"*.
- There are multiple competing technical trade-offs.

### Protocol:
1. Identify up to **3–5 high-impact questions** (Target user workflow, data storage, integration API, error behavior).
2. Format questions with recommended defaults:
   - *Option A (Recommended): Next.js Server Actions with optimistic UI updates.*
   - *Option B: REST API route with client-side SWR fetching.*
3. Once the user selects/confirms, proceed immediately to Phase 2.

---

## 2. Phase 2: The 4-Section Prompt Contract

Synthesize the request, repository architecture (`docs/architecture.md`), and conventions (`docs/conventions.md`) into a formal contract:

```markdown
## 📋 Prompt Contract: [Feature / Task Name]

### 🎯 GOAL:
[Quantifiable success metric. Include concrete deliverable. "Working X" is not a goal. "X that handles Y at Z performance" is.]

### ⛓️ CONSTRAINTS:
- [Hard limit 1 - language, dependencies, compatibility from docs/architecture.md]
- [Hard limit 2 - performance, size, complexity ceiling]
- [Hard limit 3 - integration requirements, existing patterns from docs/conventions.md]
- [Hard limit 4 - learned user preferences from AGENTS.md ## Learned Rules]

### 📁 FORMAT:
- [Exact file paths to create or modify]
- [What each file contains and component responsibilities]
- [Typing, tests, and CSS variable styling tokens]

### ❌ FAILURE (Any of these = Task Incomplete & Rejected):
- [Specific lazy shortcut the AI would be tempted to take, e.g. leaving // TODO]
- [Edge case that must be handled and not skipped, e.g. empty states, null safety]
- [Integration point that must actually work, not just compile]
- [The "technically works but crashes in production" outcome that must be avoided]
```

---

## 3. Phase 3: Present Contract & Save to Task State

1. **In Chat**: Output the structured Prompt Contract block before writing code so the user sees the restructured specification.
2. **In Repository**: Append the active contract and acceptance criteria checklist `[ ]` into `docs/task-state.md`.

---

## 4. Phase 4: Execute & Verify Against FAILURE Checklist

1. **Implement as a Strict Specification**: Treat the contract as an engineering blueprint, not an optional suggestion.
2. **Anti-Shortcut Verification**: Before declaring success, systematically review the **`FAILURE`** section:
   - [ ] Are all `// TODO` or placeholder mocks eliminated?
   - [ ] Are loading, error, and empty states rendered?
   - [ ] Is input sanitized against injection/XSS?
   - [ ] Are all affected tests passing?
3. **Update Task State**: Check off completed items in `docs/task-state.md` and report verified progress.
