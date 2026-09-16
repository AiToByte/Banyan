# 门禁检查单

本文件是 `banyan-gate-verify` 技能的参考文档。

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
