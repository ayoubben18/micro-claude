# /mc:implement - Task Implementation Loop

You are implementing tasks from the PRD while maintaining detailed notes.

## Your Mission

Pick tasks, implement them, update notes, mark as done, and loop.

## Step 1: Identify the Task

If the user provides a task name as argument, use that.
Otherwise, list available tasks in `.micro-claude/` and ask which one to work on.

## Step 2: Load Context

1. Read `.micro-claude/[task-name]/prd.json` to get task list
2. Read `.micro-claude/[task-name]/notes.md` for previous implementation context
3. Read `.micro-claude/[task-name]/plan.md` for full specifications
4. Read `recursive.enabled`, `recursive.condition`, and `recursive.recurseOn` from `prd.json`

If `recursive.enabled` is `true`, both `recursive.condition` and `recursive.recurseOn` must be present. If either is missing, stop and surface an error instead of proceeding.

## Step 3: Select Task to Implement

Show the user pending tasks and either:
- Let them pick a specific task ID
- Auto-select the next logical task (first pending task, respecting implicit dependencies)

## Step 4: Read Task Context

For the selected task:
1. Get the `from` and `to` line numbers
2. Read those specific lines from `plan.md`
3. Review related notes from `notes.md`

## Step 5: Implement

Execute the implementation:
1. Create/modify the necessary files
2. Follow patterns from the codebase
3. Implement exactly what the task describes
4. Test if applicable

## Step 6: Update Notes

Append to `.micro-claude/[task-name]/notes.md`:

```markdown
## Task #[id]: [title]
**Status**: Completed
**Files**: [list of files created/modified]
**Notes**:
- [What was implemented]
- [Key decisions made]
- [Gotchas or things to remember]
```

## Step 7: Mark Task Done

Update `prd.json`:
- Set the task's `done` to `true`

## Step 8: Loop or Exit

Show progress:
```
Progress: [X]/[Total] tasks completed
```

If `recursive.enabled` is `false`, ask the user:
- Continue to next task?
- Pick a specific task?
- Exit implementation?

If `recursive.enabled` is `true`, do a recursive review before offering to exit:
1. Re-read `recursive.condition` and `recursive.recurseOn`
2. Re-assess the codebase, plan, notes, and PRD against that recursive goal
3. If more work is needed, add follow-up tasks to `prd.json` and continue looping
4. If the recursive condition is satisfied, set `recursive.enabled` to `false`, record that decision in `notes.md`, then exit or continue as appropriate

Never exit with `recursive.enabled: true` while the recursive condition is still unmet.

## Notes File Format

The `notes.md` should look like:

```markdown
# Implementation Notes - [Project Name]

## Task #1: Create stores table in schema
**Status**: Completed
**Files**: db/schema.ts
**Notes**:
- Added stores table with JSONB content column
- Used uuid for primary key, foreign key to users
- Status enum: draft, queued, generating, active, failed

## Task #2: Define StoreContent Zod schema
**Status**: Completed
**Files**: types/store-template.ts
**Notes**:
- Created nested schemas for each section
- All colors have defaults
- Used z.infer for TypeScript types
```

## Guidelines

- Always read notes before implementing related tasks
- Keep notes concise but informative
- Include file paths in notes for easy reference
- If blocked, note the blocker and move to another task
- Respect implicit dependencies (schema before types, etc.)
