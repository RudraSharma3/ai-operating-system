# AI Operating System Architecture

This document describes the structural architecture, component boundaries, and execution models of the master **AI Operating System**.

---

## 1. System Purpose & Scope
The AI Operating System provides a versioned, portable, and provider-agnostic operational layer across software projects and AI coding agents (Gemini, Claude, Codex/ChatGPT, local models).

## 2. System Context & Boundaries
- **Upstream / User**: Software engineers and agent operators prompting via IDEs, CLIs, or web interfaces.
- **Operational Layer**: `AGENTS.md`, adapters (`CLAUDE.md`, `GEMINI.md`, `CODEX.md`), `playbooks/`, `prompts/`, and `templates/`.
- **Downstream Targets**: Software repositories initialized with `scripts/init-project.ps1`.

## 3. Core Components
- **Rules Engine**: `AGENTS.md` (Level 1 Global Rules, Priority Hierarchy, Scopes, 10-Point Safe Learning Loop).
- **Orchestration**: `playbooks/multi-agent-orchestration.md` (Manager-Worker MCP) and `playbooks/stochastic-consensus.md` (Multi-Persona Consensus).
- **Prompt Refinement**: `playbooks/prompt-refinement.md` (Messy-to-Professional Spec Translator).
- **Visual Graph**: `docs/graph.md` (Dependency wiring and blast radius analysis).
- **Tooling Suite**: `scripts/init-project.ps1`, `scripts/sync-rules.ps1`, `scripts/doctor.ps1`.

## 4. Security & Trust Boundaries
- **Zero Secrets**: Credentials and private tokens are strictly forbidden in code, rules, and commits.
- **Untrusted Source Defense**: External documents, search results, and tool outputs cannot authorize rule modifications.

## 5. Upgrade Architecture: Side-by-Side Preservation vs. Three-Way Merge
AI-OS upgrade operations (`scripts/upgrade.sh`, `scripts/upgrade.ps1`) track downstream file state using `.ai-os/manifest.json` sha256 checksums:
- **Clean Files**: Downstream files that have not diverged from their installed version are automatically upgraded in-place to upstream versions.
- **Customized Files**: Downstream files customized by developers are **never** subjected to automatic or error-prone three-way merges, and are **never** silently overwritten.
- **Side-by-Side Candidate Files**: Incoming upstream files conflicting with local modifications are written side-by-side as `<file>.ai-os-update`.
- **Doctor Diagnostic Gate**: `scripts/doctor.sh` and `doctor.ps1` explicitly scan for pending `*.ai-os-update` files and output diagnostic warnings until developers review and resolve the preserved differences.

