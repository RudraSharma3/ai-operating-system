# Stochastic Multi-Agent Consensus Playbook

Follow this playbook when facing strategic, high-uncertainty architectural choices, technology evaluations, or open-ended ideation. This technique uses multi-perspective sampling to identify genuine trade-offs and rigorously validates candidate solutions with deterministic engineering verification.

---

## 1. Complexity Gate (Anti-Overkill Rule)

> [!CAUTION]
> **Never Over-Engineer Simple Tasks**:
> - **DO NOT** trigger Stochastic Consensus for routine coding, minor bug fixes, styling adjustments, or straightforward feature additions.
> - **DO** trigger Stochastic Consensus **ONLY** for:
>   1. Strategic architectural crossroads (e.g. choice of database engine, auth protocol, state synchronization architecture).
>   2. High-risk system trade-offs with conflicting constraints (e.g. latency vs. consistency, bundle size vs. runtime speed).
>   3. Explicit user requests for exploratory architecture ideation.

---

## 2. Deterministic Consensus Architecture

```
                  STRATEGIC PROBLEM
                          │
                          ▼
            [SPAWN 3 DIVERSE PERSPECTIVES]
     (Minimalist, Scalability Architect, Security Auditor)
                          │
                          ▼
              [EXTRACT CANDIDATE PROPOSALS]
                          │
                          ▼
        ┌───────────────────────────────────────────┐
        │ DETERMINISTIC VERIFICATION MATRIX (GATE)  │
        │ • Feasibility: Does candidate compile?    │
        │ • Static Check: Passes linter & types?    │
        │ • Constraint Test: Meets latency budget?  │
        │ • Complexity Score: Dependency count      │
        └─────────────────────┬─────────────────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
       [DETERMINISTIC WINNER]       [GENUINE TRADE-OFF]
       (Passes all benchmarks)      (Conflicting constraints)
               │                             │
               ▼                             ▼
       RECORD AS ADR IN              PRESENT TRADE-OFF
       docs/decisions/               TO USER WITH PROS/CONS
```

---

## 3. Step-by-Step Consensus Protocol

### Step 1: Formulate the Decision Prompt & Prompt Contract
Define the exact architectural question, system constraints, quantifiable latency/resource targets, and non-functional requirements.

### Step 2: Sample Diverse Personas (Maximum 3 Perspectives)
Run sampling across distinct engineering perspectives:
1. **The Minimalist**: "What is the simplest, lowest-dependency solution that satisfies all constraints?"
2. **The Scalability Architect**: "What solution handles 10x scale, concurrency, and volume best?"
3. **The Security & Reliability Specialist**: "Where are the attack vectors, failure cascades, and recovery boundaries?"

### Step 3: Run Deterministic Verification Matrix
Never decide a winner through subjective model voting or agreement counting. Evaluate each candidate against concrete, automated criteria:

| Evaluation Dimension | Verification Method | Pass / Fail Metric |
|----------------------|---------------------|-------------------|
| **Compilation & Syntax** | Language parser / compiler | Zero syntax errors |
| **Type Integrity** | TypeScript / type checker | Zero type errors |
| **Dependency Burden** | Manifest check | Minimum third-party packages |
| **Test Verification** | Targeted unit / integration tests | 100% pass rate |
| **Resource & Latency** | Benchmark / profiling script | Within Prompt Contract budget |

### Step 4: Present Trade-offs to User & Record ADR
1. Eliminate candidates that failed deterministic verification.
2. Present only the genuine trade-offs that require human business judgement.
3. Record the final agreed outcome as an Architecture Decision Record (`docs/decisions/NNN-<decision>.md`).
