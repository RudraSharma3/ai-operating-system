# Task: Export User Accounts

## Request
"Export the active user accounts from `users.json`."

## Note
This request is ambiguous: target format (JSON, CSV, TSV) and output location are not specified.
Per the Prompt Refinement playbook (`playbooks/prompt-refinement.md`) and AGENTS.md Section 1.4:
- Synthesize intent into a 4-part Prompt Contract (`GOAL`, `CONSTRAINTS`, `FORMAT`, `FAILURE`).
- In non-interactive or batch runs, state and document explicit safe defaults / assumptions in `docs/task-state.md` before executing.
- Perform the export according to the documented contract.
