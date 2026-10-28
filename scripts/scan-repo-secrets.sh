#!/usr/bin/env bash
# AI-OS Repository Secret Scan Audit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT" || exit 1

patterns=(
    "JWT Token|eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}"
    "Database URL|[a-zA-Z0-9+.-]+://[^:@[:space:]]+:[^@[:space:]]+@[a-zA-Z0-9.-]+"
)

echo "============================================================"
echo " 🔍 Auditing Tracked Files for JWT & DB-URL Patterns"
echo "============================================================"

match_count=0
while IFS= read -r file; do
    case "$file" in
        *.ai/secret-patterns.txt*|*.githooks/pre-commit*) continue ;;
    esac
    [ ! -f "$file" ] && continue
    for p in "${patterns[@]}"; do
        pname="${p%%|*}"
        preg="${p#*|}"
        if grep -E -q -e "$preg" "$file" 2>/dev/null; then
            echo "MATCH FOUND: [$pname] in $file"
            match_count=$((match_count + 1))
        fi
    done
done < <(git ls-files)

echo "------------------------------------------------------------"
echo "Total Matches / False Positives in Tracked Files: $match_count"
echo "============================================================"
exit 0
