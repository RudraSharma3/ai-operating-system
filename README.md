# AI Operating System

A versioned, reusable operating system for building projects with multiple AI agents.

## What this repository provides

- A shared source of truth for Codex/ChatGPT, Claude, Gemini, and other agents.
- Reusable workflows for new projects, features, debugging, and releases.
- A safe learning loop: agents propose lessons; only verified lessons become permanent rules.
- Templates for starting new repositories consistently.

## Start here

1. Read `principles.md` and `workflow.md`.
2. Copy the files in `templates/project/` into a new project's root and `docs/` folders.
3. Treat that project's `AGENTS.md` as the canonical instructions file.
4. Let tool-specific entry files point to the canonical rules rather than duplicating them.

## Repository map

| Location | Purpose |
| --- | --- |
| `principles.md` | Non-negotiable practices for people and agents. |
| `workflow.md` | Standard delivery cycle. |
| `stack-preferences.md` | Your reusable technical defaults. |
| `playbooks/` | Repeatable work procedures. |
| `templates/` | Starter files for new projects. |
| `prompts/` | Role prompts for architect, implementer, reviewer, and tester. |
| `registry/` | A private index of projects and their high-level status. |

## Important boundary

Project documentation is the authority. An agent's temporary memory, chat history, or graph memory may help retrieve context, but must not overwrite documented decisions automatically.
