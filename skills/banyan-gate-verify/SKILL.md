---
name: banyan-gate-verify
description: 执行分阶段验证门禁：格式检查、静态分析、测试全绿、性能/数量落盘。当步骤完成准备标记为已通过时触发。当用户说"跑一下门禁"、"验证一下"、"测试通过了吗"、"clippy 过了吗"、"检查一下"、"门禁"、"门禁全绿"、"帮我检查下"、"跑下测试看看"、"能不能合了"时触发。不用于：起草计划、修改代码、恢复断点。
---

# Banyan 门禁验证技能

> 版本：1.2（2026-09-16）
> 关联 Skill：`banyan-plan-track`（全绿标 ✅ / 红灯标 ❌）、`banyan-exec-log`（门禁报告归档）。纯文档型任务走文档型分支（见 `references/gate-checklist.md`），四门同样必须全绿。冲突时以本 SKILL.md 为准。

你必须在每个步骤完成时执行门禁验证，只有全部通过才允许标记步骤为 `✅ 已完成`。任一红灯即标记 `❌ 受阻`。

## 触发前置

1. 读取 `references/gate-checklist.md` 获取完整检查单。
2. 确认当前步骤的可验证标准（来自 dated 计划文件或 `TASK_PLAN.md`）。

## 门禁四段

### 门 1：格式门（fmt）

```
# 根据项目语言执行
cargo fmt --check          # Rust
prettier --check .         # JS/TS
black --check .            # Python
```

- 结果：`clean`（通过）或列出未格式化文件（不通过）。
- 修复：执行格式化命令（`cargo fmt` / `prettier --write`），不计为门禁失败。

### 门 2：静态门（lint + typecheck）

```
cargo clippy --workspace --all-targets    # Rust
eslint .                                  # JS/TS
mypy .                                    # Python
```

- **零容忍原则**：新告警不允许出现（即使与本次修改无关的 lint 规则也必须检查）。
- **历史告警逐项消除**：若存在 pre-existing 告警，在门禁报告中逐条列出，确认是否为本轮计划内。
- **missing-docs 检查**（Rust）：`RUSTFLAGS='-W missing-docs' cargo check`，若有基线数字需对比（如 `168→0`）。

### 门 3：测试门（test）

```
cargo test --workspace          # Rust
npm test                        # JS/TS
pytest                          # Python
```

- 全绿为通过；任一失败即不通过。
- 测试数量变化必须记录（如 `97→99通过`）。
- 含 hermetic / e2e / integration 等端到端测试（如项目有）。

### 门 4：性能/数量门（bench + 度量）

```
cargo bench --workspace --no-run   # 编译检查
cargo bench --workspace --quick    # 实际运行（可选）
```

- bench 编译必须通过。
- 若步骤有性能承诺（如 `-19ms`、`12x`），必须跑 `--quick` 并记录数值。
- 若步骤有计数承诺（如 `missing-docs 168→0`），必须运行对应检查并记录。

### 文档型项目分支（无代码变更时）

纯文档型任务（如本仓库的文档治理轮次）不跑 cargo/npmpytest，直接走 `references/gate-checklist.md` 的"纯文档型项目分支"四门（格式/死链与术语/可读抽查/数量落盘）。判定规则与上同：全绿标 ✅，红灯标 ❌ 并重跑红灯门。

## 门禁报告格式

每个门完成后输出：

```
[门N-名称] ✅ 通过 | ❌ 不通过
  详情：……
  修复建议：……（仅不通过时）
```

## 判定规则

- **四门全绿**：步骤可标记为 `✅ 已完成`，同步更新 `备注` 列。
- **任一红灯**：步骤标记为 `❌ 受阻`，在 `备注` 列写明哪个门红灯 + 原因摘要。
- **修复后重跑**：修复代码后必须重跑红灯门（至少），不可声称"已修复但未验证"。

## 约束

- 门禁必须在标记完成之前执行，不可事后补跑。
- 门禁报告必须追加到 `EXEC_LOG.md`（使用 `banyan-exec-log` 技能的片段模板）。
- 禁止跳过门 4（即使项目无 bench 也需至少做 `--no-run` 编译检查）。
- 门禁发现的问题必须记录到 `EXEC_LOG.md` 的 `遇到的问题与解决` 段。
