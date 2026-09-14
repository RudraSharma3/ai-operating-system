# AI Operating System: Complete User Guide & Manual

A practical, step-by-step handbook for building software with the AI Operating System. No prior AI engineering experience required.

---

## 1. Quick Start: Scaffolding a New Project in 10 Seconds

To start a new project equipped with the entire AI Operating System:

### Option A: Using the 1-Command CLI (Recommended)

**On Windows (PowerShell):**
```powershell
# From your ai-operating-system directory:
.\scripts\init-project.ps1 -Name "my-saas-app" -Stack "Next.js + Tailwind + Supabase"
```

**On macOS / Linux (Bash):**
```bash
./scripts/init-project.sh "my-saas-app" "Next.js + Tailwind + Supabase"
```

### Option B: Manual Copy
1. Copy the `templates/project/` folder to your new project directory:
   ```bash
   cp -r ai-operating-system/templates/project/. my-saas-app/
   ```
2. Open `my-saas-app` in your favorite IDE (Cursor, VS Code, Antigravity, Claude Code).

---

## 2. Your Very First Prompt in a New Project

Once your project folder is open in your AI tool (Claude, Gemini, or ChatGPT), simply type:

> *"I want to build a real-time collaborative note-taking app with user authentication and tag organization."*

### What Happens Automatically:
1. **Prompt Optimization**: The agent expands your idea into a full specification with UI requirements, edge cases, and security checks (`docs/task-state.md`).
2. **Architecture Mapping**: The agent updates `docs/architecture.md` with components and database schemas.
3. **Scaffolding**: The agent immediately runs the initial package setup and begins Phase 1!

---

## 3. Daily Workflow: How to Build Features

Every task follows a smooth 6-stage lifecycle:

```
  [1. Discover]  ───▶  [2. Plan]  ───▶  [3. Build]
                                              │
  [6. Handoff]   ◀───  [5. Learn] ◀───  [4. Verify]
```

### Step 1: Prompt Your Agent
- **You**: *"Add Google OAuth login and a user profile dropdown."*
- **The AI OS**: Translates this into explicit acceptance criteria, edge cases, and error states.

### Step 2: The Agent Implements Code
- The agent makes surgical changes adhering to `docs/conventions.md`.

### Step 3: Autonomous Self-Healing Test Loop
- The agent automatically runs your test suite.
- If a test fails or throws a syntax error, the agent **auto-fixes the code and re-tests up to 3 times** before bothering you!

### Step 4: Clean Handoff
- The agent updates `docs/task-state.md` with checked-off tasks (`[x]`) and presents a concise summary of what was verified.

---

## 4. Teaching Your AI (Self-Modifying Rules)

Whenever you correct the agent or express a preference, the AI **permanently remembers it** for future sessions!

### How to Teach:
Just speak naturally:
- *"Always use `bun` instead of `npm`."*
- *"Use kebab-case for all component files."*
- *"Never use inline styles; always use Tailwind utility classes."*

### What the Agent Does:
The agent automatically:
1. Formats your preference: `4. [CODE] Always use bun instead of npm — user preference.`
2. Appends it to the `## Learned Rules` section in `AGENTS.md`.
3. Displays a badge confirming:  
   > 🧠 **Learned Rule Added to `AGENTS.md`**: `4. [CODE] Always use bun instead of npm — user preference.`

---

## 5. Switching Between AI Tools (Zero Amnesia!)

Hit Claude's rate limit? Want to switch to ChatGPT or Gemini?

You can switch models instantly without losing context!

```
1. You hit Claude's limit in the middle of building a feature.
2. Open the exact same project folder in ChatGPT (or Gemini).
3. ChatGPT automatically reads CODEX.md ──▶ docs/task-state.md.
4. ChatGPT immediately says:
   "I see where we left off on Step 2 (Google OAuth). Let's continue from here!"
```

---

## 6. Using Slash Commands (Chat Shortcuts)

If you use Claude Code or Antigravity, use these built-in shortcuts:

| Command | What It Does |
| --- | --- |
| `/feature <idea>` | Auto-refines your prompt, plans the files, and creates acceptance criteria in `docs/task-state.md`. |
| `/audit` | Triggers the **Security Reviewer** and **Tester** roles to scan for secret leaks, injection bugs, and edge cases. |
| `/sync-state` | Scans git diff and synchronizes completed milestones into `docs/task-state.md`. |

---

## 7. Advanced: Multi-Agent MCP & Decision Consensus

### When to Use Multi-Agent Mode (`playbooks/multi-agent-orchestration.md`)
For large fullstack features with separate UI, backend, and testing requirements:
- Configure `templates/project/mcp.json`.
- The **Manager (Claude)** creates the shared data contract first in `docs/architecture.md`.
- **Worker 1 (Gemini)** builds the frontend UI.
- **Worker 2 (Codex)** builds the backend API.
- **Worker 3 (Codex)** writes the automated test suite.

### When to Use Stochastic Consensus (`playbooks/stochastic-consensus.md`)
Facing a major architectural dilemma? (e.g. *"Should we use Supabase or Custom Postgres + Prisma?"*):
- Tell your agent: *"Run stochastic consensus on this architecture choice."*
- The agent samples 3–5 distinct personas (*Minimalist*, *Scalability Expert*, *Security Auditor*).
- Outputs a **Consensus Map** (Safe Bets vs. Trade-offs) and saves the decision to `docs/decisions/001-<decision>.md`.

---

## 8. Syncing Lessons Across All Your Projects

When you learn a fantastic universal rule in one project, you can propagate it to all future projects:

```powershell
# Run from your project directory:
powershell -File C:\path\to\ai-operating-system\scripts\sync-rules.ps1
```
This extracts all `[UNIVERSAL]` rules and merges them into your master AI Operating System repository.

---

## 9. Safety & Secret Protection

- **Pre-Commit Guard**: A built-in Git hook in `.githooks/pre-commit` automatically blocks any commit containing API keys, private tokens, or un-ignored `.env` files.
- **Zero Secrets in Rules**: The agent automatically converts secret corrections into generalized security policies (`"Load API keys from .env"`), keeping your codebase and prompt logs 100% secure.

---

## 10. FAQ & Troubleshooting

**Q: Can I use this with just 1 model like free ChatGPT or Antigravity?**  
**A:** Yes! The entire OS defaults to lightweight **Solo Model Mode** with zero external API setup required.

**Q: What if the agent suggests an over-complicated multi-agent swarm for a simple bug fix?**  
**A:** Rule 1.5 strictly enforces the **Anti-Over-Engineering Gate**. The agent is commanded to fast-track routine tasks in solo mode with zero overhead.

**Q: Where are my project tasks tracked?**  
**A:** In `docs/task-state.md`. It serves as the durable baton passed between AI sessions.
