---
name: agent-team
description: Orchestrate a multi-model agent team end-to-end (design → parallel build → QA → iterate) with a live observability dashboard. Use when the user invokes /agent-team for a non-trivial project that benefits from splitting work across roles (Designer, Implementer, Reviewer, etc.) with different Claude models. Sets up dashboard, locks specs, spawns phases in parallel, integrates QA, and drives the iteration loop.
---

# agent-team — Multi-Agent Project Orchestrator

Drive a project from idea to v1 by orchestrating multiple specialized subagents (different roles, different Claude models), with a live HTTP dashboard so the user can watch parallel work in real time.

## When to use

User invokes `/agent-team <project description>` for projects that:
- Span design, multiple implementation areas, content, and QA
- Benefit from parallel work + different model strengths (Opus / Sonnet / Haiku)
- Take more than a few minutes total (otherwise the orchestration overhead exceeds value)

Good fits: web apps/games, internal tools with backend/frontend/content/tests, prototyping a new feature with design+impl+review.

Skip if: single-file edit, single-concept question, trivial refactor.

## Core principles (DO NOT VIOLATE)

1. **Pre-flight role planning before spawning** — never spawn a subagent until the user has confirmed the role/model table. Spawning without a plan = chaos.
2. **Lock specs as contracts** — Phase 1 produces the API/schema contracts that downstream parallel agents code against. Without this, parallel agents drift and integration breaks.
3. **Status-reporting protocol baked into every subagent prompt** — the dashboard is empty without it. Every subagent prompt MUST include the boilerplate from `templates/status_protocol.md`.
4. **Reviewer is a separate role** — never let the implementer "also test." Spawn an explicit Reviewer with simulation/review tasks. Reviewer does NOT modify code, only reports.
5. **Iterate; don't ship raw** — after Phase 3 surface findings to user, ask scope of fixes, apply, optionally re-validate.

## Workflow

### Step 1 — Capture the project

Parse `/multi-agent` arguments.
- If empty: ask user "想做什麼專案？一句話描述（例如：'做個 CLI 的 markdown linter'）"
- If non-trivial enough to justify the workflow: continue. If trivial: tell user it's overkill, suggest doing it directly.

Then ask 2–3 clarifying questions (no more):
- 技術選型偏好？（語言 / 框架 / 部署環境）
- 目標環境？（CLI / Web / 函式庫 / mobile）
- 任何硬限制？（不能用外部套件 / 必須離線 / 等）

### Step 2 — Propose role + model table

Output a markdown table for user confirmation. Pick from this catalog by project nature; remove rows that don't apply, add rows that do.

| 角色 | Model | 為什麼用這個 model | 典型負責 |
|---|---|---|---|
| Game / Product Designer | Opus | 規劃、平衡、深度推理 | 規則、架構、API 契約、資料 schema |
| Architect / Tech Lead | Opus | 系統設計需要深思 | 模組切分、依賴拓樸、資料流 |
| Implementer | Sonnet | 主力實作 CP 值最高 | 主程式 / 多檔案整合 |
| Frontend / UI | Sonnet | UI code 量大但模式固定 | HTML/CSS/JS、組件 |
| Visuals / Art Director | Opus | 創意 + 程式並重 | SVG/Canvas、視覺、動畫 |
| Sound / Audio | Sonnet | Web Audio API 偏程式 | 音效合成、BGM |
| Backend / API | Sonnet | 邏輯實作 | server / API / DB schema |
| Content / Flavor Writer | Haiku | 量大簡單，快又便宜 | 文案、命名、敘事、測試資料 |
| Test Data Generator | Haiku | 重複性高 | fixtures、seed data |
| Reviewer / QA | Sonnet | 讀 code + 跑驗證 | spec 對照、模擬、bug report |
| Security Reviewer | Sonnet | 同上 | 輸入驗證、XSS/injection、secrets |
| Performance Analyst | Sonnet | 同上 | 跑 benchmark、找 hotspot |

Default model assignment heuristic:
- **Opus** → 規劃、創意、深度推理（**少**而**重**的工作）
- **Sonnet** → 實作、QA、多數 worker 角色（**主力**）
- **Haiku** → 大量重複/簡單內容（**多**而**輕**的工作）

After showing the table, ask: "確認這個角色配置？想加減 / 換 model？"

### Step 3 — Propose phase pipeline

Output a phase pipeline. Standard 3-phase pattern:

```
Phase 1 (並行)：Designer + 任何不依賴 spec 的 content 角色 (e.g., Flavor Writer)
                       ↓ spec lock
Phase 2 (並行)：所有 implementation 角色，全部 code against Phase 1 的 spec
                       ↓ 整合驗證
Phase 3 (序列)：Reviewer / QA → 產出報告
                       ↓
Iteration：使用者決定修哪些
```

Variations:
- 純後端專案：Phase 2 可能只有 1–2 個 agent，可考慮合併 phase
- 大型專案：Phase 2 可能拆成 2a (核心) → 2b (整合) 兩 step
- 沒視覺的專案：拿掉 Visuals 角色

Confirm with user before proceeding.

### Step 4 — Bootstrap dashboard

Copy templates to `<project-root>/dashboard/`:

```bash
mkdir -p <project>/dashboard
cp ~/.claude/skills/multi-agent/templates/dashboard/index.html <project>/dashboard/
cp ~/.claude/skills/multi-agent/templates/dashboard/util.py <project>/dashboard/
chmod +x <project>/dashboard/util.py
: > <project>/dashboard/log.jsonl
```

Generate `dashboard/status.json` from the agreed role table. Schema:
```json
{
  "phase": 0,
  "phaseLabel": "等待開工",
  "agents": {
    "<short_id>": {
      "name": "<display name>",
      "model": "opus|sonnet|haiku",
      "role": "<one-line responsibility>",
      "status": "idle",
      "activity": "",
      "startedAt": null,
      "endedAt": null
    }
    // ... one entry per role
  }
}
```

Use short ids (e.g., `designer`, `art`, `flavor`, `impl`, `reviewer`) — these become the keys agents pass to `util.py status <id> ...`.

Start a local HTTP server **rooted at the project root** (NOT at `dashboard/`), so future subdirectories like `app/`, `game/`, `src/` are also serveable:

```bash
cd <project-root> && python3 -m http.server 8765
```

Run in background. Tell user the URL: `📊 Dashboard: http://localhost:8765/dashboard/`

If port 8765 is taken, try 8766, 8767… and tell user the chosen port.

### Step 5 — Set up TARGET.md

Either invoke `/target` skill or write `<project>/TARGET.md` directly. Structure:

```markdown
# Project Targets

_Last updated: YYYY-MM-DD_

**Project:** <one-line description>

**角色 / Model 配置：** <reproduce the agreed table>

---

## Goal: Phase 0 — Dashboard & 基礎設施
- [x] dashboard/index.html, status.json, log.jsonl, util.py
- [x] HTTP server (port N) 起好

## Goal: Phase 1 — <Phase 1 name> (並行)
- [ ] Spawn <agent A> → <output path>
- [ ] Spawn <agent B> → <output path>
- [ ] 同一 message 並行 spawn

## Goal: Phase 2 — <Phase 2 name> (並行)
- [ ] Spawn <agent C> → <output>
- [ ] ...

## Goal: Phase 3 — QA / 收尾
- [ ] Spawn Reviewer → <project>/QA_REPORT.md
- [ ] 整理 P0/P1/P2 清單
- [ ] 修 + 重驗
```

This makes `/save` `/load` work across sessions.

### Step 6 — Phase 1: Spec lock

Update dashboard:
```bash
python3 dashboard/util.py phase 1 "Phase 1 — <names> 並行"
python3 dashboard/util.py status <each_agent> running "spawning..."
```

Spawn all Phase 1 agents **in a single message with multiple Agent tool calls** (this is how Claude Code actually parallelizes).

For each subagent prompt, include these REQUIRED sections:
1. **Role & context** — who they are, what project, who else is on the team
2. **Required reading** — paths to read first (none in Phase 1 since spec doesn't exist yet)
3. **Concrete task** — exact output path + format
4. **Constraints** — tech stack, no external deps, etc.
5. **For Designer specifically: spec.md MUST include**
   - Game/product flow
   - Data schemas (with locked field names)
   - Module API contracts (e.g., `window.X` exposes which methods)
   - Tech architecture decisions (with justification)
   - Any inter-agent contracts (e.g., what Flavor Writer's JSON shape must be — write this in the Designer's spec, not just in your prompt)
6. **Status-reporting protocol** — append the contents of `templates/status_protocol.md` (substituting agent_id and model)
7. **Final report format** — usually 150–200 words, traditional Chinese, key decisions / risks / open questions

After Phase 1 completes:
- **Read the spec output yourself.** Don't just trust the agent's summary.
- Verify schemas, API contracts are concrete enough for Phase 2 agents to code against
- If anything is missing, decide: ask the same agent (via SendMessage to `agentId`) to extend, OR fill the gap yourself
- **Cross-check Phase 1 outputs against each other** — e.g., does the data file the content writer produced match the schema the designer locked? If not, fix BEFORE Phase 2 spawns. (We hit this exact bug: horses.json was a bare array but spec said wrapped.)

### Step 7 — Phase 2: Build (parallel)

Update dashboard, then spawn all Phase 2 agents in one message with parallel Agent tool calls.

For each Phase 2 subagent prompt:
1. **Required reading FIRST** — exact paths to spec.md sections + Phase 1 outputs
2. **API contract excerpt** embedded directly in prompt (don't make them search)
3. **Important context about parallel agents** — list other Phase 2 agents and what they're producing in parallel; tell them NOT to read those files (may not exist yet)
4. **Concrete task** — exact output path
5. **Status-reporting protocol** (from template)
6. **Final report format**

After all Phase 2 agents complete, verify:
- All expected files exist
- All paths are reachable via the HTTP server (not 404 due to wrong server root)
- Quick sanity: load HTML in `curl`, check no obvious syntax errors

### Step 8 — Phase 3: QA

Spawn Reviewer with:
- Paths to ALL artifacts (spec, code, content)
- Specific testing tasks:
  - Spec compliance check (each spec clause → pass/fail/partial)
  - Logic/sim soundness (run the simulation/logic in isolation if possible — `python3` if `node` not available)
  - Browser smoke test (only if Playwright/Chrome headless available — otherwise say so explicitly)
  - Code quality / risks (memory leaks, error handling, edge cases, security)
  - UX evaluation (from reading code)
- Write report to `<project>/QA_REPORT.md` with sections: 總結, Spec 一致性, 模擬統計, Bug 清單 (P0/P1/P2 + steps + fix suggestion + file:line), UX 觀察, 建議下一步
- **Reviewer MUST NOT modify code** — only report
- Status protocol included

### Step 9 — Iterate

Read the QA report. Surface to user a concise summary + ask:
- 修全部 P0/P1?
- 只修 P0?
- 連 P2 一起?
- 自選?
- 不修，標記為 v0.1?

Apply fixes:
- **Small focused fix** (1–3 file edits): direct edit by main agent, faster
- **Larger fix** (multi-component): spawn Implementer (Sonnet) again with the QA report as input

After fixes, optionally re-spawn Reviewer for a quick re-validation pass (no full report, just regression check on the fixed bugs).

Update TARGET.md as items complete.

## Status reporting protocol

Every subagent prompt MUST end with the status-reporting boilerplate. Substitute these variables:
- `{AGENT_ID}` → the short id (e.g., `designer`)
- `{MODEL}` → `opus` / `sonnet` / `haiku`
- `{PROJECT_ROOT}` → absolute path to project root

Read and embed `templates/status_protocol.md` into the prompt.

## Files in this skill

- `SKILL.md` — this orchestration playbook
- `templates/dashboard/index.html` — auto-refresh observability dashboard (agent-agnostic; reads from status.json)
- `templates/dashboard/util.py` — CLI agents call to push status / log / phase
- `templates/status_protocol.md` — required boilerplate for every subagent prompt

## What this skill does NOT do

- Does NOT invent the project for the user — always asks
- Does NOT pick the tech stack unilaterally — surfaces options, lets user decide
- Does NOT auto-commit or push — user-controlled
- Does NOT silently retry failed agents — surfaces errors
- Does NOT run more than 3 phases of agents without user check-in (unless user explicitly asks for autonomous mode)

## Common pitfalls (learned from prior runs)

- **Schema drift between Phase 1 agents.** If the content writer (e.g., Flavor) produces JSON before the Designer locks the schema, you get mismatches. **Fix:** brief content agents with the locked schema, or run schema-locking agent first sequentially, or accept the cleanup cost.
- **HTTP server root too narrow.** Starting `http.server` inside `dashboard/` means `/game/`, `/app/` 404s later. Always start at project root.
- **Forgetting status protocol** in subagent prompts → empty dashboard → user blind → bad UX. The dashboard's value is 100% dependent on this protocol.
- **Skipping the "read Phase 1 output yourself" step** → drift only discovered when Phase 2 agents fail or produce wrong things.
- **One Reviewer for everything.** Reviewer is great but for big projects consider Security Reviewer + Performance Analyst as separate roles.
