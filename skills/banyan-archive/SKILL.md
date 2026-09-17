---
name: banyan-archive
description: 按年->月->周自动归档 EXEC_LOG.md 与 TASK_PLAN.md：周切片搬运、快照落盘、四级索引维护、按需回溯。当用户说"归档一下"、"这周收尾归档"、"查一下上周日志"、"旧账怎么查"、"EXEC_LOG太长了"时触发。不用于：修改计划状态、执行门禁、追加日常日志、恢复断点（恢复仍走banyan-resume）。
---

# Banyan 归档技能

> 版本：1.0（2026-09-17）
> 关联 Skill：`banyan-exec-log`（追加后自检调归档）、`banyan-plan-draft`（起草前必查归档）、`banyan-resume`（按需第四读查归档）、`banyan-plan-track`（快照引用）、`banyan-gate-verify`（门4归档完整性）。冲突时以本 SKILL.md 为准。

你是归档的唯一执行者。目标：根 `EXEC_LOG.md` 只留活跃周、根 `TASK_PLAN.md` 只留本轮，历史按 `archive/YYYY/YYYY-MM/Wxx_MMDD-MMDD/` 落盘供回溯。

## 触发前置

1. 读取 `references/archive-rules.md`（周定义/切分/校验清单）。
2. 读取 `templates/archive-readme-templates.md`（四级 README 模板）。
3. 读取根 `EXEC_LOG.md` 顶部归档指针行，确认上次归档位置，避免重复搬运。

## 目录结构

```text
archive/
├── README.md                  # 总索引（年入口表 + 最近4周速览）
├── 2026/
│   ├── README.md              # 年索引（12个月入口 + 全年大事记）
│   └── 2026-09/
│       ├── README.md          # 月索引（各周入口表 + 月度汇总）
│       └── W38_0914-0920/     # 周目录：W+ISO周号_起止MMDD-MMDD
│           ├── README.md      # 周索引（范围/轮次/决策/教训/文件清单）
│           ├── EXEC_LOG_0914-0920.md
│           └── TASK_PLAN_P4_2026-09-16.md
```

## 触发条件（任一命中即提示归档，不静默执行）

- 跨周：根 `EXEC_LOG.md` 最后归档时间与当前时间分属不同 ISO 周（周一为周首）。
- 膨胀：根 `EXEC_LOG.md` 超过 300 行或 60KB。
- 轮次边界：`banyan-plan-draft` 起草新轮前检查，上轮已完成且日志未归档则先归档。
- 用户显式要求："归档一下 / 这周收尾归档"。

## 搬运三步（EXEC_LOG 周切片，原子完成）

1. 复制：按 `### [YYYY-MM-DD HH:MM]` 条目切分、按开始时间归属、不断条，将归属周的条目复制到 `archive/<年>/<年月>/<周>/EXEC_LOG_MMDD-MMDD.md`。
2. 校验：搬运条目数 == 原文对应周条目数，且首尾时间戳一致；不一致则中止并报 `❌ 受阻`。
3. 截断：根 `EXEC_LOG.md` 截断，只留归档声明头 + 活跃周条目，并在截断处追加一行归档指针：
   `> [归档指针] YYYY-MM-DD 已将 MM-DD~MM-DD 共 N 条搬运 → archive/.../EXEC_LOG_....md`

## 快照（TASK_PLAN 按轮）

- 每轮完成（`TASK_PLAN.md` 顶部标已完成）后，将全文快照为 `archive/<年>/<年月>/<周>/TASK_PLAN_<轮次>_<YYYY-MM-DD>.md`，头部追加快照头：
  `> 快照时间：…… / 来源轮次：…… / 终态：已完成N/M / 跟踪表：plan/……`
- 根 `TASK_PLAN.md` 由 `banyan-plan-draft` 正常初始化新轮，历史节只留索引指针（如 `P4详见archive/2026/2026-09/W38_0914-0920/`），不再堆全文。

## 索引维护（四级 README）

- 周 README：起止范围、包含轮次（一轮一句话）、门禁结果聚合、教训聚合（摘录每条 `教训：`）、文件清单。
- 月 README：各周入口表 + 月度汇总（完成轮次/门禁/遗留）。
- 年 README：12个月入口 + 全年大事记（3~5行）。
- 总 README：年入口表 + 最近4周速览（每周一行：范围/轮次/一句话结论）。
- 四级 README 必须链路互指，任一断链视为门禁红灯。

## 回溯（供 banyan-resume 按需第四读）

1. 默认只读根双轨 + `archive/README.md` 总索引（不下钻，省 Token）。
2. 命中关键词（如"P2"/"上周"/某日期）再逐级下钻：年 → 月 → 周 README，90% 回溯止于周 README。
3. 只有周 README 信息不足时才读周切片/快照原文。

## 约束

- **归档落盘后只读**：禁止回写 `archive/` 内任何已归档文件；纠错只能在根 `EXEC_LOG.md` 追加 `勘误：[日期+原因+正确信息]` 行。
- **append-only 唯一例外**：本 Skill 的截断是唯一被授权的例外，且必须满足搬运三步校验；其他 Skill 不得截断。
- **跨月周按周一所在月份归属**，周 README 注明实际起止，禁止两处重复归档。
- **双写原子**：切片 + 快照 + 索引更新在同一次归档动作内完成；中断后重跑必须先校验已落盘部分。
- `docs/archive/`（manual 追溯）与 `archive/`（周归档）用途不同，不得混放。
