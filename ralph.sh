#!/bin/bash
#
# ralph.sh - Autonomous Implementation Loop for Micro-Claude
#
# Usage:
#   ./ralph.sh <task-name> [max-iterations]
#   ./ralph.sh                          # Interactive: list and select task
#   ./ralph.sh user-auth                # Run until complete (default 50 iterations)
#   ./ralph.sh user-auth 20             # Run max 20 iterations
#
# If `prd.json` enables recursive mode, Ralph keeps looping until the recursive
# condition is satisfied and recursive mode is turned off.
#
# This script implements the Ralph Wiggum pattern: each iteration runs with
# fresh context, avoiding the context accumulation that degrades output quality.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
MICRO_CLAUDE_DIR=".micro-claude"
DEFAULT_MAX_ITERATIONS=50
ITERATION=0

# Print colored output
log() {
    echo -e "${2:-$NC}$1${NC}"
}

# Print header
print_header() {
    echo ""
    log "╔══════════════════════════════════════════════════════════════╗" "$CYAN"
    log "║           Ralph Loop - Micro-Claude Implementation           ║" "$CYAN"
    log "╚══════════════════════════════════════════════════════════════╝" "$CYAN"
    echo ""
}

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log "Error: jq is required but not installed." "$RED"
        log "Install it with: brew install jq (macOS) or apt install jq (Linux)" "$YELLOW"
        exit 1
    fi

    if ! command -v claude &> /dev/null; then
        log "Error: claude CLI is required but not installed." "$RED"
        log "Install it with: npm install -g @anthropic-ai/claude-code" "$YELLOW"
        exit 1
    fi
}

# Global array to store task names for selection
AVAILABLE_TASKS=()

# List available tasks and populate AVAILABLE_TASKS array
list_tasks() {
    if [ ! -d "$MICRO_CLAUDE_DIR" ]; then
        log "No .micro-claude directory found." "$RED"
        echo ""
        log "Get started with:" "$YELLOW"
        log "  1. /mc:interrogate  → Create a detailed plan" "$WHITE"
        log "  2. /mc:explode      → Break into tasks" "$WHITE"
        log "  3. ./ralph.sh       → Run autonomous loop" "$WHITE"
        echo ""
        exit 1
    fi

    AVAILABLE_TASKS=()
    local task_info_list=()

    for dir in "$MICRO_CLAUDE_DIR"/*/; do
        if [ -f "${dir}prd.json" ]; then
            local task_name=$(basename "$dir")
            local total=$(jq '.tasks | length' "${dir}prd.json" 2>/dev/null || echo 0)
            local done=$(jq '[.tasks[] | select(.done == true)] | length' "${dir}prd.json" 2>/dev/null || echo 0)
            AVAILABLE_TASKS+=("$task_name")
            task_info_list+=("$task_name|$done|$total")
        fi
    done

    if [ ${#AVAILABLE_TASKS[@]} -eq 0 ]; then
        log "No tasks found with prd.json." "$RED"
        echo ""
        log "Get started with:" "$YELLOW"
        log "  1. /mc:interrogate  → Create a detailed plan" "$WHITE"
        log "  2. /mc:explode      → Break into tasks" "$WHITE"
        log "  3. ./ralph.sh       → Run autonomous loop" "$WHITE"
        echo ""
        exit 1
    fi

    echo ""
    log "Available tasks:" "$CYAN"
    echo ""
    printf "  %-4s %-30s %s\n" "#" "TASK" "PROGRESS"
    printf "  %-4s %-30s %s\n" "---" "----" "--------"

    local index=1
    for task_info in "${task_info_list[@]}"; do
        IFS='|' read -r name done total <<< "$task_info"
        if [ "$done" -eq "$total" ]; then
            printf "  ${GREEN}%-4s %-30s %s/%s (complete)${NC}\n" "[$index]" "$name" "$done" "$total"
        elif [ "$done" -gt 0 ]; then
            printf "  ${YELLOW}%-4s %-30s %s/%s (in progress)${NC}\n" "[$index]" "$name" "$done" "$total"
        else
            printf "  %-4s %-30s %s/%s\n" "[$index]" "$name" "$done" "$total"
        fi
        ((index++))
    done
    echo ""
}

# Select task interactively
select_task() {
    list_tasks

    local task_count=${#AVAILABLE_TASKS[@]}

    if [ "$task_count" -eq 1 ]; then
        # Auto-select if only one task
        TASK_NAME="${AVAILABLE_TASKS[0]}"
        log "Auto-selecting: $TASK_NAME" "$CYAN"
        return
    fi

    echo ""
    read -p "Enter task number (1-$task_count) or name: " selection

    if [ -z "$selection" ]; then
        log "No task selected. Exiting." "$YELLOW"
        exit 0
    fi

    # Check if selection is a number
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [ "$selection" -ge 1 ] && [ "$selection" -le "$task_count" ]; then
            TASK_NAME="${AVAILABLE_TASKS[$((selection-1))]}"
        else
            log "Invalid selection: $selection. Please enter 1-$task_count." "$RED"
            exit 1
        fi
    else
        # Assume it's a task name
        TASK_NAME="$selection"
    fi
}

# Get pending task count
get_pending_count() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq '[.tasks[] | select(.done == false)] | length' "$task_dir/prd.json" 2>/dev/null || echo 0
}

# Get total task count
get_total_count() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq '.tasks | length' "$task_dir/prd.json" 2>/dev/null || echo 0
}

# Get completed task count
get_done_count() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq '[.tasks[] | select(.done == true)] | length' "$task_dir/prd.json" 2>/dev/null || echo 0
}

# Get recursive enabled flag
get_recursive_enabled() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq -r '.recursive.enabled // false' "$task_dir/prd.json" 2>/dev/null || echo false
}

# Get recursive condition text
get_recursive_condition() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq -r '.recursive.condition // ""' "$task_dir/prd.json" 2>/dev/null || echo ""
}

# Get recursive target text
get_recursive_target() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    jq -r '.recursive.recurseOn // ""' "$task_dir/prd.json" 2>/dev/null || echo ""
}

# Validate prd.json structure, including recursive mode rules
validate_prd() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    local prd_file="$task_dir/prd.json"

    if ! jq empty "$prd_file" >/dev/null 2>&1; then
        log "Invalid JSON in $prd_file" "$RED"
        exit 1
    fi

    if ! jq -e 'has("tasks") and (.tasks | type == "array")' "$prd_file" >/dev/null 2>&1; then
        log "Invalid prd.json: missing tasks array" "$RED"
        exit 1
    fi

    local recursive_enabled=$(get_recursive_enabled)
    if [ "$recursive_enabled" = "true" ]; then
        if ! jq -e '
            .recursive
            and (.recursive | type == "object")
            and (.recursive.condition | type == "string")
            and (.recursive.recurseOn | type == "string")
            and (.recursive.condition | gsub("^\\s+|\\s+$"; "") | length > 0)
            and (.recursive.recurseOn | gsub("^\\s+|\\s+$"; "") | length > 0)
        ' "$prd_file" >/dev/null 2>&1; then
            log "Invalid prd.json: recursive.enabled=true requires non-empty recursive.condition and recursive.recurseOn" "$RED"
            exit 1
        fi
    fi
}

# Generate the prompt for this iteration
generate_prompt() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"
    local recursive_enabled=$(get_recursive_enabled)
    local recursive_condition=$(get_recursive_condition)
    local recursive_target=$(get_recursive_target)

    cat <<EOF
# Build Iteration for: $TASK_NAME

You are implementing tasks from a PRD in an autonomous loop. Each iteration you complete tasks, update state, and then exit.

## Context Files
- Task directory: $task_dir/
- Plan (specifications): $task_dir/plan.md
- Tasks (PRD): $task_dir/prd.json
- Notes (history): $task_dir/notes.md

## Your Mission

### Step 1: Load Context
1. Read \`$task_dir/prd.json\` to see all tasks
2. Read \`$task_dir/notes.md\` to understand what's been done
3. Find ALL tasks where \`"done": false\`
4. Read the recursive configuration in \`$task_dir/prd.json\`

### Step 2: Assess and Batch Tasks
Review pending tasks and decide how many to tackle this iteration:

**Batch multiple tasks when:**
- Tasks are simple (add a field, create a type, write a config)
- Tasks touch the same file or area
- Tasks are independent and low-risk
- Combined effort feels like <15 min of work

**Do ONE task when:**
- Task is complex (new feature, significant logic)
- Task requires research or exploration
- Task has many unknowns or dependencies
- Task involves testing/debugging

Aim for 2-5 simple tasks per batch, or 1 complex task. Don't overload - fresh context is cheap.

### Step 3: Understand Tasks
For each task you're doing:
1. Get the \`from\` and \`to\` line numbers from the task
2. Read those specific lines from \`$task_dir/plan.md\`
3. This gives you the detailed requirements

### Step 4: Implement
1. Search the codebase first - don't assume code doesn't exist
2. Follow existing patterns in the codebase
3. Implement exactly what each task describes
4. Run tests if applicable

### Step 5: Update State
For EACH completed task:

1. Append to \`$task_dir/notes.md\`:
   \`\`\`markdown
   ## Task #[id]: [title]
   **Status**: Completed
   **Files**: [files created/modified]
   **Notes**:
   - [What was implemented]
   - [Key decisions]
   \`\`\`

2. Update \`$task_dir/prd.json\`:
   - Set this task's \`"done": true\`

### Step 6: Recursive Review
- Recursive mode enabled: $recursive_enabled
- Recursive condition: $recursive_condition
- Recurse on: $recursive_target

If recursive mode is enabled:
1. Re-assess the codebase, plan, notes, and PRD against the recursive target before exiting
2. If more work is needed, add follow-up tasks to \`$task_dir/prd.json\` with new sequential IDs and keep \`recursive.enabled\` as \`true\`
3. If the recursive condition is satisfied, set \`recursive.enabled\` to \`false\` and record the decision in \`$task_dir/notes.md\`
4. Never leave the PRD in a state where there are zero pending tasks and \`recursive.enabled\` is still \`true\` unless you intentionally need another recursive review iteration

### Step 7: Exit
After completing your work for this iteration, exit. The loop will restart with fresh context if more work remains.

## Rules
- Batch simple tasks, isolate complex ones
- Always search before assuming code doesn't exist
- Follow existing code patterns
- If blocked, note the blocker in notes.md and still mark done
- Keep notes concise but informative
- Don't exceed ~5 tasks per iteration even if they're simple
- If \`recursive.enabled\` is \`true\`, do not consider the task finished until the recursive condition has been satisfied

## Current Iteration: $((ITERATION + 1))
EOF
}

# Run one iteration
run_iteration() {
    local prompt=$(generate_prompt)
    local recursive_enabled=$(get_recursive_enabled)
    local status_suffix=""

    if [ "$recursive_enabled" = "true" ]; then
        status_suffix=" | Recursive: on"
    fi

    log "────────────────────────────────────────────────────────────────" "$BLUE"
    log "Iteration $((ITERATION + 1)) | Task: $TASK_NAME | Pending: $(get_pending_count)/$(get_total_count)$status_suffix" "$BLUE"
    log "────────────────────────────────────────────────────────────────" "$BLUE"
    echo ""

    # Run Claude with fresh context
    echo "$prompt" | claude -p --dangerously-skip-permissions

    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "Claude exited with code $exit_code" "$YELLOW"
    fi

    return $exit_code
}

# Main loop
run_loop() {
    local task_dir="$MICRO_CLAUDE_DIR/$TASK_NAME"

    # Validate task exists
    if [ ! -d "$task_dir" ]; then
        log "Task '$TASK_NAME' not found in $MICRO_CLAUDE_DIR/" "$RED"
        list_tasks
        exit 1
    fi

    if [ ! -f "$task_dir/prd.json" ]; then
        log "No prd.json found for '$TASK_NAME'. Run /mc:explode first." "$RED"
        exit 1
    fi

    validate_prd

    # Check if already complete
    local pending=$(get_pending_count)
    local recursive_enabled=$(get_recursive_enabled)
    if [ "$pending" -eq 0 ] && [ "$recursive_enabled" != "true" ]; then
        log "All tasks already complete for '$TASK_NAME'!" "$GREEN"
        exit 0
    fi

    log "Starting Ralph loop for: $TASK_NAME" "$CYAN"
    log "Pending tasks: $pending | Max iterations: $MAX_ITERATIONS | Recursive: $recursive_enabled" "$CYAN"
    if [ "$recursive_enabled" = "true" ]; then
        log "Recursive condition: $(get_recursive_condition)" "$CYAN"
        log "Recursive target: $(get_recursive_target)" "$CYAN"
    fi
    echo ""

    # Main loop
    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        validate_prd

        # Check pending tasks
        pending=$(get_pending_count)
        recursive_enabled=$(get_recursive_enabled)

        if [ "$pending" -eq 0 ] && [ "$recursive_enabled" != "true" ]; then
            echo ""
            log "════════════════════════════════════════════════════════════════" "$GREEN"
            log "  All tasks complete! Finished in $ITERATION iterations." "$GREEN"
            log "════════════════════════════════════════════════════════════════" "$GREEN"
            exit 0
        fi

        if [ "$pending" -eq 0 ] && [ "$recursive_enabled" = "true" ]; then
            log "No pending tasks, but recursive mode is still enabled. Running recursive review..." "$YELLOW"
        fi

        # Run iteration
        run_iteration

        ITERATION=$((ITERATION + 1))

        # Brief pause between iterations
        sleep 1
    done

    # Max iterations reached
    echo ""
    log "════════════════════════════════════════════════════════════════" "$YELLOW"
    log "  Max iterations ($MAX_ITERATIONS) reached." "$YELLOW"
    log "  Completed: $(get_done_count)/$(get_total_count) tasks" "$YELLOW"
    log "  Run again to continue: ./ralph.sh $TASK_NAME" "$YELLOW"
    log "════════════════════════════════════════════════════════════════" "$YELLOW"
}

# Handle interrupt
cleanup() {
    echo ""
    log "Interrupted. Progress saved in prd.json and notes.md" "$YELLOW"
    log "Completed: $(get_done_count)/$(get_total_count) tasks in $ITERATION iterations" "$YELLOW"
    exit 130
}

trap cleanup SIGINT SIGTERM

# Main
main() {
    print_header
    check_dependencies

    # Parse arguments
    TASK_NAME="$1"
    MAX_ITERATIONS="${2:-$DEFAULT_MAX_ITERATIONS}"

    # Interactive selection if no task provided
    if [ -z "$TASK_NAME" ]; then
        select_task
    fi

    # Run the loop
    run_loop
}

main "$@"
