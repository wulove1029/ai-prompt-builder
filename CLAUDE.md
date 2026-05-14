# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# AI Prompt Builder — Claude Code Configuration

## Project Overview

**AI Prompt Builder** — 用 PyQt6 製作的桌面 GUI，讓使用者從左側選擇 gstack/Ruflo skill，填入欄位後於右側即時預覽 prompt，一鍵複製到剪貼簿。

### 架構（單檔 `gstack_prompt_builder.py`，約 4,000+ 行）

| 區塊（行號） | 說明 |
|---|---|
| 1–47 | gstack 安裝路徑偵測、版本讀取（`GSTACK_ROOT`, `GSTACK_VERSION`） |
| 48–977 | App 圖示（base64 PNG 嵌入，免外部檔案） |
| 978–1020 | 主題色盤定義（`DARK_THEME` / `LIGHT_THEME`，Catppuccin Mocha/Latte） |
| 1025–2986 | **`SKILLS` 字典** — 所有 skill 的 `role`/`desc`/`when`/`template` 資料，以及自動掃描 gstack 安裝目錄補充未中文化 skill 的邏輯 |
| 2987–3220 | UI/UX Pro Max 專屬 skill 條目 |
| 3235–3250 | `_build_group_skills()` — 將群組標題（`None` value）與 skill 條目分離 |
| 3254–3261 | `_PlainTextEdit` — 覆寫貼上行為，只插入純文字 |
| 3267–3281 | `_GStackVersionChecker(QThread)` — 背景抓取遠端版本，有新版時 emit `update_available` |
| 3287–4078 | **`GStackPromptBuilder(QMainWindow)`** — 主視窗：左欄 skill 選單 + 欄位輸入，右欄即時 preview，深/淺色主題切換 |
| 4082–4092 | `main()` 入口 |

### SKILLS 資料格式

```python
SKILLS["/skill-name"] = {
    "role": "顯示在 UI 的角色名",
    "desc": "簡短說明",
    "when": "適用情境",
    "template": "含 {project} {branch} {task} {extra_instructions} 的 prompt 模板",
}
SKILLS["── 群組標題 ──"] = None  # 作為 combo box 分隔
```

新增 skill 只需在 `SKILLS` 字典插入新條目，UI 會自動重整。

### 打包

使用 PyInstaller 打包成單一 `.exe`，設定在 `gstack Prompt Builder.spec`（icon 指定 `app_icon.ico`，`console=False`）。

```bash
pyinstaller "gstack Prompt Builder.spec"
```

### 執行（開發模式）

```bash
python gstack_prompt_builder.py
```

依賴：`PyQt6`（需事先安裝）。

## Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary — prefer editing existing files
- NEVER create documentation files unless explicitly requested
- NEVER save working files or tests to root — use `/src`, `/tests`, `/docs`, `/config`, `/scripts`
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- Keep files under 500 lines
- Validate input at system boundaries

## Agent Comms (SendMessage-First Coordination)

Named agents coordinate via `SendMessage`, not polling or shared state.

```
Lead (you) ←→ architect ←→ developer ←→ tester ←→ reviewer
              (named agents message each other directly)
```

### Spawning a Coordinated Team

```javascript
// ALL agents in ONE message, each knows WHO to message next
Agent({ prompt: "Research the codebase. SendMessage findings to 'architect'.",
  subagent_type: "researcher", name: "researcher", run_in_background: true })
Agent({ prompt: "Wait for 'researcher'. Design solution. SendMessage to 'coder'.",
  subagent_type: "system-architect", name: "architect", run_in_background: true })
Agent({ prompt: "Wait for 'architect'. Implement it. SendMessage to 'tester'.",
  subagent_type: "coder", name: "coder", run_in_background: true })
Agent({ prompt: "Wait for 'coder'. Write tests. SendMessage results to 'reviewer'.",
  subagent_type: "tester", name: "tester", run_in_background: true })
Agent({ prompt: "Wait for 'tester'. Review code quality and security.",
  subagent_type: "reviewer", name: "reviewer", run_in_background: true })

// Kick off the pipeline
SendMessage({ to: "researcher", summary: "Start", message: "[task context]" })
```

### Patterns

| Pattern | Flow | Use When |
|---------|------|----------|
| **Pipeline** | A → B → C → D | Sequential dependencies (feature dev) |
| **Fan-out** | Lead → A, B, C → Lead | Independent parallel work (research) |
| **Supervisor** | Lead ↔ workers | Ongoing coordination (complex refactor) |

### Rules

- ALWAYS name agents — `name: "role"` makes them addressable
- ALWAYS include comms instructions in prompts — who to message, what to send
- Spawn ALL agents in ONE message with `run_in_background: true`
- After spawning: STOP, tell user what's running, wait for results
- NEVER poll status — agents message back or complete automatically

## Swarm & Routing

### Config
- **Topology**: hierarchical-mesh (anti-drift)
- **Max Agents**: 15
- **Memory**: hybrid
- **HNSW**: Enabled
- **Neural**: Enabled

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized
```

### Agent Routing

| Task | Agents | Topology |
|------|--------|----------|
| Bug Fix | researcher, coder, tester | hierarchical |
| Feature | architect, coder, tester, reviewer | hierarchical |
| Refactor | architect, coder, reviewer | hierarchical |
| Performance | perf-engineer, coder | hierarchical |
| Security | security-architect, auditor | hierarchical |

### When to Swarm
- **YES**: 3+ files, new features, cross-module refactoring, API changes, security, performance
- **NO**: single file edits, 1-2 line fixes, docs updates, config changes, questions

### 3-Tier Model Routing

| Tier | Handler | Use Cases |
|------|---------|-----------|
| 1 | Agent Booster (WASM) | Simple transforms — skip LLM, use Edit directly |
| 2 | Haiku | Simple tasks, low complexity |
| 3 | Sonnet/Opus | Architecture, security, complex reasoning |

## Memory & Learning

### Before Any Task
```bash
npx @claude-flow/cli@latest memory search --query "[task keywords]" --namespace patterns
npx @claude-flow/cli@latest hooks route --task "[task description]"
```

### After Success
```bash
npx @claude-flow/cli@latest memory store --namespace patterns --key "[name]" --value "[what worked]"
npx @claude-flow/cli@latest hooks post-task --task-id "[id]" --success true --store-results true
```

### MCP Tools (use `ToolSearch("keyword")` to discover)

| Category | Key Tools |
|----------|-----------|
| **Memory** | `memory_store`, `memory_search`, `memory_search_unified` |
| **Bridge** | `memory_import_claude`, `memory_bridge_status` |
| **Swarm** | `swarm_init`, `swarm_status`, `swarm_health` |
| **Agents** | `agent_spawn`, `agent_list`, `agent_status` |
| **Hooks** | `hooks_route`, `hooks_post-task`, `hooks_worker-dispatch` |
| **Security** | `aidefence_scan`, `aidefence_is_safe`, `aidefence_has_pii` |
| **Hive-Mind** | `hive-mind_init`, `hive-mind_consensus`, `hive-mind_spawn` |

### Background Workers

| Worker | When |
|--------|------|
| `audit` | After security changes |
| `optimize` | After performance work |
| `testgaps` | After adding features |
| `map` | Every 5+ file changes |
| `document` | After API changes |

```bash
npx @claude-flow/cli@latest hooks worker dispatch --trigger audit
```

## Agents

**Core**: `coder`, `reviewer`, `tester`, `planner`, `researcher`
**Architecture**: `system-architect`, `backend-dev`, `mobile-dev`
**Security**: `security-architect`, `security-auditor`
**Performance**: `performance-engineer`, `perf-analyzer`
**Coordination**: `hierarchical-coordinator`, `mesh-coordinator`, `adaptive-coordinator`
**GitHub**: `pr-manager`, `code-review-swarm`, `issue-tracker`, `release-manager`

Any string works as a custom agent type.

## UI/UX Pro Max Skill

AI 驅動的設計智能技能，提供 67 種 UI 風格、161 種色彩方案、57 種字型配對、99 條 UX 準則。

### 何時使用

**必須使用**：頁面設計、元件建立/重構、色彩/字型選擇、UI 程式碼審查、導覽實作、任何影響「功能外觀、體驗或互動」的任務。

**略過**：後端邏輯、API 設計、基礎設施、非視覺自動化。

### 啟動方式

```
/ui-ux-pro-max
```

或直接用自然語言描述：
- `幫我建一個 SaaS 產品的 Landing Page`
- `設計一個儀表板 UI，使用 glassmorphism 風格`
- `選一個適合電商的色彩方案`

### 設計系統生成

```bash
# 完整設計系統（推薦）
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<查詢>" --design-system -p "專案名稱"

# 依領域搜尋
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<查詢>" --domain <領域>

# 依技術棧搜尋
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<查詢>" --stack <技術棧>
```

### 可用領域 (`--domain`)

| 領域 | 說明 |
|------|------|
| `product` | 產品類型推薦（SaaS、電商、作品集） |
| `style` | UI 風格（玻璃擬態、極簡、粗野主義） |
| `typography` | 字型配對與 Google Fonts 匯入 |
| `color` | 依產品類型的色彩方案 |
| `landing` | 頁面結構與 CTA 策略 |
| `chart` | 圖表類型與函式庫推薦 |
| `ux` | UX 最佳實踐與反模式 |

### 可用技術棧 (`--stack`)

`html-tailwind`、`react`、`nextjs`、`astro`、`vue`、`nuxtjs`、`svelte`、`swiftui`、`react-native`、`flutter`、`shadcn`、`jetpack-compose`

### 技能路由

| 任務類型 | 使用技能 |
|----------|---------|
| UI 設計 + 建置 | `ui-ux-pro-max` |
| 設計系統建立 | `design-consultation` |
| 視覺 QA 審查 | `design-review` |
| 設計方案探索 | `design-shotgun` |
| HTML/CSS 實作 | `design-html` |

### 重要準則

- 圖示使用 SVG，禁止用 Emoji 作為 UI 控制項
- 觸控目標最小 44×44px
- 主要文字對比度 ≥ 4.5:1（含深色模式）
- 間距遵循 4/8dp 節奏
- 動畫時長 150–300ms，僅用 transform

## Build & Test

- ALWAYS run tests after code changes
- ALWAYS verify build succeeds before committing

```bash
npm run build && npm test
```

## CLI Quick Reference

```bash
npx @claude-flow/cli@latest init --wizard           # Setup
npx @claude-flow/cli@latest swarm init --v3-mode     # Start swarm
npx @claude-flow/cli@latest memory search --query "" # Vector search
npx @claude-flow/cli@latest hooks route --task ""    # Route to agent
npx @claude-flow/cli@latest doctor --fix             # Diagnostics
npx @claude-flow/cli@latest security scan            # Security scan
npx @claude-flow/cli@latest performance benchmark    # Benchmarks
```

26 commands, 140+ subcommands. Use `--help` on any command for details.

## Setup

```bash
claude mcp add claude-flow -- npx -y @claude-flow/cli@latest
npx @claude-flow/cli@latest daemon start
npx @claude-flow/cli@latest doctor --fix
```

**Agent tool** handles execution (agents, files, code, git). **MCP tools** handle coordination (swarm, memory, hooks). **CLI** is the same via Bash.
