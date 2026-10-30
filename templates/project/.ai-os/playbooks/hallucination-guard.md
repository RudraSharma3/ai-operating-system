# Hallucination Guard Playbook

This playbook provides actionable operating guidance for preventing and detecting coding-agent hallucination failure modes across repositories governed by AI-OS.

---

## 1. Scope & Objective

The hallucination verification layer is designed to reduce specific, testable failure modes common to autonomous coding agents:
1. **Phantom Dependencies**: Agents hallucinating package names that do not exist or installing unvetted third-party packages.
2. **Undeclared Imports**: Code importing modules that are not declared in repository manifests or standard libraries.
3. **Stale or Guessed APIs**: Agents assuming function signatures from outdated training data without inspecting local installed code.
4. **False Completion Claims**: Agents asserting that tests pass or builds succeed without actual verifiable execution.

> [!NOTE]
> This system reduces specific, testable engineering failure modes. It does not eliminate conversational factual inaccuracies in general chat answers.

---

## 2. Rule-to-Check Enforcement Matrix

Every rule in the `Evidence & Verification` contract is paired with a distinct enforcement mechanism:

| Rule Clause | Enforcement Mechanism | Enforcement Type | Primary Tool / Check |
| :--- | :--- | :--- | :--- |
| **Never claim tests pass without evidence** | Evidence ledger record check; CI status assertion | Model-judged & Mechanical | `.ai/evidence/` records, Eval 08 |
| **Dependencies require approval** | Pre-commit hook gate; CODEOWNERS lock | Mechanical (Deterministic) | `ai_os_verify.py deps`, Doctor Check 26 |
| **Cite `file:line` for existing code** | PR review, prompt contract checklist | Model-judged / Human | Review checklist, Prompt contracts |
| **Never guess API signatures** | Test execution, local source inspection | Model-judged & Mechanical | Eval 07, test suite execution |
| **Run tests via `ai-os-run`** | Ledger generation, task-state audit | Mechanical (Deterministic) | `scripts/ai-os-run`, Doctor Check 27 |

---

## 3. Operational Workflows

### 3.1 Adding a New Dependency
Autonomous agents must **never** add dependencies without human authorization.
1. When a task requires a new package, the agent must ask the user or propose the dependency.
2. A human reviewer adds an approved line to `.ai/deps-approved.txt`:
   ```text
   ecosystem|package_name|justification|YYYY-MM-DD|approver
   ```
   *Example*: `pypi|pydantic|Data validation for API models|2026-10-29|@lead-maintainer`
3. Pre-commit hooks run `scripts/ai_os_verify.py deps` against staged changes. Any manifest addition missing from `.ai/deps-approved.txt` blocks the commit.
4. `.ai/deps-approved.txt` is protected in `.github/CODEOWNERS` and guarded by Claude Code tool hooks.

### 3.2 Verifying Import Resolution
1. Run static import analysis locally:
   ```bash
   scripts/ai-os-verify.sh imports
   # or in PowerShell:
   scripts/ai-os-verify.ps1 imports
   ```
2. The verification engine inspects:
   - Python files via `ast` parsing against declared manifest dependencies, Python standard library modules (`sys.stdlib_module_names`), relative imports, and workspace packages.
   - JavaScript / TypeScript files via literal import/require regex against `package.json` dependencies and Node.js built-in modules.
3. Package aliases (e.g. `yaml` -> `pyyaml`, `PIL` -> `pillow`) are mapped via default tables and configurable project overrides in `.ai/import-aliases.txt`.

### 3.3 Running Tests and Producing Evidence Records
1. Execute tests using the evidence runner:
   ```bash
   scripts/ai-os-run -- pytest
   # or with npm:
   scripts/ai-os-run -- npm test
   ```
2. The runner executes the command, captures exit code, execution duration, git commit SHA, and an SHA-256 hash of output, saving a structured JSON record into `.ai/evidence/<run-id>.json`.
3. Tasks logged in `docs/task-state.md` must link their completion claim to the corresponding evidence run ID.

### 3.4 Registry Verification & Slopsquatting Detection (Opt-In / Online)
1. In opt-in scheduled workflows or explicit audit runs, verify dependency hygiene:
   ```bash
   python3 scripts/ai_os_verify.py registry-check --online
   ```
2. Checks performed:
   - Confirms that approved packages exist in public registries (PyPI, npm).
   - Identifies packages published within the last 14 days (cooldown / new release warning).
   - Measures Levenshtein edit distance against popular packages and existing dependencies as a heuristic to flag potential typosquatting or slopsquatting risks (heuristic alert).

---

## 4. Known Limitations & Trust Boundaries

1. **Manifest Support**:
   - Supported manifests: `package.json`, `requirements*.txt`, `pyproject.toml`.
   - Other languages (e.g., Cargo, Go, Bundler) require manual extension of parser logic.
2. **Dynamic Imports**:
   - Runtime dynamic imports (such as Python `importlib.import_module(...)` or JavaScript dynamic `require(variable)`) cannot be statically resolved.
3. **Trust & Boundary Model**:
   - The local evidence ledger is designed to prevent honest developer and agent mistakes (unsubstantiated claims, premature task completion, missed test steps).
   - It is **not** a hardened cryptographic security boundary against an adversarial agent attempting to write fraudulent JSON records.
   - GitHub Actions CI in protected environments remains the authoritative source of truth.
4. **Offline by Default**:
   - All default test, hook, and doctor paths operate 100% offline without network calls.
   - Registry checks execute strictly when explicitly requested with `--online`.

