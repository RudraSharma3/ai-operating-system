# AI Operating System: Complete User Guide & Manual
**Author:** Rudra Sharma  
**Version:** 2.0  
**Compatibility:** Works seamlessly with Google Antigravity, Cursor, Claude Code, GitHub Copilot, VS Code, OpenAI Codex/ChatGPT, and Local LLMs.

---

## 📖 Welcome to AI-OS

The **AI Operating System (AI-OS)** is a standardized operational layer that equips your software repositories with persistent context, self-correcting rules, automatic prompt refinement, and multi-agent coordination.

This guide walks you through integrating AI-OS into any existing project (**Project X**) safely, professionally, and step-by-step without affecting your existing code or the AI-OS master repository.

---

## 🎯 The 2-Repository Integration Scenario

Let's suppose you have two repositories on your local computer:
1. **`ai-operating-system`** — The AI-OS repository cloned from GitHub.
2. **`Project-X`** — Your existing application repository (e.g., React, Node.js, Python, Django, Flutter, Go, etc.).

Follow the steps below to integrate AI-OS into `Project-X` like a senior software engineer.

```
┌───────────────────────────┐           ┌───────────────────────────┐
│    ai-operating-system    │           │         Project-X         │
│     (Master Repository)   │           │    (Your Existing Code)   │
└─────────────┬─────────────┘           └─────────────┬─────────────┘
              │                                       │
              │  1. Push Baseline to GitHub           │ (git push origin main)
              │  2. Run AI-OS Integrator Script       │
              └──────────────────────────────────────>│ (Safely adds AI-OS layers)
                                                      │
                                                      ▼
                                       🎉 "Hey [User]! AI-OS by Rudra is 
                                          integrated into Project-X!"
                                                      │
                                                      ▼
                                        Open in IDE & Paste Kickoff Prompt
```

---

## 🚀 Step-by-Step Integration Guide

---

### 🔹 Step 0: Clone the AI-OS Repository to Your Computer

If you haven't already downloaded AI-OS, open your terminal and clone the repository onto your machine (e.g. in your projects folder or Desktop):

```bash
# Clone AI-OS to your local machine
git clone https://github.com/RudraSharma3/ai-operating-system.git
```

Now you have two folders on your computer:
1. `ai-operating-system` (The AI-OS master engine)
2. `Project-X` (Your project repository)

---

### 🔹 Step 1: Save & Push Your Project Code to GitHub (Safety Baseline)

Before adding any new tools or configuration, always save your project state. This creates a clean Git baseline so you can track all AI-OS enhancements.

Open your terminal, navigate to your project directory, and push:

```bash
# 1. Navigate to your project folder
cd /path/to/Project-X

# 2. Check your git status
git status

# 3. Stage and commit any outstanding changes
git add .
git commit -m "chore: save working baseline before adding AI-OS"

# 4. Push to your GitHub repository
git push origin main
```

*(If your default branch is `master`, replace `main` with `master`)*

---

### 🔹 Step 2: Run the AI-OS Integrator

Now, let the automated AI-OS installer configure your repository. It will copy the standardized rule hierarchy, architecture templates, playbooks, and Git security hooks into `Project-X` **without touching or modifying any of your existing code**.

#### **Option A: On Windows (PowerShell)**

1. Open PowerShell and navigate into your `ai-operating-system` directory:
   ```powershell
   cd C:\path\to\ai-operating-system
   ```
2. Run the installer (replace with the actual path to your `Project-X`):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -TargetPath "C:\Users\YourUsername\Projects\Project-X"
   ```
   > 💡 **Tip:** The `-ExecutionPolicy Bypass` flag ensures Windows runs the script cleanly without permission blocks.

#### **Option B: On macOS / Linux (Terminal)**

1. Open Terminal and navigate into your `ai-operating-system` directory:
   ```bash
   cd /path/to/ai-operating-system
   ```
2. Run the installer (replace with the actual path to your `Project-X`):
   ```bash
   ./scripts/install.sh "/path/to/Project-X"
   ```

#### **Option C: Manual Copy (If you prefer not to run scripts)**

If you prefer to copy the template files manually:
- **Windows (PowerShell):**
  ```powershell
  # Inside your ai-operating-system folder:
  $dest = "C:\path\to\Project-X"
  Copy-Item -Path ".\templates\project\*" -Destination $dest -Recurse -Force
  Copy-Item -Path ".\templates\project\.ai" -Destination $dest -Recurse -Force
  Copy-Item -Path ".\templates\project\.claude" -Destination $dest -Recurse -Force
  Copy-Item -Path ".\templates\project\.githooks" -Destination $dest -Recurse -Force
  ```
- **macOS / Linux:**
  ```bash
  # Inside your ai-operating-system folder:
  cp -r ./templates/project/. /path/to/Project-X/
  ```

---

### 🔹 Step 3: Verify the Confirmation & Health Diagnostic

When the integrator finishes, it runs a 14-point diagnostic and displays your personalized confirmation banner:

```
========================================================================
 🎉 Hey [Your Username]! AI-OS by Rudra is successfully integrated
    into your project 'Project-X'!
========================================================================

1. Core Instruction Files:
 [PASS] Canonical AGENTS.md exists
 [PASS] CLAUDE.md adapter exists
 [PASS] GEMINI.md adapter exists
 [PASS] CODEX.md adapter exists

2. Documentation Integrity:
 [PASS] docs/ directory exists
 [PASS] docs/architecture.md exists
 [PASS] docs/conventions.md exists
 [PASS] docs/task-state.md exists
 [PASS] docs/graph.md exists

3. Learning Engine:
 [PASS] .ai/ directory exists
 [PASS] .ai/mistakes-candidates.md exists
 [PASS] docs/lessons.md exists

4. Secret & Security Hygiene:
 [PASS] Zero secrets detected in Markdown/docs
 [PASS] .env file not committed to Git

====================================================
 Health Summary: 14 Passed | 0 Warnings | 0 Failures
 EXCELLENT! Project health is in pristine operational order.
====================================================
```

---

### 🔹 Step 4: Open Your Project in Your AI IDE

Open `Project-X` in your favorite AI-powered IDE or editor:
- **Google Antigravity**
- **Cursor**
- **Claude Code**
- **VS Code** (with Copilot / Gemini / Claude extension)
- **Windsurf**

---

### 🔹 Step 5: The Very First Prompt to Paste in Any IDE

As soon as your project is open in the IDE, open your AI chat window and paste this **exact kickoff prompt**:

```markdown
Read AGENTS.md and follow playbooks/codebase-analysis.md to analyze this repository. 
Please map our existing codebase and update docs/architecture.md, docs/conventions.md, 
and docs/graph.md with our current components, tech stack, and data flow.
```

#### 🧠 What the AI Does Automatically:
1. **Reads `AGENTS.md`**: Adopts the non-negotiable engineering principles, safety rules, and operational workflow.
2. **Scans Your Existing Code**: Analyzes your folders, files, packages, frameworks, database connections, and API endpoints.
3. **Populates `docs/architecture.md`**: Fills in your project's tech stack, directory structure, and core services.
4. **Generates `docs/graph.md`**: Generates visual Mermaid diagrams of your system dependencies and data flows.
5. **Configures `docs/conventions.md`**: Records your project's naming conventions, coding style, and testing commands.

---

### 🔹 Step 6: Push Your AI-OS Enabled Project to GitHub

Now that AI-OS has mapped your codebase, commit and push the newly added AI-OS layer to your repository:

```bash
cd /path/to/Project-X
git add .
git commit -m "feat: integrate AI Operating System by Rudra"
git push origin main
```

🎉 **Congratulations!** Your project is now permanently equipped with AI-OS.

---

## 🛠️ How to Start a BRAND NEW Project from Scratch

If you want to start a completely fresh project from zero with AI-OS already pre-configured:

#### **On Windows (PowerShell):**
```powershell
powershell -File "C:\path\to\ai-operating-system\scripts\init-project.ps1" -Name "my-new-app" -Stack "Next.js + Tailwind + Supabase"
```

#### **On macOS / Linux (Bash):**
```bash
./scripts/init-project.sh "my-new-app" "Next.js + Tailwind + Supabase"
```

Open the new folder `my-new-app` and paste:
```markdown
I want to build my-new-app using Next.js, Tailwind, and Supabase. Please review docs/architecture.md and start Phase 1.
```

---

## 💡 Daily Development & Pro Features

### 0. Autonomous Codebase Discovery (How AI-OS Understands What You've Built)
When AI-OS is first connected to an existing project, it executes the **Autonomous Codebase Exploration Protocol** (`playbooks/codebase-analysis.md`):
- **Reads All Files & Dependencies**: Ingests your package manifests (`package.json`, `requirements.txt`, `go.mod`), environment variables, and folder hierarchy.
- **Maps Application Boundaries**: Inspects frontend UI components, backend routes, database models, and background workers.
- **Builds Visual & Textual Memory**: Writes your system architecture into `docs/architecture.md` and generates an interactive Mermaid dependency graph in `docs/graph.md`.
- **Initializes Task State**: Analyzes git history and existing code to populate `docs/task-state.md` with what features are done and what remains to be built.

---

### 1. Building Features with Messy Prompts (Prompt Auto-Refining)
You do not need to write complex prompts. Even if you type casually:
> *"Add user authentication with Google OAuth and a logout button in the navbar."*

The AI-OS **Prompt Auto-Refinement Engine** intercepts it and creates a complete specification in `docs/task-state.md` with:
- Error boundaries & network failure handling
- Loading spinners & disabled state triggers
- Security checks & token hygiene
- Acceptance criteria checklist

---

### 2. Teaching Your AI (Self-Modifying Rules Engine)
Whenever you correct the AI during development, it permanently remembers:
- *"Always use `bun` instead of `npm`."*
- *"All components must use TypeScript strict types."*

The AI logs the lesson in `.ai/mistakes-candidates.md`, tests it against the 10-point quality criteria, and appends it to `AGENTS.md` under `## Learned Rules`. Next time you or a teammate opens the project, the AI already knows your preference!

---

### 3. Switching Between AI Tools (Zero Amnesia!)
If you hit rate limits on Claude, simply open the exact same folder in **Gemini** or **ChatGPT/Codex**.
Because AI-OS stores your project memory and active task progress in Markdown files (`AGENTS.md` and `docs/task-state.md`), the new AI picks up immediately where the previous AI left off!

---

### 4. Slash Commands Quick Reference

| Command | Action |
|---|---|
| `/feature <description>` | Intercepts feature request, refines the prompt, and updates `docs/task-state.md`. |
| `/interview <idea>` | Launches a 4-question interactive architectural interview before writing any code. |
| `/audit` | Activates the Security Reviewer and Tester roles to scan for secret leaks and bugs. |
| `/sync-state` | Synchronizes completed milestones and updates the dependency graph. |

---

### 5. Running Health Diagnostics
Anytime you want to verify your repository's AI-OS configuration:

```powershell
powershell -File "scripts/doctor.ps1"
```
It tests 14 key integrity checks across rules, documentation, hooks, and security.

---

### 6. Smart Pre-Commit Secret Armor & Actionable Remediation
AI-OS automatically protects you from accidentally committing API keys, tokens, or `.env` files to GitHub.
If a secret is ever staged, the Git Pre-Commit Guard (`.githooks/pre-commit`) blocks the commit and outputs the exact 3-step copy-paste commands to fix `.gitignore` and unstage the secret safely.

---

## 🤝 Need Help or Want to Contribute?
AI Operating System is created and maintained by **Rudra Sharma**. If you build cool things with AI-OS, share your feedback and star the repository on GitHub!
