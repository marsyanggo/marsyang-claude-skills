---
name: load
description: Load last session's progress on startup. Reads SAVE.md for session context and TARGET.md for remaining tasks, then outputs a concise summary and incomplete task list. Use when the user invokes /load to resume work.
---

# Load — Session Resume

Read the last saved progress and give the user a quick briefing so they can pick up where they left off.

## How to behave

- Both files live at `<project-root>/` — use the current working directory as the project root
- Read both files in parallel before generating any output
- Be concise — this is a briefing, not a full dump
- Output in Traditional Chinese (same language as TARGET.md)

## Workflow

### Step 1 — Read both files

Read `SAVE.md` and `TARGET.md` simultaneously.

### Step 2 — Generate the briefing

Output the following sections in order:

---

#### 上次 Session 摘要

From the **most recent entry** in `SAVE.md`:
- Date of last session
- What was completed (bullet list, keep it short)
- Session notes / blockers (if any)
- Where to pick up next

If `SAVE.md` doesn't exist or has no entries: say "找不到 SAVE.md，尚未有 session 記錄。請先跑 /save 儲存進度。"

---

#### 剩餘未完成的 Tasks

From `TARGET.md`, list **only** the unchecked tasks (`- [ ]`), grouped by Goal:

```
## Goal: <goal name>
- [ ] <task>
- [ ] <task>

## Goal: <goal name>
- [ ] <task>
```

Show the count: `共 N 個 tasks 未完成`

If all tasks are done: congratulate the user.

If `TARGET.md` doesn't exist: say "找不到 TARGET.md，請先執行 /target 建立計畫。"

---

#### 建議下一步

Based on:
1. The "下次從這裡繼續" field in SAVE.md
2. The first incomplete task in the current active Goal (infer from context which week/goal is in progress)

Give **one concrete suggestion** of what to work on next. One sentence only.

---

## After the briefing

Ask: 「準備好了嗎？要開始哪個 task？」
