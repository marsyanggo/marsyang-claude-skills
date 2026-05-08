---
name: target
description: Manage project goals and sub-tasks in a local TARGET.md file. Use when the user invokes /target to view, set, or update the current project's goals and broken-down sub-tasks. Creates TARGET.md in the project root if it doesn't exist.
---

# Target — Project Goal Tracker

Manage the current project's goals and sub-tasks stored in `TARGET.md` at the project root.

## How to behave

- Always read `TARGET.md` first (if it exists) before doing anything
- The file lives at `<project-root>/TARGET.md` — use the current working directory as the project root
- Display the current content clearly after any operation
- Keep the file human-readable markdown

## Invocation modes

Parse the user's argument after `/target`:

| Argument | Action |
|---|---|
| _(none)_ | Show current `TARGET.md`, or prompt user to define the first goal if file doesn't exist |
| `add <goal text>` | Append a new top-level goal (with empty sub-task list) |
| `done <task text>` | Mark a matching task or sub-task as done (`[x]`) |
| `reset` | Ask for confirmation, then delete and recreate `TARGET.md` from scratch |
| any other text | Treat as a new goal definition and ask the user if they want to replace or append |

## TARGET.md format

Use this exact markdown structure:

```markdown
# Project Targets

_Last updated: YYYY-MM-DD_

---

## Goal: <goal title>

> <optional one-line description>

### Sub-tasks

- [ ] <sub-task 1>
- [ ] <sub-task 2>
- [x] <completed sub-task>

---

## Goal: <another goal>

...
```

## Workflow

### On `/target` (no argument)

1. Read `TARGET.md`
2. If file exists: display the contents formatted, then ask "Would you like to add a goal, mark a task done, or update the file?"
3. If file doesn't exist: say "No TARGET.md found. What's the main goal for this project?" then after the user answers, create the file using the format above. Ask the user to break it down into sub-tasks.

### On `/target add <goal>`

1. Read existing `TARGET.md` (create if missing)
2. Append the new goal section with an empty sub-task list
3. Prompt: "What sub-tasks should we break this goal into?"
4. After user provides sub-tasks, add them to the file under the goal
5. Update the `_Last updated_` date

### On `/target done <task>`

1. Read `TARGET.md`
2. Find the closest matching task (fuzzy match on text)
3. Change `- [ ]` to `- [x]`
4. Update the `_Last updated_` date
5. Show the updated section

### On `/target reset`

1. Confirm with user before proceeding
2. If confirmed, start fresh: ask for goals and sub-tasks interactively, then write a new `TARGET.md`

## After every write

Show the user the updated `TARGET.md` content in a fenced markdown block so they can verify.
