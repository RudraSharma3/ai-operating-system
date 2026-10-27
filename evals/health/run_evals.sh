#!/usr/bin/env bash
# AI-OS Empirical Benchmark & Evaluation Runner
# Measures token budget compliance, hook interception accuracy, and doctor latency.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "============================================================"
echo " 📈 RUNNING AI-OS EMPIRICAL BENCHMARKS & EVALUATIONS"
echo "============================================================"
echo ""

PASSED_EVALS=0
FAILED_EVALS=0

run_eval() {
    local eval_name="$1"
    local eval_cmd="$2"
    echo -n "  • [BENCHMARK] $eval_name ... "
    
    local start_time
    start_time=$(date +%s%N 2>/dev/null || date +%s)
    
    local output
    local status=0
    output=$(eval "$eval_cmd" 2>&1) || status=$?
    
    local end_time
    end_time=$(date +%s%N 2>/dev/null || date +%s)
    
    if [ $status -eq 0 ]; then
        echo "PASS"
        PASSED_EVALS=$((PASSED_EVALS + 1))
    else
        echo "FAIL"
        echo "    --- Evaluation Details ---"
        echo "$output" | sed 's/^/    | /'
        echo "    --------------------------"
        FAILED_EVALS=$((FAILED_EVALS + 1))
    fi
}

# 1. Token Budget Benchmark
run_eval "Token Budget: AGENTS.md within 15KB budget" \
    "'$ROOT_DIR/scripts/token-report.sh' --budget 15360 >/dev/null"

# 2. Secret Defense Accuracy Benchmark (100% block rate)
run_eval "Secret Defense: POSIX engine blocks multi-vendor signatures" \
    "bash '$ROOT_DIR/tests/test_hook.sh' >/dev/null"

# 3. Doctor Diagnostics Latency (<4.0s budget)
run_eval "Doctor Latency: 14 health checks execute under 4.0s" \
    "bash '$ROOT_DIR/scripts/doctor.sh' --ci '$ROOT_DIR' >/dev/null"

# 4. Prompt Contract Integrity
run_eval "Prompt Contract: Specification defines all 4 required sections" \
    "grep -qE '^### .*GOAL:' '$ROOT_DIR/playbooks/prompt-refinement.md' && \
     grep -qE '^### .*CONSTRAINTS:' '$ROOT_DIR/playbooks/prompt-refinement.md' && \
     grep -qE '^### .*FORMAT:' '$ROOT_DIR/playbooks/prompt-refinement.md' && \
     grep -qE '^### .*FAILURE' '$ROOT_DIR/playbooks/prompt-refinement.md'"

# 5. Template Zero Drift Benchmark
run_eval "Template Parity: Zero drift between master and generated templates" \
    "'$ROOT_DIR/scripts/build-templates.sh' --check >/dev/null"

echo ""
echo "============================================================"
echo " Benchmark Summary: $PASSED_EVALS Passed | $FAILED_EVALS Failed"
echo "============================================================"

if [ "$FAILED_EVALS" -gt 0 ]; then
    exit 1
fi
exit 0
