# Stack Preferences

Record engineering defaults and preferred tools here. Preferences provide context for agent design decisions but do not override project-specific requirements or explicit user instructions.

---

## Technical Defaults

- **Version Control**: Git with focused, descriptive commits, atomic branches, and clean diffs.
- **Documentation**: Markdown as first-class project documentation co-located with code; decisions documented as Architecture Decision Records (MADR format).
- **Agent Roles**: Single-owner implementation; independent reviewers, testers, and architects for material changes.
- **Instruction Model**: Provider-agnostic canonical rules in `AGENTS.md` with thin adapters (`CLAUDE.md`, `GEMINI.md`, `CODEX.md`).
- **Learning & Memory**: Safe candidate logging (`.ai/mistakes-candidates.md`) and verified promotion (`docs/lessons.md`); no naive autonomous file rewriting.
- **Testing & Verification**: Automated unit/integration tests, type checks, and static analysis prioritized before claiming task completion.
