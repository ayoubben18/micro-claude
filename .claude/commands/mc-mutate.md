# /mc:mutate - Extend & Modify Plans

You are helping the user extend, modify, or fix an existing plan and PRD. This is an interactive loop that continues until the user is satisfied.

## Your Mission

Load existing artifacts, understand what the user wants to change, update the documents, and loop until done.

## Step 1: Identify the Task

If the user provides a task name as argument, use that.
Otherwise, list available tasks in `.micro-claude/` and ask which one to mutate.

## Step 2: Load Current State

Read all three artifacts:
1. `.micro-claude/[task-name]/plan.md` - The full specification
2. `.micro-claude/[task-name]/prd.json` - The task breakdown
3. `.micro-claude/[task-name]/notes.md` - Implementation notes (if exists)

Display a brief summary:
- Plan sections overview
- Task count: X total, Y completed, Z pending
- Last implemented task (from notes)
- Recursive mode status: enabled/disabled, condition, recurseOn

## Step 3: Ask What to Mutate

Present mutation options to the user:

**What would you like to do?**
1. **Add something new** - New requirement, field, endpoint, component, etc.
2. **Modify existing** - Change a requirement, update a field type, rename something
3. **Remove something** - Delete a requirement that's no longer needed
4. **Fix a mistake** - Correct an error in the plan
5. **Clarify something** - Add more detail to an ambiguous section
6. **Update recursive behavior** - Change whether execution should recurse, on what, and until which condition

Wait for the user's choice.

## Step 4: Deep Dive on the Change

Based on their choice, ask targeted follow-up questions:

### For "Add something new":
1. **What section does this belong to?** (Data Model, API, UI, etc.)
2. **Describe what you want to add in detail**
3. **Does this relate to existing items?** (Dependencies, relationships)
4. **Are there edge cases to consider?**

### For "Modify existing":
1. **Which section/item needs modification?** (Show relevant parts of plan)
2. **What's the current state vs desired state?**
3. **Does this change affect other parts?** (Cascading impacts)

### For "Remove something":
1. **What should be removed?** (Show relevant parts)
2. **Is anything dependent on this?** (Check for breaking changes)
3. **Should related tasks be removed from PRD?**

### For "Fix a mistake":
1. **Where is the mistake?** (Section, line numbers)
2. **What's wrong and what should it be?**
3. **Were any tasks already implemented based on this mistake?**

### For "Clarify something":
1. **Which part is ambiguous?**
2. **What additional detail can you provide?**
3. **Any examples that would help?**

Wait for answers before proceeding.

## Step 5: Propose Changes

Show the user exactly what will change:

```markdown
## Proposed Changes to plan.md

### Section: [Section Name]

**Current** (lines X-Y):
```
[existing content]
```

**New**:
```
[proposed content]
```

### Impact on PRD

- Tasks to ADD: [list new tasks if any]
- Tasks to MODIFY: [list affected tasks]
- Tasks to REMOVE: [list obsolete tasks]
```

Ask: **Does this look correct? (yes/no/adjust)**

## Step 6: Apply Changes

If approved:

1. **Update plan.md**:
   - Insert new sections where appropriate
   - Modify existing lines
   - Maintain line number references for existing PRD tasks (or note if they shift)

2. **Update prd.json**:
   - Add new tasks with sequential IDs continuing from highest existing ID
   - Update `from`/`to` line numbers if content shifted
   - Mark removed requirements' tasks as appropriate
   - Keep `done` status for existing tasks
   - Validate `recursive`: if `enabled` is `true`, require both `condition` and `recurseOn`

3. **Update notes.md**:
   - Add a mutation log entry:
   ```markdown
   ## Mutation - [Date/Time]
   **Type**: [Add/Modify/Remove/Fix/Clarify]
   **Summary**: [Brief description of what changed]
   **Plan changes**: [Lines affected]
   **PRD changes**: [Tasks added/modified/removed]
   ```

## Step 7: Loop

After applying changes, ask:

```
Changes applied successfully!

- Plan updated: [X sections modified]
- PRD updated: [Y tasks added, Z tasks modified]

**Want to make more changes?** (yes/no)
```

If yes, go back to Step 3.
If no, display final summary and suggest next steps.

## Final Summary

When exiting, show:

```markdown
## Mutation Session Complete

### Plan Changes
- [List of sections added/modified]

### PRD Status
- Total tasks: X
- Completed: Y
- Pending: Z
- New tasks added this session: N

### Next Steps
- Run `/mc:implement` to continue implementation
- Run `/mc:mutate` again if you think of more changes
```

## Guidelines

- Always show before/after for changes
- Preserve existing task IDs and completion status
- New tasks get IDs continuing from the highest existing ID
- If line numbers shift, update ALL affected task references in prd.json
- Be careful with cascading impacts - one change might affect multiple tasks
- Keep the mutation log in notes.md for traceability
- Ask clarifying questions rather than assuming
- Loop until user explicitly says they're done
