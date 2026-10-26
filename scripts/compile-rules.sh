#!/usr/bin/env bash
# AI-OS Rule Compiler
# Compiles modular rules in .ai/rules/*.md into the canonical AGENTS.md
# Supports collision-resistant timestamp/short-hash IDs, configurable budgets, and nested monorepo packages.

set -euo pipefail

PROJECT_DIR="."
CHECK_MODE=false
STDOUT_MODE=false
MAX_RULES=50
TOKEN_BUDGET=12000
RECURSIVE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project|-p)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --check|-c)
            CHECK_MODE=true
            shift
            ;;
        --stdout)
            STDOUT_MODE=true
            shift
            ;;
        --max-rules)
            MAX_RULES="$2"
            shift 2
            ;;
        --token-budget)
            TOKEN_BUDGET="$2"
            shift 2
            ;;
        --recursive|-r)
            RECURSIVE=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: compile-rules.sh [--project <path>] [--check] [--stdout] [--max-rules <N>] [--token-budget <bytes>] [--recursive]" >&2
            exit 1
            ;;
    esac
done

compile_single_target() {
    local target_dir="$1"
    local rules_dir="$target_dir/.ai/rules"
    local agents_file="$target_dir/AGENTS.md"

    if [ ! -d "$rules_dir" ] || [ ! -f "$agents_file" ]; then
        return 0
    fi

    local rule_files=()
    while IFS= read -r f; do
        [ -n "$f" ] && rule_files+=("$f")
    done < <(find "$rules_dir" -maxdepth 1 -name "*.md" | sort)

    if [ ${#rule_files[@]} -eq 0 ]; then
        return 0
    fi

    if [ ${#rule_files[@]} -gt "$MAX_RULES" ]; then
        echo "❌ Error in $target_dir: rule count (${#rule_files[@]}) exceeds configured maximum ($MAX_RULES)" >&2
        exit 1
    fi

    local compiled_rules=""
    declare -A seen_ids=()

    for rf in "${rule_files[@]}"; do
        local rule_content
        rule_content=$(grep -v '^[[:space:]]*$' "$rf" | head -n 1 || true)
        
        if [ -z "$rule_content" ]; then
            continue
        fi
        
        if ! echo "$rule_content" | grep -qE '^([a-zA-Z0-9_-]+)\.[[:space:]]+\[(STYLE|CODE|ARCH|TOOL|PROCESS|DATA|UX|SECURITY|TEST|OTHER)\][[:space:]]+'; then
            echo "❌ Error in $(basename "$rf"): rule does not match standard format '<ID>. [CATEGORY] Description — rationale.'" >&2
            echo "   Content: $rule_content" >&2
            exit 1
        fi
        
        local actual_id
        actual_id=$(echo "$rule_content" | sed -E 's/^([a-zA-Z0-9_-]+)\..*/\1/')
        if [ -n "${seen_ids[$actual_id]:-}" ]; then
            echo "❌ Error in $(basename "$rf"): duplicate rule ID '$actual_id' detected (collision with ${seen_ids[$actual_id]})" >&2
            exit 1
        fi
        seen_ids["$actual_id"]="$(basename "$rf")"
        
        local full_rule_block
        full_rule_block=$(cat "$rf" | sed -e 's/[[:space:]]*$//')
        
        if [ -n "$compiled_rules" ]; then
            compiled_rules="${compiled_rules}"$'\n'"${full_rule_block}"
        else
            compiled_rules="${full_rule_block}"
        fi
    done

    if [ "$STDOUT_MODE" = true ]; then
        echo "$compiled_rules"
        return 0
    fi

    python3 - "$agents_file" "$compiled_rules" "$CHECK_MODE" "$TOKEN_BUDGET" << 'EOF'
import sys, re, os

agents_file = sys.argv[1]
compiled_rules = sys.argv[2]
check_mode = sys.argv[3] == 'true'
token_budget = int(sys.argv[4])

with open(agents_file, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'(?s)(##\s+([0-9]+\.\s+)?Learned Rules\s*\r?\n\s*(?:<!--.*?-->\s*\r?\n)?)'
match = re.search(pattern, content)

if not match:
    sys.stderr.write('❌ Error: Could not locate Learned Rules header in ' + agents_file + '\n')
    sys.exit(1)

prefix = content[:match.end()].rstrip() + '\n\n'
new_content = prefix + compiled_rules + '\n'

norm_existing = content.replace('\r\n', '\n').strip()
norm_new = new_content.replace('\r\n', '\n').strip()

# Enforce configured byte/token budget on target AGENTS.md
byte_size = len(norm_new.encode('utf-8'))
if byte_size > token_budget:
    sys.stderr.write(f'❌ Error: Compiled {agents_file} size ({byte_size} bytes) exceeds configured token budget ({token_budget} bytes)\n')
    sys.exit(1)

if check_mode:
    if norm_existing != norm_new:
        sys.stderr.write('❌ Check failed: ' + agents_file + ' is not in sync with .ai/rules/\n')
        sys.exit(1)
    else:
        print(' [PASS] ' + agents_file + ' is in sync with .ai/rules/')
        sys.exit(0)
else:
    with open(agents_file, 'w', encoding='utf-8', newline='\n') as f:
        f.write(new_content)
    print(f' [SUCCESS] Compiled rules into {agents_file} ({byte_size} bytes / budget {token_budget} bytes)')
EOF
}

# Compile main project
compile_single_target "$PROJECT_DIR"

# If recursive, compile any nested monorepo packages (e.g. packages/*, apps/*)
if [ "$RECURSIVE" = true ]; then
    for sub in "$PROJECT_DIR"/packages/* "$PROJECT_DIR"/apps/*; do
        if [ -d "$sub/.ai/rules" ] && [ -f "$sub/AGENTS.md" ]; then
            echo "📦 Compiling nested monorepo package: $sub"
            compile_single_target "$sub"
        fi
    done
fi
