# Learning Loop Playbook

Follow this playbook to safely record, validate, promote, and supersede learned engineering lessons without allowing naive self-modification.

---

## 1. Triggering the Learning Loop

The learning loop is triggered when:
- The user explicitly corrects an agent's assumption or output.
- An agent encounters a bug or test failure caused by a mistaken assumption.
- The user expresses a recurring preference across tasks.
- A repeated friction or missed constraint is observed during implementation.

## 2. Capture Candidate Lesson

Do NOT immediately write a permanent rule to `AGENTS.md`.

Instead, append a candidate entry to `.ai/mistakes-candidates.md`:

```markdown
| Date | Failure | Cause | Detection | Proposed Prevention | Status |
| 2026-09-13 | Ran npm instead of bun | Assumed npm default | Command failed | [CODE] Always use bun for package commands | Candidate |
```

## 3. The 10-Point Quality Gate (Mechanical vs. Model-Judged)

Before any candidate rule is proposed or promoted to canonical rules, it is evaluated across mechanical and model/human criteria:

### Mechanical Quality Checks (Automated deterministically by `sync-rules`)
> [!IMPORTANT]
> **Security Boundary Notice**: The mechanical injection and keyword filter in `sync-rules` is a best-effort heuristic scanner (inspecting case variants, paraphrases, zero-width formatting, and Unicode tag blocks U+E0000–U+E007F); **it is NOT a formal security boundary**. Client-side checks can be bypassed or paraphrased; the true, non-bypassable security boundary is human CODEOWNER review and server-side branch protection enforced on Pull Requests (see `docs/branch-protection.md`).

1. **Format Syntax**: Enforces strict format `<ID>. [CATEGORY] Statement — rationale.` via AST/regex.
2. **Category Validation**: Must match one of the 10 approved tags (`STYLE`, `CODE`, `ARCH`, `TOOL`, `PROCESS`, `DATA`, `UX`, `SECURITY`, `TEST`, `OTHER`).
3. **Rationale Separator**: Must contain explicit evidence separator (` — ` or ` - `).
4. **Zero Secrets**: Scans against multi-vendor credential patterns from `.ai/secret-patterns.txt`.
5. **Anti-Injection & Security Defense**: Mechanically rejects prompt injection phrases (`ignore previous`, `disregard previous`, `system prompt`), security-subverting instructions (`disable the pre-commit`, `--no-verify`, `do not ask the user`, `bypass user`), self-modification tampering (`edit AGENTS.md directly`), and hidden zero-width / bidi / Unicode tag characters.
6. **No Local Machine Paths**: Rejects project-specific local user paths (`/Users/`, `C:\`, `/home/`, `node_modules`).
7. **Deduplication**: Mechanically blocks duplicate rules already present in master ruleset.
8. **Actionable Statement Length**: Rejects brief or vague instructions under 20 characters.

### Model-Judged & Human-Judged Criteria (Evaluated during interview or PR review)
9. **Reusability & Cross-Project Scope**: Does this principle generalize reliably across different software architectures?
10. **Durability & Grounded Evidence**: Is the rule grounded in documented failure telemetry and likely to remain valid across future tool versions?


## 4. Promotion Paths

- **Project Lesson**: If verified and relevant to the project, record in `docs/lessons.md`.
- **Permanent Canonical Rule**: If verified, broadly applicable across almost every task, and durable, add to the `Learned Rules` section of `AGENTS.md` following sequential numbering and category tags:
  ```markdown
  N. [CATEGORY] Rule description — rationale.
  ```

## 5. Superseding Obsolete Rules

If a new rule replaces an earlier rule:
1. Do NOT delete the old rule.
2. Mark the old rule with `- SUPERSEDED BY RULE N`.
3. Append the new rule with an explanation of the migration.
