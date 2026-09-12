# AI Operating System Instructions

## Purpose

Maintain this repository as a clear, portable operating system for AI-assisted software projects.

## Working rules

- Prefer short, specific, testable instructions over broad advice.
- Keep provider-neutral guidance in shared files. Put provider-specific details only in adapter files.
- Do not duplicate a rule across multiple files when one file can be referenced instead.
- Treat `templates/project/AGENTS.md` as the canonical per-project instruction source.
- Do not add secrets, tokens, private customer data, or private keys to this repository.
- Preserve a clear separation between current project facts, decisions, and unverified lessons.

## Learning loop

When an agent makes or discovers a mistake:

1. Record it first as a candidate in `.ai/mistakes-candidates.md` in the affected project.
2. Include the failure, cause, detection method, and a proposed prevention rule.
3. Promote it to `docs/lessons.md` only after it is verified or repeats.
4. Promote it to `AGENTS.md` only if it must apply to nearly every task.

Never silently add unverified claims to permanent instructions.

## Definition of done

- Requested work is implemented or the blocker is explicitly documented.
- Relevant tests, checks, or manual verification are completed.
- Material architectural decisions are captured as an ADR.
- Reusable verified lessons are documented concisely.
