# Banyan Skill 套件使用手册

> 版本：1.1（2026-09-16，由 `manual/manual-4.md` v1.0 升格，P1 文档治理）
> 适用：Banyan 项目 `skills/` 目录下的 5 个 iot-kernel 式计划管理 Skill
> 目标读者：使用 Claude Code / OpenCode / Codex / Gemini CLI 等编程 Agent 的用户，以及跨会话接手任务的任何 Agent。
> 相关：入口见 `README.md`，常见问题见 `docs/faq.md`，任务跟踪表见 `plan/` 下 dated 计划文件。

---

## 目录

1. [套件概览](#1-套件概览)
2. [安装与发现路径](#2-安装与发现路径)
3. [核心概念：双轨文件体系](#3-核心概念双轨文件体系)
4. [Skill 详解](#4-skill-详解)
   - 4.1 `banyan-plan-draft`（起草）
   - 4.2 `banyan-plan-track`（跟踪）
   - 4.3 `banyan-gate-verify`（门禁）
   - 4.4 `banyan-exec-log`（日志）
   - 4.5 `banyan-resume`（断点恢复）
5. [典型工作流](#5-典型工作流)
   - 场景 A：全新任务从零开始
   - 场景 B：任务中断换 Agent 恢复
   - 场景 C：跨多轮大型项目（P0→P6 式）
6. [配套模板与参考](#6-配套模板与参考)
7. [常见问题（FAQ）](#7-常见问题faq)
8. [术语表](#8-术语表)

---

## 1. 套件概览

### 1.1 解决的问题

免费模型 Token 额度有限，任务常在中途中断；切换模型 / Agent / 窗口后上下文丢失，新会话往往从零重新规划，浪费大量重复 Token。

解决思路：**外部状态持久化 + 上下文解耦**。不依赖 Agent 会话记忆，将任务状态下沉到本地 Markdown 文件。任何 Agent、任何时候都能通过读文件秒级接续任务。

### 1.2 套件构成

| 目录 | 职责 | 触发时机 |
|------|------|----------|
| `skills/banyan-plan-draft` | 起草计划 | 收到需求、要做规划 |
| `skills/banyan-plan-track` | 跟踪状态机 | 步骤开始/完成/受阻 |
| `skills/banyan-gate-verify` | 验证门禁 | 步骤完成后验收 |
| `skills/banyan-exec-log` | 执行日志 | 任何关键操作/决策 |
| `skills/banyan-resume` | 断点恢复 | 新会话接手旧任务 |

五个 Skill 形成闭环：

```
banyan-plan-draft（起草）→ banyan-plan-track（开始步骤）
      ↓                                        ↓
banyan-exec-log（全程记日志）← banyan-gate-verify（门禁验收）
      ↓
banyan-plan-track（标记完成）
      ↓
banyan-resume（新会话从断点接力）
```

### 1.3 设计原则

- **通用兼容**：frontmatter 只使用 Agent Skills 开放标准的交集字段（`name` + `description`），不使用任何单家扩展字段，保证 Claude Code / OpenCode / Codex / Gemini CLI 都能发现和加载。
- **中文描述**：所有 `description` 用中文，明确"何时触发 / 何时不触发"，减少误触发。
- **渐进披露**：SKILL.md 只写指令，长参考内容放 `references/`、模板放 `templates/`，按需读取，省 Token。
- **状态下沉**：进度、日志、决策全部写文件，换模型零成本接力。

---

## 2. 安装与发现路径

### 2.0 免安装直驱（首选，不用记命令）

复制下面一句给任何 Agent（Claude Code / OpenCode / Codex / Gemini CLI），它自己读 `skills/` 并开工，不建链接、不敲命令，Win/mac 通用：

本地仓库版：

> 请读取本仓库 skills/banyan-plan-draft、banyan-plan-track、banyan-gate-verify、banyan-exec-log、banyan-resume 下的 SKILL.md 并严格遵守其中的任务规划与断点续传协议；然后先出方案再动手：【把你的需求粘在这里】。

新项目版（空目录，AI 自己 clone）：

> 把 https://github.com/AiToByte/Banyan 克隆到 ./banyan-skills，读取其中 5 个 Skill 的 SKILL.md 并严格遵守其中的任务规划与断点续传协议；然后先出方案再动手：【把你的需求粘在这里】。

直驱覆盖日常使用；下面 2.1–2.4 的链接安装是"自动触发"增强项（装完 Agent 无需指引自动加载），按需再做。

### 2.1 目录结构

```
Banyan/
├── README.md                        # 中英双语入口
├── CLAUDE.md                        # 任务执行与断点续传协议（总纲）
├── TASK_PLAN.md                     # 总体执行计划 + 实时进度状态机（精简投影）
├── EXEC_LOG.md                      # 详细执行流水账（append-only）
├── plan/                            # dated 计划文件（时间+计划号命名，执行跟踪表）
│   └── 2026年9月16日-P1实施计划.md
├── docs/
│   ├── index.md                     # 文档导航
│   ├── handbook.md                  # 本手册（现行）
│   ├── faq.md                       # 常见问题
│   └── archive/                     # 历史归档（manual-1~3，仅追溯）
├── skills/                          # 规范目录（Skill 源文件常驻于此，唯一源）
│   ├── banyan-plan-draft/
│   │   ├── SKILL.md
│   │   ├── templates/plan-template.md
│   │   └── references/iot-kernel-format.md
│   ├── banyan-plan-track/
│   │   ├── SKILL.md
│   │   └── references/status-legend.md
│   ├── banyan-gate-verify/
│   │   ├── SKILL.md
│   │   └── references/gate-checklist.md
│   ├── banyan-exec-log/
│   │   ├── SKILL.md
│   │   └── templates/log-fragments.md
│   └── banyan-resume/
│       └── SKILL.md
├── scripts/                         # 安装与校验脚本
│   ├── install-skills.ps1           # Windows 重建链接（首选）
│   └── install-skills.sh            # macOS / Linux 重建链接
├── .claude/skills/                  # Claude Code 发现路径（链接，由脚本重建）
├── .opencode/skills/                # OpenCode 发现路径（链接，由脚本重建）
└── .agents/skills/                  # Codex / Gemini CLI / OpenCode 兼容路径（链接，由脚本重建）
```

### 2.2 发现路径说明

各 Agent 从以下位置发现 Skill（只扫描 `*/SKILL.md`）：

| Agent | 默认发现路径 | Banyan 采用的对接 |
|-------|--------------|-------------------|
| Claude Code | `.claude/skills/` | ✅ 目录联接 |
| OpenCode | `.opencode/skills/` 或 `.claude/skills/` 或 `.agents/skills/` | ✅ 三种都有 |
| Codex | `.agents/skills/` | ✅ 目录联接 |
| Gemini CLI | `.agents/skills/` | ✅ 目录联接 |
| GitHub Copilot | `.github/copilot/skills/` | 按需补充 |

### 2.3 创建 / 维护目录联接（首选脚本，一键重建）

> 首选直接运行仓库脚本（自动删旧副本→建链接→校验 15 条链路）。**装完脚本会直接输出 5 句可用话，照着说一句即可开工。**
>
> ```powershell
> # Windows（PowerShell 5.1 可用，/J 免管理员）
> powershell -ExecutionPolicy Bypass -File scripts/install-skills.ps1
> ```
> ```bash
> # macOS / Linux
> bash scripts/install-skills.sh
> ```
>
> 以下为脚本所做事项的手动等价命令（仅脚本不可用时使用）：

Windows（`mklink /J`，免管理员）：

```powershell
New-Item -ItemType Directory -Force .claude\skills, .opencode\skills, .agents\skills
foreach ($s in "banyan-plan-draft","banyan-plan-track","banyan-gate-verify","banyan-exec-log","banyan-resume") {
  cmd /c mklink /J ".claude\skills\$s"   "skills\$s"
  cmd /c mklink /J ".opencode\skills\$s" "skills\$s"
  cmd /c mklink /J ".agents\skills\$s"   "skills\$s"
}
```

macOS / Linux（符号链接）：

```bash
mkdir -p .claude/skills .opencode/skills .agents/skills
for s in banyan-plan-draft banyan-plan-track banyan-gate-verify banyan-exec-log banyan-resume; do
  ln -s "../../skills/$s" ".claude/skills/$s"
  ln -s "../../skills/$s" ".opencode/skills/$s"
  ln -s "../../skills/$s" ".agents/skills/$s"
done
```

> 注意：目录联接是 Windows 特性，跨平台协作者需改用符号链接。核心内容唯一地存在于 `skills/`，联接只是发现代理，删掉重建没有任何损失。

### 2.4 安装校验

```bash
# 预期：三个目录各列出 5 个条目，且每个 SKILL.md 可读
ls .claude/skills/ .opencode/skills/ .agents/skills/

# 校验一个 skill 可被正常解析
Get-Content skills/banyan-resume/SKILL.md   # Windows
head -4 skills/banyan-resume/SKILL.md       # mac/linux，应见 YAML frontmatter
```

---

## 3. 核心概念：双轨文件体系

### 3.1 三份核心文件

| 文件 | 角色 | 更新频次 |
|------|------|----------|
| `TASK_PLAN.md` | 本轮任务的精简状态投影（粗粒度步骤清单） | 状态变更时 |
| `YYYY年M月D日-Px实施计划.md` | 本轮实施的详细跟踪表（子项级） | 状态变更 + 子项更新时 |
| `EXEC_LOG.md` | 执行流水账（append-only） | 任何关键操作 |

### 3.2 双轨状态映射

同一任务在两个文件里同时推进，**状态必须一致**（同名同序）。映射关系：

| `TASK_PLAN.md` | dated 计划文件状态列 | 含义 |
|----------------|----------------------|------|
| `- [ ] 步骤 N` | `⬜ 待开始` | 未开始 |
| `- [-] 步骤 N` | `🟡 进行中` | 正在执行 |
| `- [x] 步骤 N` | `✅ 已完成` | 完成且门禁全绿 |
| `- [!] 步骤 N` | `❌ 受阻` | 受阻待排查 |
| `- [s] 步骤 N` | `⏭️ 跳过` | 本轮跳过 |

### 3.3 状态流转规则

```
⬜ ──开始──▶ 🟡 ──门禁全绿──▶ ✅
 │            │
 │            └──红灯/阻塞──▶ ❌ ──修复──▶ 🟡（重试）
 └──本轮不做──▶ ⏭️
```

- ✅ 不可回退（除非用户明确要求）
- ⏭️ 不可转换
- 禁止跳级：`⬜` 不能直接变 `✅`，必须先 `🟡`

### 3.4 与 iot-kernel 式计划的关系

本套件将 iot-kernel 的 `docs/plan/` 实施计划格式（状态总览表 + 阶段拆解表 + 验证门禁 + 延后声明 + 执行日志）移植到 Banyan。dated 计划文件就是"本轮的执行跟踪表"，`TASK_PLAN.md` 是它的精简投影，`EXEC_LOG.md` 是全程流水账。

---

## 4. Skill 详解

## 4.1 `banyan-plan-draft`（起草）

### 用途

把需求拆解为可执行的原子步骤，产出 dated 计划文件 + 初始化 `TASK_PLAN.md`。**任何代码修改前必须先过此关**。

### 何时触发 / 何时不触发

- 触发：输入需求、想法；说"制定计划""拆解任务""分析需求""规划方案""起草计划""怎么做""帮我规划"
- 不触发：修改代码、运行命令、执行门禁、追加日志、恢复断点

### 前置动作

1. 读 `references/iot-kernel-format.md`（格式规范）
2. 读 `templates/plan-template.md`（可填充模板）
3. 若 `TASK_PLAN.md` 已有未完成任务 → 先与用户确认是追加 / 替换 / 新建，**禁止静默覆盖**

### 拆解规范

- 步骤数严格 **4–8 个**；超过 8 个必须合并或分轮。
- 每步必须带**可验证标准**，例如：
  - `cargo test --workspace 全绿`
  - `grep "pub fn encode_" 除 connack/pingresp 外全 Result`
  - `新增 N 个单测`
  - `missing-docs 168→0`
- 有前置依赖的要注明（如 `P1-1 完成后才可启动 P1-2`）。
- 识别 `Step0`（阻塞修复）：存在编译错误 / 基础缺陷时优先立为 Step0。
- 写明 `延后声明` 节，防止范围蔓延。

### 产出

1. **dated 计划文件**（`plan/` 目录，时间+计划号命名）：`plan/YYYY年M月D日-Px实施计划.md`
2. **`TASK_PLAN.md`**（覆盖或新建）

### 最小模板速查

```markdown
# [P名称] 落地实施计划（YYYY年M月D日）

> 来源：[输入]
> 用户决策（已确认）：**[方向]**
> 前置基线：[之前的完成状态]
> 本文件为执行跟踪表，随执行情况和结果动态更新状态。

图例：⬜ 待开始 / 🟡 进行中 / ✅ 已完成 / ❌ 受阻 / ⏭️ 跳过（本轮不做，留后轮）。

## 状态总览
| 阶段 | 内容 | 状态 | 备注 |
|------|------|------|------|
| P5-0 | 残留硬伤小修 | ⬜ 待开始 | |

## P5-0 拆解
| 子项 | 文件:行号 | 改法 | 状态 |
|------|-----------|------|------|

验收：……

## 验证门禁（每阶段）
`<fmt>` + `<clippy>`（新告警零容忍）+ `<test>`。

## 延后（本轮不做，仅跟踪）
* ……

## 执行日志
* YYYY-MM-DD：建表，开始……
```

### 约束红线

- 规划阶段**禁止改代码**。
- 无验证标准的步骤视为不完整。
- `关键决策与约束` 不可留空；至少写技术边界和禁止事项。
- 勘察结论（如果有）必须列 `勘察结论（冻结）` 节，执行中不可静默修改。

---

## 4.2 `banyan-plan-track`（跟踪）

### 用途

唯一的状态机维护者：在两个文件之间**双写**步骤状态，保证双轨一致。

### 何时触发 / 何时不触发

- 触发：步骤开始 / 完成 / 受阻；说"更新状态""标记完成""进入下一步""状态变了""受阻了"
- 不触发：起草新计划、执行门禁、追加详细日志、恢复断点

### 双写操作（原子完成）

**标记开始（⬜ → 🟡）**
```markdown
dated 计划：状态列 ⬜ 待开始 → 🟡 进行中
TASK_PLAN.md：- [ ] 步骤 N → - [-] 步骤 N
```

**标记完成（🟡 → ✅）**
```markdown
dated 计划：🟡 进行中 → ✅ 已完成；备注列写一行结果：97通过 / clippy零告警 / fmt clean
TASK_PLAN.md：- [-] 步骤 N → - [x] 步骤 N
```

**标记受阻（🟡 → ❌）**
```markdown
dated 计划：🟡 → ❌ 受阻；备注写明原因
TASK_PLAN.md：- [-] → - [!]
同时在关键决策/约束中追加阻塞因素
```

**标记跳过（⬜ → ⏭️）**
```markdown
dated 计划：⬜ → ⏭️ 跳过（本轮不做）
TASK_PLAN.md：- [ ] → - [s]
```

### 备注列的写法（参考 iot-kernel 实证）

- 数量变化：`97→99通过`、`88→91通过`
- 门禁结果：`fmt clean / clippy零告警 / missing-docs零`
- 关键决策：`经论证否决`、`设计偏离说明`
- 教训：`复用同一网关+同源多 MID 单测会命中去重窗口误判`

### 约束红线

- 状态变更**先改文件再写代码**（继承 CLAUDE.md）。
- 禁止 `⬜` 直接跳 `✅`。
- 禁止静默回退 `✅`。
- 有子项拆解表时，子项状态要同步更新。

---

## 4.3 `banyan-gate-verify`（门禁）

### 用途

在小步骤完成时执行**门禁四段**验证，只有全部通过才允许标记 `✅ 已完成`。

### 何时触发 / 何时不触发

- 触发：步骤完成准备验收；说"跑一下门禁""验证一下""测试通过了吗""clippy 过了吗""检查一下""门禁"
- 不触发：起草计划、修改代码、恢复断点

### 门禁四段

**门 1 格式**：`cargo fmt --check`（Rust）/ `prettier --check .`（JS/TS）/ `black --check .`（Python）。不通过则执行格式化命令修复，不计失败。

**门 2 静态**：`cargo clippy --workspace --all-targets` / `eslint .` / `mypy .`。**零容忍**：新告警不允许；历史告警逐项列出并核查是否计划内；Rust 附 `RUSTFLAGS='-W missing-docs' cargo check` 对比基线。

**门 3 测试**：`cargo test --workspace` / `npm test` / `pytest`。全绿；记录数量变化；含 hermetic / e2e。

**门 4 性能/数量**：`cargo bench --workspace --no-run` 编译必须过；有性能承诺则跑 `--quick` 记录数值；有计数承诺（如 `missing-docs 168→0`）则运行对应检查记录。

### 门禁报告模板

```
[门1-格式] ✅ 通过 | ❌ 不通过  详情：clean
[门2-静态] ✅ 通过 | ❌ 不通过  详情：零告警
[门3-测试] ✅ 通过 | ❌ 不通过  详情：99 通过 / 0 失败
[门4-性能] ✅ 通过 | ❌ 不通过  详情：bench 编译通过，search 12x
综合判定：✅ 全绿 / ❌ N 门红灯
```

### 判定规则

- 四门全绿 → 可标记 `✅ 已完成`，活动详情报 `EXEC_LOG.md`。
- 任一红灯 → 标记 `❌ 受阻`，备注写明哪个门 + 原因。
- 修复后必须**重跑红灯门**，不可声称"已修复但未验证"。

---

## 4.4 `banyan-exec-log`（日志）

### 用途

维护 append-only 执行流水账，**双写**到 `EXEC_LOG.md`（详版）和 dated 计划文末 `##执行日志`（摘要版）。

### 何时触发 / 何时不触发

- 触发：步骤开始 / 完成 / 遇到问题 / 重要决策；说"记一下""追加日志""记录现场""写日志"
- 不触发：修改计划结构、改变状态、恢复断点

### 五种日志片段

**① 步骤开始**
```markdown
### [YYYY-MM-DD HH:MM] 步骤 N 开始: [步骤描述]
- 计划操作：……
- 预期验证方式：……
```

**② 步骤完成（归档）**
```markdown
### [YYYY-MM-DD HH:MM] 步骤 N 已完成: [步骤描述]
- **实际操作**：修改了哪些文件、运行了哪些命令、关键参数
- **验证结果**：测试输出摘要 / 编译结果 / 功能确认（含数量）
- **遇到的问题与解决**：……
- **下一步建议**：……
```

dated 文末同步一行：
```markdown
* YYYY-MM-DD：[步骤] 完成：[一句话摘要]（含门禁结果和数量变化）
```

**③ 实时备忘**
```markdown
[HH:MM] 实时调试/备忘: [发现……，决定采用……方案。修改了文件：……]
```

**④ 教训记录**
```markdown
教训：[一句话总结，如"池化必须先 bench 再定档位，固定开销在小尺寸下恒为负收益"]
```

**⑤ 最终总结**
```markdown
### 最终总结
- 整体完成情况：N/M 步骤完成
- 关键产出文件：……
- 遗留问题（如有）：……
- 验证结论：…… / 最终门禁状态
```

### 约束红线

- **append-only**：严禁修改历史行。
- **数量必记**：完成日志必须有测试数量变化 / bench 数值 / lint 状态。
- **教训必写**：非平凡问题必须在"遇到的问题与解决"写明 `教训：`。
- **时间戳必含**：所有条目带 `YYYY-MM-DD HH:MM` 或 `HH:MM`。
- 双写原子：详版 + 摘要版同一次调用完成。

---

## 4.5 `banyan-resume`（断点恢复）

### 用途

新会话接手未完成任务。核心：**严禁重新规划，严禁重复已完成步骤**。

### 何时触发 / 何时不触发

- 触发：会话重置；说"继续任务""断点恢复""接着做""上次做到哪了""恢复""接力""从上次继续"
- 不触发：起草新计划、执行门禁、修改状态机

### 恢复四步

**第一步：三读（按顺序）**
1. `TASK_PLAN.md` → 总体进度
2. `EXEC_LOG.md` → 最新日志切片（最后 20–30 行）
3. 当前 dated 计划文件 → 子项拆解与备注

**第二步：定位断点**
- 找最后一个 `[x]`、第一个 `[-]` 或 `[ ]`
- 在 `EXEC_LOG.md` 找最后一条"步骤 N 已完成"；若存在未归档的"步骤 N 开始"，说明完成前中断

**第三步：汇报断点**（模板）
```markdown
## 断点接力报告

任务：[标题]
总体进度：已完成 [N]/[M] 步

最后完成的步骤：步骤 [X] - [描述]
（附：最后日志关键信息，如"99通过 / clippy零告警"）

当前中断/进行中的步骤：步骤 [Y] - [描述]
下一步应执行的操作：[从 EXEC_LOG.md 最后一条推断]

请确认继续从步骤 [Y] 开始执行。
```

**第四步：直接继续**
- 不重新规划、不覆盖双轨文件
- 不重复 `[x]` 步骤、不重跑已完成门禁
- 遵守 `banyan-exec-log` 规范

### 约束红线

- 恢复流程中不改代码、不覆盖文件。
- 双轨不一致 → 先修一致再继续，修复记入 `EXEC_LOG.md`。
- 找不到 dated 计划 → 提示指定路径或执行 `banyan-plan-draft` 新建。

---

## 5. 典型工作流

> **一句话速查表**（复制即用，不用敲 `/命令`；说下面任一句，Agent 自动触发对应 Skill。本表为唯一源，README 与 FAQ 同文案同步。）

| 想做的事 | 直接说这一句 | 触发的 Skill |
|----------|--------------|--------------|
| 出方案 | 这个需求先出方案再动手，拆成步骤存下来。 | `banyan-plan-draft` |
| 更新进度 | 这步做完了（/卡住了），进度更新下。 | `banyan-plan-track` |
| 验收 | 这步改完了，跑下门禁看看能不能合。 | `banyan-gate-verify` |
| 记现场 | 刚才的改动和报错记一下。 | `banyan-exec-log` |
| 换会话接力 | 继续任务，直接从断点往下做。 | `banyan-resume` |

## 场景 A：全新任务从零开始（完整周期）

**用户**："帮我实现 MQTT 客户端断线重连功能。"

1. Agent 触发 `banyan-plan-draft`
   - 通读 iot-kernel 格式规范 + 模板
   - 拆解 5 个步骤（含 Step0 阻塞修复）
   - 产出 `2026年9月16日-P1断线重连实施计划.md` + 初始化 `TASK_PLAN.md`
   - 向用户确认计划后进入执行

2. 步骤 1 开始：触发 `banyan-plan-track`（双写 `🟡` 与 `[-]`），然后 `banyan-exec-log` 追加"开始"
3. 写代码，过程中遇报错 → `banyan-exec-log` 追加实时备忘（含 `教训：`）
4. 步骤 1 完成 → 触发 `banyan-gate-verify` 四门验证
   - 全绿 → `banyan-plan-track` 标记 `✅` + 备注 `12通过 / clippy零告警` → `banyan-exec-log` 归档
   - 红灯 → 标记 `❌`，修复后重跑红灯门，再归档
5. 依此推进步骤 2–5
6. 全部完成 → `banyan-exec-log` 写最终总结 → `banyan-plan-draft` 不需动，`TASK_PLAN.md` 顶部标"已完成"

## 场景 B：任务中断换 Agent 恢复

**背景**：Claude Code 执行到步骤 3 中途 Token 用尽。

**新会话（任意 Agent）**，用户只说："继续任务"。

1. 触发 `banyan-resume`
2. 三读双轨文件 → 定位断点：步骤 3 `[-]` 未归档
3. 输出"断点接力报告"，用户确认
4. 直接执行 `banyan-gate-verify`（若步骤 3 已完成但未验收）或继续步骤 3 的剩余工作
5. 全程遵守 `banyan-exec-log` 双写规范

> 关键收益：新 Agent 不需要重读历史对话，读 `EXEC_LOG.md` 最后几条即获得全部现场上下文，直接聚焦断点。

## 场景 C：跨多轮大型项目（P0→P6 式）

**背景**：类似 iot-kernel 的多阶段项目，每轮一个 dated 计划文件。

- 每轮开头：`banyan-plan-draft` 建新 dated 文件（如 `P2P3实施计划.md`），状态总览含整轮阶段表
- 每轮结尾：执行日志归档 + 备注"前置基线"供下一轮引用（`P0→P5 全部落地 / cargo test workspace全绿`）
- 下一轮 `banyan-plan-draft` 在头部写 `前置基线：P0+P1+P2+P3 已全部落地`，这就是跨轮状态传递
- 中途换 Agent：`banyan-resume` 找到对应的 dated 文件（用户提供或从 `EXEC_LOG.md` 推断轮次）

---

## 6. 配套模板与参考

| Skill | 文件 | 用途 |
|-------|------|------|
| banyan-plan-draft | `templates/plan-template.md` | 可直接填充的 iot-kernel 式计划模板 |
| banyan-plan-draft | `references/iot-kernel-format.md` | 计划格式规范 + 备注列写法 |
| banyan-plan-track | `references/status-legend.md` | 五态定义 + 双写映射表 |
| banyan-gate-verify | `references/gate-checklist.md` | 各语言门禁命令 + 报告模板 |
| banyan-exec-log | `templates/log-fragments.md` | 五种日志片段模板 |

---

## 7. 常见问题（FAQ）

> 完整版已抽出为 [`faq.md`](faq.md)，此处仅保留速查索引。手册与 FAQ 冲突时以各 `skills/<name>/SKILL.md` 为准。
>
> - Q1 多路径是否都要建 → 至少建你用的 Agent 对应的那路，全建最省心
> - Q2 `mklink /J` 与 `ln -s` 区别 → Windows 用 `/J` 免管理员，详见 Q2
> - Q3 Agent 没自动触发 → 查 `SKILL.md` 文件名/ frontmatter，不行就手动 `/banyan-*` 显式调用
> - Q4 双轨状态不一致 → 先修一致再施工，记入 `EXEC_LOG.md`
> - Q5 完成步骤能否回退 → 默认不可，除非用户明确要求
> - Q6 超过 8 步 → 合并或拆多轮，子项表不计入上限
> - Q7 手册与 SKILL 冲突听谁 → 听 `SKILL.md`
> - Q8 文件会泛滥吗 → dated 一轮一个自然归档，不会膨胀

---

## 8. 术语表

| 术语 | 含义 |
|------|------|
| dated 计划文件 | `YYYY年M月D日-Px实施计划.md`，本轮实施跟踪表 |
| 双轨 / 双写 | 同一状态同时写入 dated 文件与 `TASK_PLAN.md`，保持一致 |
| 双轨打通 | `TASK_PLAN.md` 的状态投影与 iot-kernel 式表格状态互映射 |
| 原子操作 | 两个文件的状态修改必须在同一工具调用内完成 |
| 门禁四段 | 格式 / 静态 / 测试 / 性能数量，四关全过才算完成 |
| 零容忍 | clippy 等静态分析不允许出现新告警 |
| 断点接力 | 新会话通过读文件秒级接续旧任务 |
| 渐进披露 | 只加载 `name+description`，选中后才读 SKILL.md 全文 |
| Frontmatter | SKILL.md 顶部 `---` 之间的 YAML 元数据 |

---

*本手册随套件演进维护。修改任何 SKILL 后请同步更新本文档对应章节。*