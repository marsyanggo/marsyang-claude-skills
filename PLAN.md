# claude-skills — Setup Plan

把個人 Claude Code skills 集中到這個 git repo，跨機器同步、可選擇性公開分享。

---

## 0. 現況

- 4 個 user-level skills 在 `~/.claude/skills/`：
  - `agent-team` — 多 agent 協作 orchestration（含 dashboard 模板）
  - `target` — 專案 TARGET.md 管理
  - `save` — session 進度寫入 SAVE.md
  - `load` — 從 SAVE.md / TARGET.md 復原 session
- 這四個剛好形成一組工作流：`agent-team` 開案 → 中途 `save` / `load` 接續 → `target` 追進度。

---

## 1. 目標 layout

```
~/workspace/claude-skills/         ← 這個 repo（git tracked）
├── README.md                      ← 給自己 / 給訪客看的說明
├── PLAN.md                        ← 本檔（setup 完成後可刪 or 留作歷史）
├── install.sh                     ← 一鍵 symlink 到 ~/.claude/skills/
├── uninstall.sh                   ← 還原（移除 symlink）
├── .gitignore
└── skills/
    ├── agent-team/
    │   ├── SKILL.md
    │   └── templates/
    ├── target/
    │   └── SKILL.md
    ├── save/
    │   └── SKILL.md
    └── load/
        └── SKILL.md
```

**為什麼把 skills 放在 `skills/` 子資料夾**：repo 未來能擴成完整的「Claude Code 個人配置」repo，可加 `commands/`、`agents/`、`hooks/`、`keybindings.json`、`settings.json` 等。也方便未來轉成正式 plugin 格式（plugin 規格 skills 就放 `skills/`）。

---

## 2. 待執行步驟

### 2.1 搬檔 + symlink
```
# 1. 搬 skill 過來
mv ~/.claude/skills/agent-team  ~/workspace/claude-skills/skills/
mv ~/.claude/skills/target      ~/workspace/claude-skills/skills/
mv ~/.claude/skills/save        ~/workspace/claude-skills/skills/
mv ~/.claude/skills/load        ~/workspace/claude-skills/skills/

# 2. symlink 回去
ln -s ~/workspace/claude-skills/skills/agent-team  ~/.claude/skills/agent-team
ln -s ~/workspace/claude-skills/skills/target      ~/.claude/skills/target
ln -s ~/workspace/claude-skills/skills/save        ~/.claude/skills/save
ln -s ~/workspace/claude-skills/skills/load        ~/.claude/skills/load

# 3. 驗證 Claude Code 還抓得到 skill
ls -la ~/.claude/skills/   # 應該看到 4 個 symlink → workspace
```

### 2.2 寫 install.sh（給未來新機器用）
要點：
- 掃 `./skills/*/`，每個資料夾在 `~/.claude/skills/<name>` 建 symlink
- 若 target 已存在：
  - 是同樣的 symlink → skip
  - 是其他 symlink / 真實檔案 → 備份成 `.bak.<timestamp>` 再 symlink（不靜默覆蓋）
- 不需要 sudo
- 印出每個動作，最後一行確認結果
- 加 `--dry-run` flag（先看會做什麼，不真的動）

### 2.3 寫 uninstall.sh
- 掃 `~/.claude/skills/`，若 symlink 指向本 repo 就 `rm`（不動其他 symlink）

### 2.4 .gitignore
```
.DS_Store
*.bak.*
*.swp
__pycache__/
```

### 2.5 README.md（給訪客看）
- 一句話介紹
- 4 個 skill 各一行說明（從 SKILL.md 的 description 抓）
- 安裝：`git clone … && bash install.sh`
- 使用：說明每個 skill 怎麼觸發（`/agent-team`、`/target` 等）
- License（待決定）

### 2.6 git init + push
```
cd ~/workspace/claude-skills
git init
git add .
git commit -m "initial commit: 4 personal Claude Code skills"
gh repo create <name> --public --source=. --push   # 或先建 GitHub repo 再 git push
```

---

## 3. 待決定（請使用者回答）

| # | 問題 | 選項 / 預設 |
|---|---|---|
| Q1 | Repo 名稱 | `claude-skills` / `dotclaude` / 其他 |
| Q2 | GitHub repo 公開或私有 | public（可給人用）/ private（純備份） |
| Q3 | License | MIT（標準分享）/ 不寫（保留所有權）/ 其他 |
| Q4 | install.sh 行為 | 互動式（每個衝突問一次） / 預設備份不問 / 預設覆蓋 |
| Q5 | GitHub username/org | 拿來組 repo URL |
| Q6 | 要不要加 plugin manifest（`.claude-plugin/plugin.json`）讓人能用 `/plugin install <url>` | 現在加 / 之後再加 |

---

## 4. 後續延伸想法（不一定現在做）

### 4.1 擴成完整個人 Claude 配置 repo
未來可加：
- `commands/` — 自訂 slash commands（若有）
- `agents/` — 自訂 subagent 定義
- `hooks/` — 事件 hook scripts
- `keybindings.json` — 鍵位設定（也放進 install.sh）
- `settings.json` template（**注意過濾 secret / OAuth token / API key / 機器特定路徑**）

### 4.2 升級成 Claude Code plugin
在 repo 根加 `.claude-plugin/plugin.json`：
```json
{
  "name": "marsyang-skills",
  "version": "0.1.0",
  "description": "Personal Claude Code skills: agent-team orchestration + session continuity",
  "skills": ["skills/agent-team", "skills/target", "skills/save", "skills/load"]
}
```
之後別人就能 `/plugin install <git-url>`，不用 clone + symlink。本 repo layout 已經跟 plugin 相容，無痛升級。

### 4.3 CI 檢查
GitHub Actions 跑：
- `python3 skills/agent-team/templates/dashboard/util.py --help` 能不能跑
- 每個 SKILL.md 有正確 frontmatter（name, description）
- README 列出的 skill 跟實際 skills/ 內的對得上

### 4.4 Versioning
- 用 git tag 標版本（v0.1, v0.2...）
- 每個 skill SKILL.md 內也標 version（讓 changelog 好寫）

### 4.5 文件 / 範例
- `examples/` 放 agent-team 跑過的成品（例如本次的賽馬遊戲 spec.md + QA report）當 demo
- 可選：每個 skill 一個短 demo 影片或 GIF

---

## 5. 風險 / 要小心的事

- **誤覆蓋**：install.sh 一定要備份不靜默 overwrite，避免把使用者本地客製化的 skill 蓋掉。
- **Symlink 在某些工具下行為怪**：例如 finder 拖拽、某些 backup 工具。一般 dev 環境沒事。
- **跨平台**：install.sh 預設 macOS / Linux。Windows 要另外處理（PowerShell 版 install.ps1，或者教使用者用 WSL）。
- **Secret 外洩**：未來若加 `settings.json` 進 repo，必須先洗掉 OAuth token / API key / 機器特定路徑（如 `/Users/marsyang/...`）。可寫 `settings.template.json` + `.gitignore` 真的 settings.json。
- **Skill 內部依賴**：例如 `agent-team` 用了 `python3`，README 要列依賴；未來若有跨 skill 互相引用要注意路徑不能寫死絕對路徑。

---

## 6. 完成定義 (Definition of Done)

第一階段（本次要做的）：
- [ ] 4 個 skill 搬到 `~/workspace/claude-skills/skills/`
- [ ] symlink 回 `~/.claude/skills/`，新 session 還能正常用 `/agent-team` 等指令
- [ ] install.sh 可在 dry-run 跟實跑兩種模式運作
- [ ] uninstall.sh 能還原
- [ ] README 寫好
- [ ] git init + 第一個 commit

第二階段（之後再說）：
- [ ] 推到 GitHub
- [ ] 加 plugin manifest
- [ ] 加 CI

---

_Last updated: 2026-05-07_
