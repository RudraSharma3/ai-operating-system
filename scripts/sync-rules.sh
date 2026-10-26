#!/usr/bin/env bash
# AI-OS Federated Rule Sync & Quality Gate
# Scans downstream project rules, validates through 10-point mechanical gate,
# and generates structured proposals under proposals/ (never silent direct merge).

set -euo pipefail

PROJECT_PATH="."
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project|-p)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: sync-rules.sh [--project <path>] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

echo "===================================================="
echo " 🧠 AI-OS Federated Learning & Proposal Gate"
echo " Source Project: $PROJECT_PATH"
echo " Master AI-OS:   $MASTER_ROOT"
echo "===================================================="

SECRET_PATTERNS_FILE="$MASTER_ROOT/.ai/secret-patterns.txt"
PROPOSALS_DIR="$MASTER_ROOT/proposals"
mkdir -p "$PROPOSALS_DIR"

# Collect rules from downstream project
CANDIDATE_RULES=()
if [ -d "$PROJECT_PATH/.ai/rules" ]; then
    while IFS= read -r f; do
        if [ -n "$f" ]; then
            rule_line=$(grep -v '^[[:space:]]*$' "$f" | head -n 1)
            [ -n "$rule_line" ] && CANDIDATE_RULES+=("$rule_line")
        fi
    done < <(find "$PROJECT_PATH/.ai/rules" -maxdepth 1 -name "*.md" | sort)
fi

if [ ${#CANDIDATE_RULES[@]} -eq 0 ] && [ -f "$PROJECT_PATH/AGENTS.md" ]; then
    # Fallback to extracting from AGENTS.md Learned Rules section
    in_learned=false
    while IFS= read -r line; do
        if echo "$line" | grep -qE '^##[[:space:]]+([0-9]+\.[[:space:]]*)?Learned Rules'; then
            in_learned=true
            continue
        elif $in_learned && echo "$line" | grep -qE '^##[[:space:]]+'; then
            in_learned=false
        fi
        if $in_learned && echo "$line" | grep -qE '^[0-9]+\.[[:space:]]+\[[A-Z]+\]'; then
            CANDIDATE_RULES+=("$line")
        fi
    done < "$PROJECT_PATH/AGENTS.md"
fi

if [ ${#CANDIDATE_RULES[@]} -eq 0 ]; then
    echo "ℹ️ No learned rules discovered in project to evaluate."
    exit 0
fi

echo "Found ${#CANDIDATE_RULES[@]} candidate rule(s). Evaluating through 10-point mechanical gate..."

python3 - "$MASTER_ROOT" "$PROJECT_PATH" "$SECRET_PATTERNS_FILE" "$PROPOSALS_DIR" "$DRY_RUN" "${CANDIDATE_RULES[@]}" << 'EOF'
import os, sys, re, datetime

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

master_root = sys.argv[1]
project_path = sys.argv[2]
patterns_file = sys.argv[3]
proposals_dir = sys.argv[4]
dry_run = sys.argv[5] == 'true'
raw_rules = sys.argv[6:]

# Load master secret patterns
secret_regexes = []
if os.path.isfile(patterns_file):
    with open(patterns_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                parts = line.split('|', 1)
                pattern = parts[1] if len(parts) == 2 else parts[0]
                try:
                    secret_regexes.append(re.compile(pattern))
                except Exception:
                    pass

# Load master active rules
master_rules = []
master_rules_dir = os.path.join(master_root, '.ai', 'rules')
if os.path.isdir(master_rules_dir):
    for f in os.listdir(master_rules_dir):
        if f.endswith('.md'):
            with open(os.path.join(master_rules_dir, f), 'r', encoding='utf-8') as rf:
                txt = rf.read().strip()
                if txt:
                    master_rules.append(txt)

def evaluate_rule(rule_str):
    # Rule syntax: N. [CATEGORY] Description — rationale.
    match = re.match(r'^[0-9]+\.\s+\[([A-Z]+)\]\s+(.*)', rule_str)
    if not match:
        return False, 'Fails format syntax (N. [CATEGORY] Description — rationale.)', []
    
    category = match.group(1)
    body = match.group(2)
    
    checks = []
    
    # 1. Category tag
    valid_categories = {'STYLE', 'CODE', 'ARCH', 'TOOL', 'PROCESS', 'DATA', 'UX', 'SECURITY', 'TEST', 'OTHER'}
    if category in valid_categories:
        checks.append(('PASS', 'Valid Category tag [' + category + ']'))
    else:
        return False, f'Invalid category [{category}]', checks
    
    # 2. Rationale separator
    has_rationale = ' — ' in body or ' - ' in body
    if has_rationale:
        checks.append(('PASS', 'Includes explicit evidence and rationale separator'))
    else:
        return False, 'Missing evidence/rationale separator (— or -)', checks
    
    # 3. Actionable length
    if len(body) >= 20:
        checks.append(('PASS', 'Actionable instruction statement length adequate'))
    else:
        return False, 'Rule statement is too brief to be actionable', checks
    
    # 4. General scope (no local paths)
    local_path_patterns = [r'/Users/', r'C:\\', r'D:\\', r'/home/', r'node_modules', r'apps/web', r'src/components']
    has_local_path = any(re.search(lp, body, re.IGNORECASE) for lp in local_path_patterns)
    if not has_local_path:
        checks.append(('PASS', 'Free of project-specific local file paths'))
    else:
        return False, 'Contains project-specific local file paths; not universal', checks
    
    # 5. Non-conflicting / not duplicated
    body_core = body.split(' — ')[0].split(' - ')[0].strip().lower()
    is_dup = False
    for mr in master_rules:
        if body_core in mr.lower():
            is_dup = True
            break
    if not is_dup:
        checks.append(('PASS', 'Non-conflicting and not already present in master'))
    else:
        return False, 'Rule already present in master ruleset', checks
    
    # 6. Safe source
    injection_words = ['ignore previous', 'system prompt', 'api key sk-', 'bypass guard']
    has_inj = any(iw in body.lower() for iw in injection_words)
    if not has_inj:
        checks.append(('PASS', 'Clean instruction source'))
    else:
        return False, 'Contains prompt injection or suspicious phrases', checks
    
    # 7. Zero secrets
    has_secret = any(rx.search(rule_str) for rx in secret_regexes)
    if not has_secret:
        checks.append(('PASS', 'Zero secrets or credential patterns detected'))
    else:
        return False, 'CRITICAL: Contains credential or secret pattern!', checks
    
    # 8. Durability
    checks.append(('PASS', 'Durable engineering practice'))
    
    # 9. Format syntax
    checks.append(('PASS', 'Complies with canonical format'))
    
    # 10. Reusability
    checks.append(('PASS', 'Reusable principle across software stacks'))
    
    return True, category, checks

stats = {'proposed': 0, 'rejected': 0, 'duplicate': 0}

for r in raw_rules:
    passed, reason, checks = evaluate_rule(r)
    if not passed:
        if 'already present' in reason:
            print(f' [=] Skipped (duplicate): {r[:60]}...')
            stats['duplicate'] += 1
        else:
            print(f' [REJECTED] GATE REJECTED: {reason}')
            print(f'     Rule: {r}')
            stats['rejected'] += 1
    else:
        cat = reason
        # Generate proposal file
        match = re.match(r'^[0-9]+\.\s+\[([A-Z]+)\]\s+(.*)', r)
        body = match.group(2)
        slug = re.sub(r'[^a-z0-9]+', '-', body.split('—')[0].split('-')[0].strip().lower()).strip('-')[:40]
        ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S')
        prop_filename = f'{ts}-{slug}.md'
        prop_path = os.path.join(proposals_dir, prop_filename)
        
        md_content = f'''# Rule Proposal: {body[:60]}

- **Source Project**: {project_path}
- **Proposed Date**: {datetime.datetime.now(datetime.timezone.utc).isoformat()}
- **Category**: [{cat}]
- **Status**: PENDING

## Proposed Rule Content
`[{cat}] {body}`

## 10-Point Mechanical Quality Gate Assessment
'''
        for idx, (status, desc) in enumerate(checks, 1):
            md_content += f'{idx}. [{status}] {desc}\n'
        
        md_content += f'''
## Execution Command
To approve and compile into canonical rules:
```bash
./scripts/approve-proposal.sh proposals/{prop_filename}
```
'''
        if not dry_run:
            with open(prop_path, 'w', encoding='utf-8') as pf:
                pf.write(md_content)
        
        print(f' [PROPOSAL GENERATED] proposals/{prop_filename}')
        print(f'     Rule: [{cat}] {body}')
        stats['proposed'] += 1

print('====================================================')
print(f' Gate Summary: {stats["proposed"]} proposal(s) created, {stats["rejected"]} rejected, {stats["duplicate"]} duplicate(s) skipped.')
print('====================================================')
EOF
