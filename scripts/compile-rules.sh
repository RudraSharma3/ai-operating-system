#!/usr/bin/env bash
# AI-OS Rule Compiler
# Compiles modular rules in .ai/rules/*.md into the canonical AGENTS.md

set -euo pipefail

PROJECT_DIR="."
CHECK_MODE=false
STDOUT_MODE=false

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
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: compile-rules.sh [--project <path>] [--check] [--stdout]" >&2
            exit 1
            ;;
    esac
done

RULES_DIR="$PROJECT_DIR/.ai/rules"
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"

if [ ! -d "$RULES_DIR" ]; then
    echo "❌ Error: Rules directory not found at $RULES_DIR" >&2
    exit 1
fi

if [ ! -f "$AGENTS_FILE" ]; then
    echo "❌ Error: AGENTS.md not found at $AGENTS_FILE" >&2
    exit 1
fi

# Find and sort rule files
RULE_FILES=()
while IFS= read -r f; do
    [ -n "$f" ] && RULE_FILES+=("$f")
done < <(find "$RULES_DIR" -maxdepth 1 -name "*.md" | sort)

if [ ${#RULE_FILES[@]} -eq 0 ]; then
    echo "⚠️ Warning: No rule files found in $RULES_DIR" >&2
    exit 0
fi

COMPILED_RULES=""
EXPECTED_NUM=1

for rf in "${RULE_FILES[@]}"; do
    RULE_CONTENT=$(grep -v '^[[:space:]]*$' "$rf" | head -n 1)
    
    if [ -z "$RULE_CONTENT" ]; then
        continue
    fi
    
    if ! echo "$RULE_CONTENT" | grep -qE '^[0-9]+\.[[:space:]]+\[(STYLE|CODE|ARCH|TOOL|PROCESS|DATA|UX|SECURITY|TEST|OTHER)\][[:space:]]+'; then
        echo "❌ Error in $(basename "$rf"): rule does not match standard format 'N. [CATEGORY] Description — rationale.'" >&2
        echo "   Content: $RULE_CONTENT" >&2
        exit 1
    fi
    
    ACTUAL_NUM=$(echo "$RULE_CONTENT" | sed -E 's/^([0-9]+)\..*/\1/')
    if [ "$ACTUAL_NUM" -ne "$EXPECTED_NUM" ]; then
        echo "❌ Error in $(basename "$rf"): expected rule number $EXPECTED_NUM, but found $ACTUAL_NUM" >&2
        exit 1
    fi
    
    FULL_RULE_BLOCK=$(cat "$rf" | sed -e 's/[[:space:]]*$//')
    
    if [ -n "$COMPILED_RULES" ]; then
        COMPILED_RULES="${COMPILED_RULES}"$'\n'"${FULL_RULE_BLOCK}"
    else
        COMPILED_RULES="${FULL_RULE_BLOCK}"
    fi
    
    EXPECTED_NUM=$((EXPECTED_NUM + 1))
done

if [ "$STDOUT_MODE" = true ]; then
    echo "$COMPILED_RULES"
    exit 0
fi

python3 -c "
import sys, re

agents_file = sys.argv[1]
compiled_rules = sys.argv[2]
check_mode = sys.argv[3] == 'true'

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
    print(' [SUCCESS] Compiled ' + str($((EXPECTED_NUM - 1))) + ' rules into ' + agents_file)
" "$AGENTS_FILE" "$COMPILED_RULES" "$CHECK_MODE"
