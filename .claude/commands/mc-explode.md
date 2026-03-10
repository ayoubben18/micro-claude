# /mc:explode - Fine-Grained Task Explosion

You are exploding a plan into atomic implementation tasks (small, focused chunks).

## Your Mission

Read the plan and break it down into the smallest actionable tasks. Each task references specific line ranges in `plan.md`.

## Step 1: Identify the Task

If the user provides a task name as argument, use that.
Otherwise, list available tasks in `.micro-claude/` and ask which one to explode.

## Step 2: Read the Plan

Read `.micro-claude/[task-name]/plan.md` thoroughly. Note the line numbers for each requirement, field, endpoint, component, etc.

## Step 3: Generate PRD JSON

Create `prd.json` with this structure:

```json
{
  "project": "[Task Name]",
  "document": "plan.md",
  "granularity": "full",
  "recursive": {
    "enabled": false,
    "condition": "",
    "recurseOn": ""
  },
  "tasks": [
    {
      "id": 1,
      "title": "Create stores table in schema",
      "description": "Add stores table with id, userId, content JSONB, status enum, timestamps",
      "from": 45,
      "to": 52,
      "done": false
    },
    {
      "id": 2,
      "title": "Define StoreContent Zod schema",
      "description": "Create Zod schema for store content with header, hero, products sections",
      "from": 54,
      "to": 89,
      "done": false
    },
    {
      "id": 3,
      "title": "Create StoreDTO type",
      "description": "Define DTO for API responses with store data and computed fields",
      "from": 91,
      "to": 98,
      "done": false
    }
  ]
}
```

## Task Properties

- **id**: Sequential number starting from 1
- **title**: Specific, atomic action (create X, add Y, implement Z)
- **description**: One sentence explaining what exactly to do
- **from**: Starting line number in plan.md
- **to**: Ending line number in plan.md
- **done**: Boolean, starts as false

## Recursive Properties

- **recursive.enabled**: Boolean flag for recursive execution mode
- **recursive.condition**: Text describing the stop condition that must be satisfied before recursive mode can end
- **recursive.recurseOn**: Text describing what the agent should keep re-evaluating recursively

If recursive mode is not needed, set:

```json
"recursive": {
  "enabled": false,
  "condition": "",
  "recurseOn": ""
}
```

If recursive mode is enabled, both `condition` and `recurseOn` are required. Do not write an invalid `prd.json`; stop and ask the user for the missing value instead.

## Step 4: Save and Report

1. Write `prd.json` to `.micro-claude/[task-name]/prd.json`
2. Display summary: total tasks count, first 10 task titles
3. Suggest: "Run `/mc:implement` to start implementation"

## Guidelines

- Make tasks atomic (one file, one function, one component)
- Typically 20-50 tasks for a medium feature
- Each task should be completable in one focused session
- Line ranges can be small (even 3-5 lines for a specific field)
- Order tasks by implementation dependency (schema before types, types before services)
- Be granular: "Create header section schema" not "Create all sections"
- If the user wants recursive execution, encode it in `recursive`; otherwise keep it disabled by default
