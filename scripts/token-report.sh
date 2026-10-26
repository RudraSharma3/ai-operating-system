#!/usr/bin/env bash
# AI-OS Empirical Token & Footprint Measurement Tool
# Measures exact bytes, lines, characters, and estimated tokens across system files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

JSON_MODE=false
BUDGET_BYTES=15360 # 15KB

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --budget)
            BUDGET_BYTES="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: token-report.sh [--json] [--budget <bytes>]" >&2
            exit 1
            ;;
    esac
done

python3 - "$ROOT_DIR" "$JSON_MODE" "$BUDGET_BYTES" << 'EOF'
import os, sys, json, glob

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

root_dir = sys.argv[1]
json_mode = sys.argv[2] == 'true'
budget_bytes = int(sys.argv[3])

target_files = [
    'AGENTS.md',
    'CLAUDE.md',
    'GEMINI.md',
    'CODEX.md',
    '.cursorrules',
    '.github/copilot-instructions.md',
    '.ai/routing.md',
    'templates/project/AGENTS.md',
]

# Add all playbooks and prompts
for p in sorted(glob.glob(os.path.join(root_dir, 'playbooks', '*.md'))):
    target_files.append(os.path.relpath(p, root_dir).replace('\\', '/'))
for p in sorted(glob.glob(os.path.join(root_dir, 'prompts', '*.md'))):
    target_files.append(os.path.relpath(p, root_dir).replace('\\', '/'))

report = []
total_bytes = 0
total_chars = 0
total_lines = 0
total_tokens = 0

for rel in target_files:
    full_path = os.path.join(root_dir, rel)
    if os.path.isfile(full_path):
        with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        b_count = os.path.getsize(full_path)
        c_count = len(content)
        l_count = len(content.splitlines())
        w_count = len(content.split())
        t_est = int(round(c_count / 4.0)) # 1 token ~ 4 chars
        
        report.append({
            'file': rel,
            'bytes': b_count,
            'chars': c_count,
            'lines': l_count,
            'words': w_count,
            'est_tokens': t_est
        })
        
        total_bytes += b_count
        total_chars += c_count
        total_lines += l_count
        total_tokens += t_est

agents_bytes = os.path.getsize(os.path.join(root_dir, 'AGENTS.md')) if os.path.isfile(os.path.join(root_dir, 'AGENTS.md')) else 0
budget_pass = agents_bytes <= budget_bytes

if json_mode:
    output = {
        'budget_limit_bytes': budget_bytes,
        'canonical_agents_bytes': agents_bytes,
        'budget_pass': budget_pass,
        'total_files': len(report),
        'total_bytes': total_bytes,
        'total_lines': total_lines,
        'total_est_tokens': total_tokens,
        'files': report
    }
    print(json.dumps(output, indent=2))
else:
    print('========================================================================================')
    print(' AI-OS Empirical Token & Footprint Measurement Report')
    print('========================================================================================')
    print(f'{"File":<45} | {"Bytes":>7} | {"Lines":>6} | {"Words":>6} | {"Est. Tokens":>11}')
    print('----------------------------------------------------------------------------------------')
    for r in report:
        print(f'{r["file"]:<45} | {r["bytes"]:>7} | {r["lines"]:>6} | {r["words"]:>6} | {r["est_tokens"]:>11}')
    print('========================================================================================')
    print(f'{"TOTALS":<45} | {total_bytes:>7} | {total_lines:>6} | {"-":>6} | {total_tokens:>11}')
    print('========================================================================================')
    
    status_str = '[PASS]' if budget_pass else '[FAIL]'
    print(f' {status_str} Canonical AGENTS.md Budget Check: {agents_bytes:,} bytes / limit {budget_bytes:,} bytes (~{int(round(agents_bytes/4.0))} est. tokens)')
    print('========================================================================================')

sys.exit(0 if budget_pass else 1)
EOF
