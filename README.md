# Banyan

> 跨会话任务断点续传的 Agent Skill 套件：把计划与执行现场下沉到本地 Markdown，换模型 / 换 Agent / 重开窗口也能秒级接力。
>
> A cross-session task-continuity skill suite for coding agents: persist plans and execution context to local Markdown, so switching models/agents/windows resumes in seconds.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Skills: 5](https://img.shields.io/badge/skills-5-blue.svg)](skills/)
[![Docs](https://img.shields.io/badge/docs-handbook-orange.svg)](docs/handbook.md)

---

## 中文介绍

### 为什么做 Banyan？

免费模型 Token 额度有限，任务常在中途中断；切换模型 / Agent / 窗口后上下文丢失，新会话往往从零重新规划，浪费大量重复 Token。

Banyan 的解决思路是**外部状态持久化 + 上下文解耦**：不依赖 Agent 会话记忆，把任务状态下沉到本地 Markdown 文件。任何 Agent、任何时候读文件即可接续任务。

### 核心设计

- **双轨文件体系**：`TASK_PLAN.md`（精简状态投影）+ dated 计划文件（本轮详细跟踪表，见 `plan/`）+ `EXEC_LOG.md`（append-only 流水账）。
- **五态状态机**：`⬜ 待开始 / 🟡 进行中 / ✅ 已完成 / ❌ 受阻 / ⏭️ 跳过`，`TASK_PLAN.md` 用 `- [ ] / [-] / [x] / [!] / [s]` 映射，双写原子一致。
- **通用兼容**：Skill frontmatter 只用 `name + description` 交集字段，Claude Code / OpenCode / Codex / Gemini CLI 均可发现加载。
- **渐进披露**：`SKILL.md` 只写指令，长参考放 `references/`、模板放 `templates/`，按需读取省 Token。

### 五个 Skill 一览

| Skill | 职责 | 触发时机 |
|-------|------|----------|
| `banyan-plan-draft` | 起草计划，产出 dated 计划文件 + 初始化 `TASK_PLAN.md` | 收到需求 / "制定计划 / 拆解任务 / 帮我规划" |
| `banyan-plan-track` | 状态机唯一维护者，双写 dated 文件与 `TASK_PLAN.md` | 步骤开始 / 完成 / 受阻 |
| `banyan-gate-verify` | 门禁四段验证（格式/静态/测试/性能数量，含文档型分支） | 步骤完成验收 / "跑一下门禁" |
| `banyan-exec-log` | append-only 流水账，双写 `EXEC_LOG.md` + dated 文末 | 关键操作 / 决策 / "记一下" |
| `banyan-resume` | 断点恢复：三读定位断点并汇报，直接继续 | 新会话 / "继续任务 / 断点恢复" |

闭环：`plan-draft（起草）→ plan-track（开始）→ exec-log（记）→ gate-verify（验收）→ plan-track（完成）→ resume（接力）`。

详见 [`docs/handbook.md`](docs/handbook.md)，常见问题见 [`docs/faq.md`](docs/faq.md)。

### 3 分钟快速开始

> **零安装一句话直驱（首选）**：下面任选一句复制给 AI，不用记命令、不用建链接，Win/mac 通用——AI 自己读 skills 并开工。

本地仓库（已在 Banyan 目录里开 Agent）：

> 请读取本仓库 skills/banyan-plan-draft、banyan-plan-track、banyan-gate-verify、banyan-exec-log、banyan-resume 下的 SKILL.md 并严格遵守其中的任务规划与断点续传协议；然后先出方案再动手：【把你的需求粘在这里】。

新项目（空目录开 Agent，AI 自己 clone）：

> 把 https://github.com/AiToByte/Banyan 克隆到 ./banyan-skills，读取其中 5 个 Skill 的 SKILL.md 并严格遵守其中的任务规划与断点续传协议；然后先出方案再动手：【把你的需求粘在这里】。

> **进阶：自动触发**：想让 Agent 不用读文件自动触发 Skill，再运行下面对应的一行命令（装完脚本会直接给出 5 句可用话）。

```powershell
# Windows（一行命令，/J 免管理员）
powershell -ExecutionPolicy Bypass -File scripts/install-skills.ps1
```

```bash
# macOS / Linux（一行命令，无需 sudo）
bash scripts/install-skills.sh
```

装完先说这句（推荐首句）：**"这个需求先出方案再动手，拆成步骤存下来。"**

然后对 Agent 说：

1. **新任务**："帮我实现 XXX。先制定计划。"→ Agent 触发 `banyan-plan-draft`，在 `plan/` 建 dated 计划 + 初始化 `TASK_PLAN.md`，向你确认后开工。
2. **执行中**：Agent 按 `plan-track` 双写状态、`exec-log` 追加日志、`gate-verify` 跑门禁，全绿才标 `✅`。
3. **中断接力**：新窗口只说"继续任务" → Agent 触发 `banyan-resume`，三读双轨文件，输出断点接力报告并直接继续。

**一句话速查**（复制即用，不用敲 `/命令`；与 `docs/handbook.md` §5 同步）：

| 想做的事 | 直接说这一句 |
|----------|--------------|
| 出方案 | 这个需求先出方案再动手，拆成步骤存下来。 |
| 更新进度 | 这步做完了（/卡住了），进度更新下。 |
| 验收 | 这步改完了，跑下门禁看看能不能合。 |
| 记现场 | 刚才的改动和报错记一下。 |
| 换会话接力 | 继续任务，直接从断点往下做。 |

换模型接力指令（一句话即可）：

> "由于此前模型额度耗尽，会话已重置。请直接读取根目录的 `TASK_PLAN.md` 和 `EXEC_LOG.md`，不要重复已完成工作，直接从下一个未完成步骤继续执行。"

### 仓库结构

```
Banyan/
├── README.md                      # 本文件（中英双语入口）
├── CLAUDE.md                      # 任务执行与断点续传协议（总纲）
├── TASK_PLAN.md                   # 本轮精简状态投影（实时更新）
├── EXEC_LOG.md                    # 执行流水账（append-only）
├── LICENSE                        # MIT
├── plan/                          # dated 计划文件（时间+计划号命名）
│   └── 2026年9月16日-P1实施计划.md
├── docs/                          # 项目文档
│   ├── index.md                   # 文档导航
│   ├── handbook.md                # Skill 套件使用手册（现行）
│   ├── faq.md                     # 常见问题
│   └── archive/                   # 历史归档（manual-1~3，仅追溯）
├── skills/                        # Skill 规范源（唯一源）
│   ├── banyan-plan-draft/         # 起草（含 templates/references）
│   ├── banyan-plan-track/         # 跟踪
│   ├── banyan-gate-verify/        # 门禁
│   ├── banyan-exec-log/           # 日志
│   └── banyan-resume/             # 断点恢复
├── scripts/                       # 安装与校验脚本
│   ├── install-skills.ps1
│   └── install-skills.sh
├── .claude/skills/                # Claude Code 发现路径（链接，重建生成）
├── .opencode/skills/              # OpenCode 发现路径（链接，重建生成）
└── .agents/skills/                # Codex / Gemini CLI 兼容路径（链接，重建生成）
```

### 文档导航

- 入门：本 README → [`docs/index.md`](docs/index.md) → [`docs/handbook.md`](docs/handbook.md)
- 救急：[`docs/faq.md`](docs/faq.md)，Skill 冲突时以 `skills/<name>/SKILL.md` 为准
- 历史：[`docs/archive/`](docs/archive/) 仅供追溯；`manual-3` 的 `agent-task.py` 思想已被 Skill 套件取代，声明作废
- 任务追踪：[`plan/`](plan/) 下 dated 计划文件为执行跟踪表，`TASK_PLAN.md` 为其精简投影

### 协议与工作流

根目录 `CLAUDE.md` 为总纲：复杂任务先规划（4–8 原子步骤）→ 实时双写状态与日志 → 中断后严禁重新规划、从断点继续。`TASK_PLAN.md` / `EXEC_LOG.md` 由 Agent 实时维护。

### 参与与许可

- 改 Skill 后请同步更新 `docs/handbook.md` 对应章节，并跑一遍 `scripts/` 校验。
- 本项目采用 [MIT](LICENSE) 许可。

---

## English Summary

**Banyan** is a task-continuity skill suite for coding agents (Claude Code, OpenCode, Codex, Gemini CLI).

- **Problem**: free-model token quotas interrupt long tasks; switching models/agents/windows loses context and wastes tokens on re-planning.
- **Approach**: externalize state to local Markdown (`TASK_PLAN.md` + dated plan in `plan/` + append-only `EXEC_LOG.md`) instead of relying on session memory.
- **Suite**: 5 skills — `banyan-plan-draft` (plan), `banyan-plan-track` (state machine), `banyan-gate-verify` (4-gate acceptance incl. docs-only branch), `banyan-exec-log` (journal), `banyan-resume` (handover). One-line handover: "Session was reset. Read `TASK_PLAN.md` and `EXEC_LOG.md`, skip completed steps, continue from the first incomplete step."
- **Layout**: `skills/` is the single source of truth; `.claude/skills`, `.opencode/skills`, `.agents/skills` are links rebuilt by `scripts/install-skills.*`. Start at `docs/index.md`, handbook at `docs/handbook.md`, FAQ at `docs/faq.md`.
- **License**: [MIT](LICENSE).
