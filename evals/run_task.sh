#!/usr/bin/env bash
# AI-OS Replayable Evaluation Task Runner
# Supports running tasks with or without AI-OS installed, with custom agent command or reference solution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TASKS_DIR="$SCRIPT_DIR/tasks"

TASK_NAME="all"
MODE="with"
AGENT_CMD=""
USE_REFERENCE=false
USE_NEGATIVE=false
EXPECT_FAIL=false
CHECK_ONLY=false
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task|-t)
            TASK_NAME="$2"
            shift 2
            ;;
        --mode|-m)
            MODE="$2"
            shift 2
            ;;
        --agent-cmd|-a)
            AGENT_CMD="$2"
            shift 2
            ;;
        --reference|-r)
            USE_REFERENCE=true
            shift
            ;;
        --negative|-n)
            USE_NEGATIVE=true
            shift
            ;;
        --expect-fail)
            EXPECT_FAIL=true
            shift
            ;;
        --check-only|-c)
            CHECK_ONLY=true
            shift
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: run_task.sh [--task <name|all>] [--mode with|without] [--agent-cmd <command>] [--reference] [--negative] [--expect-fail] [--check-only] [--target <dir>]" >&2
            exit 1
            ;;
    esac
done

run_single_task() {
    local t_dir="$1"
    local t_name
    t_name=$(basename "$t_dir")
    
    echo "============================================================"
    echo " 🧪 Running Eval Task: $t_name (Mode: $MODE)"
    echo "============================================================"

    local sandbox="$TARGET_DIR"
    local cleanup_needed=false
    if [ -z "$sandbox" ]; then
        local sys_tmp="${TMPDIR:-/tmp}"
        [ ! -d "$sys_tmp" ] && sys_tmp="/tmp"
        sandbox=$(mktemp -d "$sys_tmp/aios_eval_XXXXXX" 2>/dev/null || mktemp -d -t 'aios_eval')
        cleanup_needed=true
    else
        mkdir -p "$sandbox"
    fi

    local real_sandbox real_root
    real_sandbox=$(cd "$sandbox" && pwd -P)
    real_root=$(cd "$ROOT_DIR" && pwd -P)

    # 1. Refuse if sandbox is inside the repository tree
    if [[ "$real_sandbox" == "$real_root"* ]]; then
        echo "❌ ERROR: Evaluation sandbox '$sandbox' is located inside repository tree ($real_root)." >&2
        [ "$cleanup_needed" = true ] && rm -rf "$sandbox" 2>/dev/null || true
        return 1
    fi

    # 2. Refuse if sandbox is inside any parent directory containing other git repositories
    local parent_dir check_dir inside_parent=false
    parent_dir=$(dirname "$real_sandbox")
    check_dir="$parent_dir"
    while [ -n "$check_dir" ] && [ "$check_dir" != "/" ] && [ "$check_dir" != "." ]; do
        if [ -e "$check_dir/.git" ]; then
            inside_parent=true
            break
        fi
        local next_dir
        next_dir=$(dirname "$check_dir")
        [ "$next_dir" = "$check_dir" ] && break
        check_dir="$next_dir"
    done
    if [ "$inside_parent" = true ]; then
        echo "❌ ERROR: Evaluation sandbox '$sandbox' is located inside an existing parent git repository ($check_dir)." >&2
        [ "$cleanup_needed" = true ] && rm -rf "$sandbox" 2>/dev/null || true
        return 1
    fi

    # 3. Refuse --dangerously-skip-permissions unless AI_OS_EVAL_SANDBOX=1 is set
    if [[ "$AGENT_CMD" == *"--dangerously-skip-permissions"* ]]; then
        if [ "${AI_OS_EVAL_SANDBOX:-0}" != "1" ]; then
            echo "❌ ERROR: Refusing to run agent command with --dangerously-skip-permissions without AI_OS_EVAL_SANDBOX=1." >&2
            [ "$cleanup_needed" = true ] && rm -rf "$sandbox" 2>/dev/null || true
            return 1
        fi
    fi

    # 1. Setup fixture repo
    if [ "$CHECK_ONLY" = false ]; then
        echo "▶️ Setting up fixture repository..."
        bash "$t_dir/setup.sh" "$sandbox"
        
        # 2. Install AI-OS if mode == with
        if [ "$MODE" = "with" ]; then
            echo "🛡️ Installing AI-OS into fixture repository..."
            bash "$ROOT_DIR/scripts/install.sh" "$sandbox" >/dev/null 2>&1
        fi

        # 3. Apply solution or agent command
        if [ "$USE_REFERENCE" = true ]; then
            echo "▶️ Applying reference solution..."
            bash "$t_dir/reference_solution.sh" "$sandbox"
        elif [ "$USE_NEGATIVE" = true ]; then
            echo "▶️ Applying negative-control solution..."
            bash "$t_dir/negative_solution.sh" "$sandbox"
        elif [ -n "$AGENT_CMD" ]; then
            echo "▶️ Executing agent command: $AGENT_CMD (with secret environment stripped)..."
            local prompt_file="$t_dir/prompt.md"
            (
                # Strip environment variables matching common secret patterns
                for var in $(compgen -v 2>/dev/null || env | cut -d= -f1); do
                    if [[ "$var" =~ (KEY|TOKEN|SECRET|PASSWORD|^AWS_|^AZURE_|^GOOGLE_|^GCP_) ]]; then
                        unset "$var" 2>/dev/null || true
                    fi
                done
                cd "$sandbox" && eval "$AGENT_CMD \"$prompt_file\""
            ) || true
        else
            echo "ℹ️ Untouched fixture evaluation (no agent command or reference solution)."
        fi
    fi

    # 4. Run Check
    echo "🔍 Running evaluation check..."
    local check_status=0
    local check_output
    check_output=$(bash "$t_dir/check.sh" "$sandbox" 2>&1) || check_status=$?

    if [ "$check_status" -eq 0 ]; then
        echo "✅ Task $t_name Result: PASS"
        [ -n "$check_output" ] && echo "$check_output" | sed 's/^/   | /'
    else
        echo "❌ Task $t_name Result: FAIL"
        [ -n "$check_output" ] && echo "$check_output" | sed 's/^/   | /'
    fi

    if [ "$cleanup_needed" = true ]; then
        rm -rf "$sandbox" 2>/dev/null || true
    fi

    echo ""
    return "$check_status"
}

TOTAL_TASKS=0
PASSED_TASKS=0
FAILED_TASKS=0

tasks_to_run=()
if [ "$TASK_NAME" = "all" ]; then
    for d in "$TASKS_DIR"/*; do
        if [ -d "$d" ]; then
            tasks_to_run+=("$d")
        fi
    done
else
    if [ -d "$TASKS_DIR/$TASK_NAME" ]; then
        tasks_to_run+=("$TASKS_DIR/$TASK_NAME")
    elif [ -d "$TASK_NAME" ]; then
        tasks_to_run+=("$TASK_NAME")
    else
        echo "❌ Task '$TASK_NAME' not found in $TASKS_DIR" >&2
        exit 1
    fi
fi

for t in "${tasks_to_run[@]}"; do
    TOTAL_TASKS=$((TOTAL_TASKS + 1))
    if run_single_task "$t"; then
        PASSED_TASKS=$((PASSED_TASKS + 1))
    else
        FAILED_TASKS=$((FAILED_TASKS + 1))
    fi
done

echo "============================================================"
echo " Task Suite Summary: $PASSED_TASKS Passed | $FAILED_TASKS Failed (Total: $TOTAL_TASKS)"
echo "============================================================"

if [ "$EXPECT_FAIL" = true ]; then
    echo "============================================================"
    echo " Negative Control Expectation: Expecting all tasks to FAIL"
    echo "============================================================"
    if [ "$PASSED_TASKS" -eq 0 ] && [ "$FAILED_TASKS" -eq "$TOTAL_TASKS" ]; then
        echo "✅ Negative Control Suite: All $TOTAL_TASKS negative controls correctly rejected (exit 0)."
        exit 0
    else
        echo "❌ Negative Control Suite: Expected all negative controls to fail, but $PASSED_TASKS passed!"
        exit 1
    fi
fi

if [ "$FAILED_TASKS" -gt 0 ]; then
    exit 1
fi
exit 0
