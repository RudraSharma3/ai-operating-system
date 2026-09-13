# Prompt Refinement & Optimization Playbook

Follow this playbook whenever the user provides an informal, brief, ambiguous, or messy prompt. The AI Operating System automatically transforms conversational input into a rigorous, production-grade engineering specification before modifying code.

---

## The Prompt Optimization Flow

```
  MESSY / BRIEF USER PROMPT
  ("make a search bar for users and make it look clean")
              │
              ▼
  ┌────────────────────────────────────────────────────────┐
  │  PROMPT REFINEMENT ENGINE                              │
  │  1. Intent Extraction (Core Objective & Constraints)   │
  │  2. Context Enrichment (Stack, Architecture, Rules)    │
  │  3. Edge Case & Security Derivation (Errors, XSS, DB)  │
  │  4. Acceptance Criteria & Test Matrix Formulation      │
  └────────────────────────────────────────────────────────┘
              │
              ▼
  OPTIMIZED ENGINEERING SPECIFICATION
  (Documented in docs/task-state.md → Executed Surgically)
```

---

## 1. Step-by-Step Optimization Protocol

### Step 1: Deconstruct Intent
Deconstruct the messy prompt into:
- **Primary Goal**: What single functional outcome must be achieved?
- **Implicit Needs**: What did the user assume (e.g. loading states, mobile responsiveness, error banners)?
- **Ambiguities**: What details need sensible default assumptions based on existing codebase patterns?

### Step 2: Context Enrichment
Enrich the prompt using repository facts:
- Check `docs/architecture.md` for existing components, endpoints, and database models.
- Check `docs/conventions.md` for naming, styling (e.g., Tailwind, CSS modules), and state management.
- Check `AGENTS.md` `## Learned Rules` for user-specific habits and past corrections.

### Step 3: Edge Case & Security Synthesis
Automatically derive non-obvious requirements:
- **UI/UX**: Loading skeletons, empty states, debounce delays, disabled button states during network calls.
- **Edge Cases**: Null/empty inputs, maximum length limits, special characters, concurrent requests.
- **Security & Data**: Input sanitization, authorization checks, SQL/command injection defense, rate limiting.

### Step 4: Formulate Acceptance Criteria
Synthesize the refined prompt into structured acceptance criteria in `docs/task-state.md`:
```markdown
## Goal
Implement a debounce-enabled User Search Bar with real-time filtering and loading indicators.

## Acceptance Criteria
- [ ] UI: Search input with search icon, clear button, and accessible loading spinner.
- [ ] Performance: 300ms debounce on input keystrokes to minimize backend queries.
- [ ] Edge Cases: Displays "No users found" for 0 matches; handles network errors gracefully.
- [ ] Security: Sanitizes query input against XSS before DOM rendering.
- [ ] Tests: Unit test for debounce logic and empty state rendering.
```

### Step 5: Execute & Report
Execute the refined specification directly, producing robust, production-grade code rather than a quick hack.
