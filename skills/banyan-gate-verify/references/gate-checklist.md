# 门禁检查单

本文件是 `banyan-gate-verify` 技能的参考文档。代码型任务走门 1–4；**纯文档型任务走"纯文档型项目分支"（本仓库各文档治理轮次适用此分支）**。

## 门 1：格式门

### Rust

```bash
cargo fmt --check
```

通过：`clean`（无输出）。
不通过：列出未格式化文件。

修复：`cargo fmt`。

### JS/TS

```bash
prettier --check "**/*.{js,ts,jsx,tsx}"
```

### Python

```bash
black --check .
```

## 门 2：静态门

### Rust

```bash
cargo clippy --workspace --all-targets
```

**零容忍原则**：
- 新告警不允许出现
- 历史告警逐项消除（在报告中列出）
- `missing-docs` 检查：`RUSTFLAGS='-W missing-docs' cargo check`

### JS/TS

```bash
eslint .
```

### Python

```bash
mypy .
ruff check .
```

## 门 3：测试门

### Rust

```bash
cargo test --workspace
```

- 全绿为通过
- 测试数量变化必须记录（如 `97→99通过`）
- 含 hermetic / e2e / integration 测试

### JS/TS

```bash
npm test
```

### Python

```bash
pytest
```

## 门 4：性能/数量门

### 编译检查（必须）

```bash
cargo bench --workspace --no-run
```

### 实际运行（按需）

```bash
cargo bench --workspace --quick
```

- 若步骤有性能承诺，必须跑 `--quick` 并记录数值
- 若步骤有计数承诺（如 `missing-docs 168→0`），必须运行对应检查

## 纯文档型项目分支（无代码变更时）

### 门 1：格式门

- Markdown 无格式错：标题前后空行、列表缩进一致、表格竖线对齐、无行尾多余空格。
- 有条件可跑 `markdownlint`，无条件则人工按上条逐文件过一遍。

通过：零格式问题。不通过：列出文件与行号，修复后重验。

### 门 2：静态门（死链 + 术语 + frontmatter）

- **死链零容忍**：所有相对链接（`docs/*`、`skills/*`、`plan/*`、`scripts/*`）指向存在的文件；锚点（`#...`）存在。
- **术语一致**：dated 计划文件位置统一为 `plan/`；状态符号（⬜/🟡/✅/❌/⏭️）与 `TASK_PLAN.md` 映射一致。
- **Skill frontmatter**：每个 `SKILL.md` 含 `name` + `description`，文件名全大写。

### 门 3：可读门（代替测试门）

- 每个新增/修改的 `.md` 通读一遍：无截断、无乱码、无占位符残留（如 `[ ]` 待填项）。
- 内链逐条点一遍（可用 `grep` 抽查目标文件存在）。

### 门 4：数量门

- 落盘数量：新增文件数、各核心文件行数、Skill 数（本仓库恒为 5）。
- 有计数承诺（如"6 文件就位"）必须逐项点名确认。

### 文档型门禁报告模板

```
[门1-格式] ✅ 通过 | ❌ 不通过
  详情：零格式问题 / [文件:行号] 需修

[门2-静态] ✅ 通过 | ❌ 不通过
  详情：死链 0 / 术语一致 / frontmatter 全合规

[门3-可读] ✅ 通过 | ❌ 不通过
  详情：[N] 个文件通读无截断

[门4-数量] ✅ 通过 | ❌ 不通过
  详情：新增 [N] 文件 / Skill 5 个

综合判定：✅ 全绿 / ❌ [N] 门红灯
```

## 门禁报告模板

```
[门1-格式] ✅ 通过 | ❌ 不通过
  详情：clean / [N] 个文件需格式化

[门2-静态] ✅ 通过 | ❌ 不通过
  详情：零告警 / [N] 条告警
  历史告警：[逐条列出]

[门3-测试] ✅ 通过 | ❌ 不通过
  详情：[N] 通过 / [M] 失败

[门4-性能] ✅ 通过 | ❌ 不通过
  详情：bench 编译通过 / [数值]

综合判定：✅ 全绿 / ❌ [N] 门红灯
```
