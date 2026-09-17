# Banyan 常见问题（FAQ）

> 来源：`handbook.md` v1.0 §7 全量抽出，P1 文档治理后独立维护。本页与各 `skills/<name>/SKILL.md` 冲突时以后者为准。

**Q1：一定要建三种目录联接吗？只用一个行不行？**
至少建你实际使用 Agent 对应的路径。Claude Code 只需 `.claude/skills/`；OpenCode 只需 `.opencode/skills/`（它也读 `.claude/`）。三路都建 == 全覆盖，多花几秒。首选运行 `scripts/install-skills.ps1` / `scripts/install-skills.sh` 一键重建。装完脚本会直接给出 6 句可用话，照着说一句即可开工。

**Q2：Windows 上 `mklink /J` 和 `ln -s` 什么区别？**
`/J` 是目录联接，不需要管理员权限；`ln -s` 是符号链接，可能需要开发者模式。Windows 推荐 `/J`（安装脚本默认即用）。跨平台仓库建议用 `ln -s` 并在 README 写清。

**Q3：Agent 没自动触发 Skill 怎么办？**
先确认发现路径正确、文件名必须是全大写 `SKILL.md`、frontmatter 含 `name` 和 `description`。仍不触发就手动 `/banyan-plan-draft` 或 `/banyan-resume` 显式调用。

**Q4：`TASK_PLAN.md` 和 dated 文件状态不一致了？**
执行 `banyan-plan-track` 修复：先修一致再施工，修复动作记入 `EXEC_LOG.md`。不要各自为政。

**Q5：已经完成的步骤能回退吗？**
除非用户明确要求，`✅` 不回退。发现错误应作为新的后续步骤处理，而不是改写历史。

**Q6：计划步骤超过 8 个怎么办？**
合并相关步骤，或拆成多轮（每个 dated 文件一轮）。拆解表（子项）不计入 4–8 上限，粒度高时用子项表表达。

**Q7：手册 / 模板和 Skill 内置指令冲突听谁的？**
以 `skills/<name>/SKILL.md` 为准。本手册是学习资料，SKILL.md 是运行期强约束。

**Q8：文件会堆太多吗？会泛滥吗？**
dated 文件一轮一个，放在 `plan/` 下按时间+计划号命名，天然归档；`TASK_PLAN.md` 按轮快照到 `archive/`（历史节只留索引指针）；`EXEC_LOG.md` 按周切片搬运、根只留活跃周。跨 ISO 周 / 超 300 行 / 超 60KB / 新轮起草前触发 `banyan-archive`，根文件永远有界，不会膨胀。

**Q9：能不能不敲指令，一句话调用 Skill？**
能。说下面任一句即可（与 `handbook.md` §5 速查表同文案）：出方案→"这个需求先出方案再动手，拆成步骤存下来。"；更新进度→"这步做完了（/卡住了），进度更新下。"；验收→"这步改完了，跑下门禁看看能不能合。"；记现场→"刚才的改动和报错记一下。"；换会话接力→"继续任务，直接从断点往下做。"；归档查旧账→"这周收尾归档一下（/查一下上周日志）。"。v1.2 起各 Skill 已内置这些口语触发语。

**Q10：连安装命令都记不住怎么办？**
用零安装直驱句（见 README 快速开始与 `handbook.md` §2.0）：本地仓库版让 AI 自读 `skills/` 的 6 个 SKILL.md 并开工；新项目版让 AI 自己 clone 再读。不建链接、不敲命令，Win/mac 通用。安装脚本只在你想"自动触发"时再用。

**Q11：归档什么时候触发？旧账怎么查？**
任一命中即归档：跨 ISO 周（周一为周首）/ 根 `EXEC_LOG.md` 超 300 行 / 超 60KB / 新轮起草前上轮未归档，或你直接说"这周收尾归档一下"。执行走 `banyan-archive`：EXEC_LOG 按周切片搬运（三步原子：复制→校验条目数与首尾时间戳→截断并追加归档指针），TASK_PLAN 按轮快照，落盘 `archive/YYYY/YYYY-MM/Wxx_MMDD-MMDD/` 后只读。查旧账先读 `archive/README.md` 总索引定位周，再按需下钻年→月→周（90% 止于周 README）；`archive/`（周归档）与 `docs/archive/`（manual 追溯）不混放。
