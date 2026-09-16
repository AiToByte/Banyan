# 任务总体执行规划: P1 文档与 Skill 治理（README + docs归拢 + skills完善）

> 创建/更新时间: 2026-09-16 21:06
> 当前状态: 已完成
> 跟踪表: `plan/2026年9月16日-P1实施计划.md`（动态更新，状态以该文件为准）

## 执行进度清单
- [x] **步骤 1**: 新建 README.md 中英双语（可验证标准：落盘，含五Skill表/快速开始/结构树，内链无断链）
- [x] **步骤 2**: 新建 docs/ 并归拢 manual-1~3 到 archive，manual-4 升格 handbook（可验证标准：manual/ 删除，docs 下 6 文件存在，无断链）
- [x] **步骤 3**: 完善 5 个 Skill 内容（可验证标准：SKILL 1.1版本行，gate-checklist 含文档型分支，引用无断链）
- [x] **步骤 4**: 发现路径改脚本重建（可验证标准：三路径各5链接可用，git 仅预期变更）
- [x] **步骤 5**: 根文档联动更新（可验证标准：CLAUDE.md 含入口引用，LICENSE 存在，历史行未擦除）
- [x] **步骤 6**: 全量验证门禁并归档（可验证标准：文档型四门全绿报告落 EXEC_LOG.md）

## 关键决策与约束
- README 中英双语，handbook 保持中文，防双源漂移只摘要引用
- manual-1~3 归档保留不删除历史，manual-3 声明作废
- skills/ 为唯一源，不动 description 触发语；副本在 P1-4 统一重建
- 计划文件落在 plan/ 下按时间+计划号命名，执行中动态更新
- 禁止事项：不新增 Skill、不碰远端 GitHub 设置、不改 CLAUDE.md 三阶段协议正文

## 最终总结（P1 已完成）
- 6/6 步骤完成：README 中英双语、docs/6 文件归拢、skills 升 1.1、脚本重建 15 链接、CLAUDE 入口节、MIT LICENSE、文档型门禁全绿。
- 关键产出：`README.md`、`docs/handbook.md` v1.1、`docs/faq.md`、`scripts/install-skills.ps1/.sh`、`plan/2026年9月16日-P1实施计划.md`。
- 遗留：install-skills.sh 未在 Linux 实机运行；更改未提交，待用户 review 后 commit。

---
*本文件由 Agent 实时维护，严禁手动随意擦除或修改状态。*