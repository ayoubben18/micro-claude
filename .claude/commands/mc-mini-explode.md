# /mc:mini-explode - High-Level Task Explosion

You are exploding a plan into high-level PRD tasks (bigger chunks).

## Your Mission

Read the plan and break it down into major implementation phases. Each task references specific line ranges in `plan.md`.

## Step 1: Identify the Task

If the user provides a task name as argument, use that.
Otherwise, list available tasks in `.micro-claude/` and ask which one to explode.

## Step 2: Read the Plan

Read `.micro-claude/[task-name]/plan.md` thoroughly. Note the line numbers for each section.

## Step 3: Generate PRD JSON

Create `prd.json` with this structure:

```json
{
  "project": "[Task Name]",
  "document": "plan.md",
  "granularity": "mini",
  "recursive": {
    "enabled": false,
    "condition": "",
    "recurseOn": ""
  },
  "tasks": [
    {
      "id": 1,
      "title": "Database Schema & Models",
      "description": "Create database tables and data model",
      "from": 45,
      "to": 78,
      "done": false
    },
    {
      "id": 2,
      "title": "TypeScript Types & Validation",
      "description": "Define interfaces and Zod schemas",
      "from": 80,
      "to": 112,
      "done": false
    }
  ]
}
```

## Task Properties

- **id**: Sequential number starting from 1
- **title**: Clear, action-oriented title
- **description**: Brief description of what this task covers
- **from**: Starting line number in plan.md
- **to**: Ending line number in plan.md
- **done**: Boolean, starts as false

## Recursive Properties

- **recursive.enabled**: Boolean flag for recursive execution mode
- **recursive.condition**: Text describing the stop condition for recursive mode
- **recursive.recurseOn**: Text describing what the agent should recursively revisit

When recursive mode is enabled, `condition` and `recurseOn` must both be non-empty strings. If either is missing, stop and ask the user instead of generating an invalid `prd.json`.

## Step 4: Save and Report

1. Write `prd.json` to `.micro-claude/[task-name]/prd.json`
2. Display summary: total tasks, their titles
3. Suggest: "Run `/mc:explode` for finer granularity, or `/mc:implement` to start"

## Guidelines

- Keep tasks at high level (5-15 tasks typically)
- Each task should map to a coherent section of the plan
- Line ranges should not overlap
- Order tasks logically (database before API, backend before frontend)
- Default `recursive.enabled` to `false` unless the user explicitly wants recursive execution
