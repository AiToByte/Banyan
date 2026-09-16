> **历史归档，仅供追溯**：本文件提出的 `agent-task.py` 单文件 CLI 方案**已作废**，其思想已被 `skills/` 下 5 个 Skill 套件取代。保留仅为追溯设计演进，现行以 `docs/handbook.md` 为准。归档时间 2026-09-16（P1 文档治理）。

---

结合我的详细需求, 先给我一个适用于 claudecode, opencode, codex, pi等多编程Agent的Skill或通用工具


为了在 **Claude Code、OpenCode、Codex、Pi、Aider** 等不同的编程 Agent 之间完全通用，最稳健、不受 Agent 生态壁垒限制的方案是：**打造一个“以单文件 Python 脚本为核心的状态持久化 CLI 工具”，并配合一套标准化的 Agent Skill 指令。**

> **为什么采用 CLI 脚本驱动，而不是纯自然语言提示词？**
> 1. **格式不走样**：纯靠模型写 Markdown，小模型/免费模型经常写错格式、漏勾选或中途偷懒停止更新。脚本通过确定性代码写入，格式 100% 规范。
> 2. **极致节省 Token（断点续传的关键）**：换模型/换终端时，你不需要把以前数万字的聊天记录灌给新模型，脚本的 `resume` 命令会直接提取出 **最精炼的当前状态与断点上下文（仅占用约 200 Token）**，新模型拿起来就能继续写代码。
> 3. **全环境通用**：几乎所有编码 Agent 都具备终端执行能力（Bash/Command Execution），无论它们是否支持 MCP，都能调用。

---

### 第一部分：核心通用工具——`agent-task.py`（单文件开箱即用）

请在你的项目根目录（或全局环境变量中）保存一个 Python 脚本 `agent-task.py`（仅依赖 Python 标准库，无须额外安装第三方包）。

```python
#!/usr/bin/env python3
"""
Universal Agent Task & State Tracker
适用于各类编程 Agent 的跨会话任务断点续传与执行状态追踪工具
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

STATE_DIR = Path(".agent_state")
PLAN_FILE = STATE_DIR / "TASK_PLAN.md"
LOG_FILE = STATE_DIR / "EXEC_LOG.md"
META_FILE = STATE_DIR / "state.json"


def ensure_state_dir():
    STATE_DIR.mkdir(parents=True, exist_ok=True)


def init_task(title: str, steps: list):
    ensure_state_dir()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    state = {
        "title": title,
        "created_at": now,
        "updated_at": now,
        "current_step_id": 1 if steps else 0,
        "steps": [
            {"id": idx + 1, "desc": step.strip(), "status": "pending"}
            for idx, step in enumerate(steps)
            if step.strip()
        ],
    }

    with open(META_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

    # 生成 TASK_PLAN.md
    render_plan_md(state)

    # 初始化 EXEC_LOG.md
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write(f"# 任务执行流水日志: {title}\n")
        f.write(f"> 规划初始化时间: {now}\n\n---\n")

    print(f"[SUCCESS] 任务规划已持久化！总共 {len(state['steps'])} 个原子步骤。")
    print(f"-> 计划文件: {PLAN_FILE}")
    print(f"-> 日志文件: {LOG_FILE}")


def render_plan_md(state: dict):
    lines = [
        f"# 任务总体执行规划: {state['title']}",
        f"> 最近更新: {state['updated_at']}",
        "",
        "## 执行进度清单",
    ]
    for s in state["steps"]:
        mark = " "
        status_text = ""
        if s["status"] == "done":
            mark = "x"
            status_text = " *(已完成)*"
        elif s["status"] == "in_progress":
            mark = "-"
            status_text = " **(正在执行...)**"
        elif s["status"] == "failed":
            mark = "!"
            status_text = " **(失败/待排查)**"

        lines.append(f"- [{mark}] **步骤 {s['id']}**: {s['desc']}{status_text}")

    lines.append("\n---\n*本文件由 agent-task 自动实时维护，严禁手动随意擦除。*")
    with open(PLAN_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def start_step(step_id: int):
    if not META_FILE.exists():
        sys.exit("[ERROR] 尚未初始化任务，请先执行 init 命令。")

    with open(META_FILE, "r", encoding="utf-8") as f:
        state = json.load(f)

    target = next((s for s in state["steps"] if s["id"] == step_id), None)
    if not target:
        sys.exit(f"[ERROR] 找不到步骤编号: {step_id}")

    target["status"] = "in_progress"
    state["current_step_id"] = step_id
    state["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open(META_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

    render_plan_md(state)
    print(f"[STATUS] 步骤 {step_id} 状态已更新为：执行中 [in_progress]")


def complete_step(step_id: int, log_detail: str):
    if not META_FILE.exists():
        sys.exit("[ERROR] 尚未初始化任务，请先执行 init 命令。")

    with open(META_FILE, "r", encoding="utf-8") as f:
        state = json.load(f)

    target = next((s for s in state["steps"] if s["id"] == step_id), None)
    if not target:
        sys.exit(f"[ERROR] 找不到步骤编号: {step_id}")

    target["status"] = "done"
    state["updated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 寻找下一个未完成步骤
    next_step = next(
        (s["id"] for s in state["steps"] if s["status"] == "pending"), None
    )
    state["current_step_id"] = next_step if next_step else 0

    with open(META_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

    render_plan_md(state)

    # 写入 EXEC_LOG.md
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = (
        f"\n### 步骤 {step_id} 已完成: {target['desc']}\n"
        f"- **完成时间**: {now}\n"
        f"- **详细执行记录与验证**:\n{log_detail}\n"
        f"\n---\n"
    )
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(log_entry)

    print(f"[SUCCESS] 步骤 {step_id} 已归档，详细日志已追加至 {LOG_FILE}。")
    if next_step:
        print(f"-> 下一个待执行步骤: 步骤 {next_step}")
    else:
        print("-> 所有步骤已全部完成！")


def append_log(note: str):
    """在当前步骤执行过程中，实时追加现场调试日志"""
    if not LOG_FILE.exists():
        sys.exit("[ERROR] 日志文件不存在。")
    now = datetime.now().strftime("%H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{now}] 实时调试/备忘: {note}\n")
    print(f"[LOGGED] 实时现场信息已保存。")


def resume_context():
    """
    极简上下文提取器：换模型、重开终端时调用，
    仅输出接力所需的最高密度上下文，避免消耗 Token。
    """
    if not META_FILE.exists():
        print("[NOTICE] 当前目录没有找到进行中的任务状态。")
        return

    with open(META_FILE, "r", encoding="utf-8") as f:
        state = json.load(f)

    done_steps = [s for s in state["steps"] if s["status"] == "done"]
    current_step = next(
        (s for s in state["steps"] if s["status"] == "in_progress"), None
    )
    next_pending = next(
        (s for s in state["steps"] if s["status"] == "pending"), None
    )

    # 提取最后 20 行日志以掌握最新现场
    recent_logs = ""
    if LOG_FILE.exists():
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()
            recent_logs = "".join(lines[-20:])

    print("=" * 60)
    print(f"【任务断点接力上下文】: {state['title']}")
    print(f"总体进度: 已完成 {len(done_steps)}/{len(state['steps'])} 步")
    if done_steps:
        print(f"最后完成的步骤: 步骤 {done_steps[-1]['id']} - {done_steps[-1]['desc']}")

    if current_step:
        print(f"\n当前中断/进行中的步骤: 步骤 {current_step['id']} - {current_step['desc']}")
    elif next_pending:
        print(f"\n下一个应执行步骤: 步骤 {next_pending['id']} - {next_pending['desc']}")
    else:
        print("\n所有任务已全部完成！")

    print("\n【现场最新日志切片】:")
    print(recent_logs.strip() or "暂无详细执行日志")
    print("=" * 60)
    print("指令建议：请新 Agent 仔细检查上述状态，直接从当前步骤继续向下执行，切勿重复前面已完成的任务！")


def main():
    parser = argparse.ArgumentParser(description="跨 Agent 任务规划与断点续传工具")
    subparsers = parser.add_subparsers(dest="command")

    # init
    p_init = subparsers.add_parser("init", help="初始化任务规划")
    p_init.add_argument("title", help="总任务标题")
    p_init.add_argument(
        "--steps",
        required=True,
        help="以分号(;)或换行分隔的任务步骤清单，如 '分析依赖;重构代码;单元测试'",
    )

    # start
    p_start = subparsers.add_parser("start", help="标记某个步骤开始执行")
    p_start.add_argument("step_id", type=int, help="步骤编号")

    # complete
    p_done = subparsers.add_parser("complete", help="完成某个步骤并记录详细日志")
    p_done.add_argument("step_id", type=int, help="步骤编号")
    p_done.add_argument(
        "--log", required=True, help="详细日志：完成了什么、改了哪些文件、验证输出"
    )

    # log
    p_log = subparsers.add_parser("log", help="追加过程中的现场或错误备忘")
    p_log.add_argument("note", help="备忘内容")

    # resume
    subparsers.add_parser("resume", help="打印精简接力上下文")

    args = parser.parse_args()

    if args.command == "init":
        # 兼容换行和分号切分
        raw_steps = args.steps.replace("\n", ";").split(";")
        init_task(args.title, raw_steps)
    elif args.command == "start":
        start_step(args.step_id)
    elif args.command == "complete":
        complete_step(args.step_id, args.log)
    elif args.command == "log":
        append_log(args.note)
    elif args.command == "resume":
        resume_context()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
```

---

### 第二部分：跨 Agent 通用 Skill 规则配置

你可以把以下规则内容直接分发给不同的编程 Agent。无论你换到哪个 Agent，它都会自动学会调用该脚本。

#### 1. 通用 Skill 提示词（直接保存为工作区根目录的规则文件）
* **对于 Claude Code**：直接保存为工作区根目录的 `CLAUDE.md`
* **对于 OpenCode / Codex / Pi**：可作为初始系统预设（System Instructions），或存为 `.cursorrules` / `instructions.md`

```markdown
# 任务规划、实时日志与状态连续性协议 (Task Continuity Protocol)

无论你当前是哪个模型或 Agent，你必须通过本地命令行工具 `python3 agent-task.py` 来维护跨会话的任务状态。这能防止因为 Token 耗尽或终端重置而导致重复工作。

## 1. 任务开始前的规划阶段
在处理用户的复杂编程需求前，**严禁直接修改代码**。必须先拆解任务并执行：
`python3 agent-task.py init "任务标题" --steps "子步骤1; 子步骤2; 子步骤3; 子步骤4"`
- 这将自动在本地生成 `.agent_state/TASK_PLAN.md` 和 `.agent_state/EXEC_LOG.md`。

## 2. 任务执行与实时记录（强制动作）
- **开始步骤**：每当你着手处理步骤 N，先执行：
  `python3 agent-task.py start <步骤编号>`
- **记录现场**：如果在调试中遇到报错或重要决策，执行：
  `python3 agent-task.py log "发现报错 XXX，决定采用 YYY 方案绕过"`
- **步骤完成**：代码编写并通过测试后，必须立即归档：
  `python3 agent-task.py complete <步骤编号> --log "修改了 a.py 和 b.py；通过了 pytest 测试；新增了针对 edge case 的校验"`

## 3. 会话重置与模型接力（断点恢复）
当你被要求“继续任务”或刚被启动时：
- 首先执行：`python3 agent-task.py resume`
- 仔细阅读输出的【当前进行中步骤】与【现场最新日志切片】。
- **不要重复执行已标记为 done 的步骤**，直接无缝接着最新的未完成步骤继续推进！
```

---

### 第三部分：跨 Agent 实际协作工作流演示

看看这个体系在你的实际日常中是如何运作的：

#### 场景 1：在 Claude Code 中开始任务
* **用户对 Claude Code 说**：“帮我把项目里的认证模块从 JWT 换成 Session，并补齐单元测试。”
* **Claude Code 自动执行**：
  ```bash
  python3 agent-task.py init "认证机制重构(JWT转Session)" --steps "审计现有JWT逻辑;设计Session数据模型与存储;重写中间件;修复关联测试用例"
  python3 agent-task.py start 1
  ```
* Claude Code 开始阅读代码、排查逻辑，完成步骤 1 后：
  ```bash
  python3 agent-task.py complete 1 --log "梳理了 auth.py，确认了 4 个依赖 JWT 的路由装饰器，已记录在笔记中"
  python3 agent-task.py start 2
  ```
* 此时 Claude 执行到步骤 2 中途，**免费 Token 配额用尽（Rate limit 429 报错），会话强行中断。**

---

#### 场景 2：切换到 OpenCode / Codex / Pi 或 DeepSeek 接力
你打开一个新终端，启动另一个 Agent（例如免费的 DeepSeek 模型或 Pi CLI）：

* **你只需要向新 Agent 发送一句话**：
  > “之前任务被中断了，请读取断点上下文并继续执行未完成的工作。”

* **新 Agent 按照规则自动运行命令**：
  ```bash
  python3 agent-task.py resume
  ```
* **控制台返回高密度上下文（仅消耗 ~180 Token）**：
  ```text
  ============================================================
  【任务断点接力上下文】: 认证机制重构(JWT转Session)
  总体进度: 已完成 1/4 步
  最后完成的步骤: 步骤 1 - 审计现有JWT逻辑

  当前中断/进行中的步骤: 步骤 2 - 设计Session数据模型与存储

  【现场最新日志切片】:
  ### 步骤 1 已完成: 审计现有JWT逻辑
  - 完成时间: 2026-09-15 20:45:00
  - 详细执行记录与验证:
  梳理了 auth.py，确认了 4 个依赖 JWT 的路由装饰器，已记录在笔记中
  ============================================================
  ```
* **效果**：新 Agent **瞬间得知前一个 Agent 做完了什么、留下了什么、自己现在该干什么**。它不会重新去审计 `auth.py`（避免重复浪费 Token），而是直接聚焦在步骤 2 的代码编写上。

---

### 方案亮点与收益总结

1. **绝对解耦**：不依赖任何厂商专有的私有上下文格式，文件统一沉淀在本地标准的 `.md` 和 `.json` 里，任何编辑器（如 VS Code）都能直观查看。
2. **极速省流**：切换模型接力时，不需要把动辄几万 Token 的历史对话重新塞回新会话，通过 `agent-task resume` 精准传递断点信息。
3. **支持全套工具链**：无论是 Claude Code、OpenCode、Aider 还是 Codex，只要 Agent 能调命令行，就能完美无缝使用。你可以随时将 `agent-task.py` 放到系统的 `/usr/local/bin` 中，作为全局命令随时调用。