# AI Operating System Verified Lessons

Only verified, high-durability lessons learned while developing the AI Operating System are recorded here.

---

| Date | Category | Scope | Lesson | Evidence / Incident | Prevention Rule | Superseded By |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-14 | [PROCESS] | UNIVERSAL | Always verify code and files against current repo state rather than assumptions | System boundary discovery | Rule 1.1 & 1.3 in `AGENTS.md` | - |
| 2026-09-14 | [SECURITY] | UNIVERSAL | Never store secrets, tokens, or credentials in prompt rules or markdown | Credential leak prevention | Rule 1.2 in `AGENTS.md` | - |
| 2026-09-14 | [TOOL] | REPOSITORY | Use string concatenation for complex pipeline formatting in PowerShell scripts | `doctor.ps1` parser fix | Verified in `scripts/doctor.ps1` | - |
