# Status reporting protocol (REQUIRED — append to every subagent prompt)

This protocol is what makes the live dashboard non-empty. Every subagent prompt spawned by the agent-team skill MUST include the section below, with these substitutions made by the orchestrator BEFORE spawning:

- `{AGENT_ID}`     → the short agent id (e.g., `designer`, `art`, `flavor`, `impl`, `reviewer`). Must match a key in `dashboard/status.json`.
- `{MODEL}`        → `opus` / `sonnet` / `haiku` (whatever model this subagent is running on)
- `{PROJECT_ROOT}` → absolute path to the project root (where `dashboard/util.py` lives)

Embed the literal text below into the subagent's prompt (after substitution). Don't paraphrase — the exact bash one-liners matter so subagents know how to call the CLI.

---

## (paste this block into the subagent prompt, with substitutions applied)

**Status reporting (REQUIRED — run these via Bash throughout your work):**

At the very start (before any other work):
```
python3 {PROJECT_ROOT}/dashboard/util.py status {AGENT_ID} running "<起手活動，例如：讀 spec、規劃結構>"
```

At each meaningful milestone (every major sub-task, not every line of code), run BOTH:
```
python3 {PROJECT_ROOT}/dashboard/util.py status {AGENT_ID} running "<目前在做什麼，一句話>"
python3 {PROJECT_ROOT}/dashboard/util.py log {AGENT_ID} {MODEL} "<里程碑，繁體中文，一句話>"
```

At the very end (right before returning your final report):
```
python3 {PROJECT_ROOT}/dashboard/util.py status {AGENT_ID} done "<最終產出摘要>"
```

If you fail / hit a blocker, set status to `error` instead of `done`:
```
python3 {PROJECT_ROOT}/dashboard/util.py status {AGENT_ID} error "<失敗原因>"
```

**Important:**
- Update status frequently enough that the user can tell you're alive (every 30–90 seconds of work)
- Don't spam — log lines are for milestones, not every Read/Edit
- The dashboard polls every 1 second; updates are nearly real-time

---

## How the orchestrator should integrate this

In each subagent prompt you craft, structure it as:

```
[Role description]

[Required reading]

[Concrete task with output paths]

[Constraints]

[Status reporting — paste the substituted block above]

[Final report format]
```

The status reporting block should be near the END of the prompt, but BEFORE the final report instructions, so the agent reads task → status protocol → expected output, in that order.
