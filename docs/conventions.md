# AI Operating System Engineering Conventions

This document establishes standards, formatting styles, git workflows, and testing patterns for contributing to the AI Operating System.

---

## 1. File Organization & Naming
- Playbooks live in `playbooks/<kebab-case-name>.md`.
- Multi-agent role prompts live in `prompts/<role-name>.md`.
- Core documentation lives in `docs/`.
- Automation scripts live in `scripts/` (with both `.ps1` and `.sh` equivalents).

## 2. Git & Version Control
- Commits follow Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- All staged commits pass `scripts/doctor.ps1` and `.githooks/pre-commit` secret scanning.

## 3. Rule Quality & Formatting
- All rules added to `AGENTS.md` must follow: `N. [CATEGORY] Rule description — rationale.`
- Allowed categories: `[STYLE]`, `[CODE]`, `[ARCH]`, `[TOOL]`, `[PROCESS]`, `[DATA]`, `[UX]`, `[SECURITY]`, `[TEST]`, `[OTHER]`.
