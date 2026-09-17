# Banyan 文档导航

> 入口：[`README.md`](../README.md) → 本页 → [`handbook.md`](handbook.md) → [`faq.md`](faq.md)

## 现行文档

| 文档 | 说明 |
|------|------|
| [`handbook.md`](handbook.md) | Skill 套件使用手册 v1.2（现行唯一手册）：安装、双轨概念、6 Skill 详解（含 `banyan-archive` 周归档）、3 种典型工作流 |
| [`faq.md`](faq.md) | 常见问题 11 问（安装/触发/状态修复/回退/拆分/冲突/膨胀/一句话调用/直驱/归档回溯） |
| [`../plan/`](../plan/) | dated 计划文件（时间+计划号命名），每轮执行跟踪表，随执行动态更新 |
| [`../archive/`](../archive/) | 周归档（年→月→周：切片 + 快照 + 四级索引，只读；回溯先读总索引） |

## 历史归档（仅追溯，不作为执行依据）

| 文档 | 说明 |
|------|------|
| [`archive/manual-1.md`](archive/manual-1.md) | 早期需求问答：技术方案选型（提示词/Memory Bank/MCP/自研网关） |
| [`archive/manual-2.md`](archive/manual-2.md) | 早期开源选型问答：Roo/LiteLLM/OpenHands/Aider 等 |
| [`archive/manual-3.md`](archive/manual-3.md) | 早期 `agent-task.py` CLI 方案草案（**已作废**，思想由 Skill 套件取代） |

## Skill 源文件

规范源常驻 `../skills/`（唯一源），各 Agent 发现路径（`.claude/skills`、`.opencode/skills`、`.agents/skills`）为链接，由 `../scripts/install-skills.ps1`（Windows）或 `../scripts/install-skills.sh`（mac/Linux）重建。冲突时以 `skills/<name>/SKILL.md` 为准。
