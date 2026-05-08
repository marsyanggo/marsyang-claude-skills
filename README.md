# marsyang-claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills — multi-agent orchestration plus a small session-continuity workflow.

## Skills

| Skill | Trigger | What it does |
|---|---|---|
| **agent-team** | `/agent-team <project>` | Orchestrate a multi-model agent team end-to-end (design → parallel build → QA → iterate) with a live observability dashboard. |
| **target** | `/target` | Manage project goals and sub-tasks in a local `TARGET.md` file. |
| **save** | `/save` | Write a structured session journal entry to `SAVE.md`, auto-detecting completed tasks from `TARGET.md`. |
| **load** | `/load` | Read `SAVE.md` + `TARGET.md` and brief you on where the last session left off. |

`target` / `save` / `load` are designed to be used together: define goals with `/target`, capture progress with `/save` at the end of a session, resume with `/load` next time. `agent-team` is independent and can be used standalone for non-trivial projects.

## Install

Two ways.

### Option A — Plugin (recommended once Claude Code plugin support is enabled)

```
/plugin install https://github.com/marsyanggo/marsyang-claude-skills
```

### Option B — Symlink script

```
git clone https://github.com/marsyanggo/marsyang-claude-skills.git ~/workspace/claude-skills
cd ~/workspace/claude-skills
bash install.sh
```

`install.sh` symlinks each `skills/<name>/` into `~/.claude/skills/<name>`. If a name already exists there, it is backed up to `<name>.bak.<timestamp>` rather than overwritten silently.

Preview first with `bash install.sh --dry-run`.

### Uninstall

```
bash uninstall.sh
```

Only removes symlinks that point back into this repo — anything else in `~/.claude/skills/` is left alone.

## Layout

```
.
├── README.md
├── LICENSE                       # MIT
├── install.sh                    # symlink skills into ~/.claude/skills/
├── uninstall.sh
├── .claude-plugin/
│   └── plugin.json               # Claude Code plugin manifest
└── skills/
    ├── agent-team/
    │   ├── SKILL.md
    │   └── templates/
    ├── target/SKILL.md
    ├── save/SKILL.md
    └── load/SKILL.md
```

## Requirements

- macOS or Linux (Windows: use WSL, or adapt `install.sh` to PowerShell)
- `agent-team` uses Python 3 for its dashboard server

## License

[MIT](./LICENSE)
