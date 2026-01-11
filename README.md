# Micro-Claude

A structured AI-driven development method for Claude Code that interrogates, plans, and implements features through task decomposition.

## Philosophy

Micro-Claude transforms vague feature requests into well-structured implementation plans:

1. **Interrogate** - Deep questioning to extract comprehensive requirements
2. **Explode** - Break down plans into trackable tasks with line references
3. **Implement** - Execute tasks while maintaining detailed notes

The model can loop and pick any task it sees fit based on context and dependencies.

## Installation

```bash
npx micro-claude
```

This installs the slash commands in your project's `.claude/commands/` directory.

## Commands

### `/mc:interrogate`

Starts a deep interrogation session to create a comprehensive plan.

**Flow:**
1. Asks for feature/task name
2. Phases of questions: Core Identity, Functional Requirements, Technical Context, Edge Cases, Success Criteria
3. Generates `plan.md` with all specifications

**Output:** `.micro-claude/[task-name]/plan.md`

### `/mc:mini-explode`

Explodes the plan into high-level tasks (bigger chunks).

**Output:** `.micro-claude/[task-name]/prd.json` with ~5-15 tasks

### `/mc:explode`

Explodes the plan into fine-grained atomic tasks.

**Output:** `.micro-claude/[task-name]/prd.json` with ~20-50 tasks

### `/mc:implement`

Implements tasks in a loop while maintaining notes.

**Flow:**
1. Reads `prd.json` and `notes.md` for context
2. Picks or suggests next task
3. Reads relevant section from `plan.md` (using `from`/`to` line numbers)
4. Implements the task
5. Updates `notes.md` with implementation details
6. Marks task as `done` in `prd.json`
7. Loops or exits

## File Structure

```
.micro-claude/
└── [task-name]/
    ├── plan.md     # Comprehensive specifications from interrogation
    ├── prd.json    # Task definitions with line references
    └── notes.md    # Implementation notes by task ID
```

### prd.json Format

```json
{
  "project": "feature-name",
  "document": "plan.md",
  "granularity": "full",
  "tasks": [
    {
      "id": 1,
      "title": "Create database schema",
      "description": "Add tables for the feature",
      "from": 45,
      "to": 62,
      "done": false
    }
  ]
}
```

### notes.md Format

```markdown
# Implementation Notes - Feature Name

## Task #1: Create database schema
**Status**: Completed
**Files**: db/schema.ts
**Notes**:
- Added stores table with JSONB content
- Used uuid for primary key
```

## Workflow Example

```bash
# 1. Start interrogation
/mc:interrogate
# Answer all questions about your feature
# → Creates .micro-claude/my-feature/plan.md

# 2. Explode into tasks
/mc:explode
# → Creates .micro-claude/my-feature/prd.json

# 3. Implement
/mc:implement
# → Implements tasks, updates notes.md, marks done
```

## License

MIT
