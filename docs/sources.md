# External Documentation Sources & Verifications

This document records the official documentation URLs, retrieval dates, and verification statuses for external tool integrations and specifications.

---

## 1. AGENTS.md Multi-Tool Specification & Ecosystem Standard

- **Canonical Specification**: `https://agents.md`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Summary**: `AGENTS.md` is an open standard format defining repository context, build/test commands, and architectural constraints for autonomous AI coding agents across developer environments.

---

## 2. Cursor IDE AGENTS.md & Rules Integration

- **Official Source**: `https://cursor.com` and `https://docs.cursor.com/context/rules-for-ai`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Details**:
  - Cursor natively detects and parses `AGENTS.md` at the project root for Agent mode and background execution.
  - Complemented by scoped rules located in `.cursor/rules/*.mdc`.
  - In AI-OS, `.cursor/rules/agents.mdc` provides the direct pointer ensuring Cursor loads `AGENTS.md` as the single source of truth.

---

## 3. GitHub Copilot AGENTS.md & Custom Instructions

- **Official Source**: `https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot`
- **Retrieval Date**: 2026-10-27
- **Verification Status**: **VERIFIED**
- **Details**:
  - GitHub Copilot supports repository-level instructions defined in `AGENTS.md` as well as `.github/copilot-instructions.md`.
  - In AI-OS, `.github/copilot-instructions.md` acts as an adapter referencing canonical `AGENTS.md` to prevent policy drift.

---

## 4. Phase 7: Agent-Harness Hooks

- **Status**: **SKIPPED**
- **Retrieval Date**: 2026-10-27
- **Reason**: No official, vendor-supported lifecycle hook specification (such as pre-tool-call, post-tool-call, or harness-level intercepts) is published or standardized in official documentation by Cursor, GitHub Copilot, or Claude Code for third-party workspace integration. Rather than fabricating or introducing proprietary, undocumented hook names, Phase 7 is marked SKIPPED per AI-OS evidence-gated governance rules.
