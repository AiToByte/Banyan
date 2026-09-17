#!/usr/bin/env bash
# Banyan Skill 发现路径重建脚本（macOS / Linux）。
# 以 skills/ 为唯一源重建符号链接，并校验 18 条链路。
# 兼容 macOS 自带 bash 3.2：只用 for 循环/test/readlink，不用关联数组等新特性。
# 用法（一行命令）：bash scripts/install-skills.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="banyan-plan-draft banyan-plan-track banyan-gate-verify banyan-exec-log banyan-resume banyan-archive"
TARGETS=".claude/skills .opencode/skills .agents/skills"

for s in $SKILLS; do
  if [ ! -r "$ROOT/skills/$s/SKILL.md" ]; then
    echo "ERROR: missing source skills/$s/SKILL.md" >&2
    exit 1
  fi
done

for t in $TARGETS; do
  mkdir -p "$ROOT/$t"
  for s in $SKILLS; do
    if [ -L "$ROOT/$t/$s" ] && [ "$(readlink "$ROOT/$t/$s")" = "../../skills/$s" ]; then
      echo "SKIP $t/$s (already linked)"
      continue
    fi
    rm -rf "$ROOT/$t/$s"
    ln -s "../../skills/$s" "$ROOT/$t/$s"
  done
done

fail=0
for t in $TARGETS; do
  for s in $SKILLS; do
    if [ -r "$ROOT/$t/$s/SKILL.md" ]; then
      echo "OK   $t/$s"
    else
      echo "FAIL $t/$s"
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "ALL 18 LINKS OK"
  echo ""
  echo "安装完成，直接把下面任一句发给 Agent 即可开始（不用敲 /命令）："
  echo "  出方案：这个需求先出方案再动手，拆成步骤存下来。"
  echo "  更新进度：这步做完了（/卡住了），进度更新下。"
  echo "  验收：这步改完了，跑下门禁看看能不能合。"
  echo "  记现场：刚才的改动和报错记一下。"
  echo "  换会话接力：继续任务，直接从断点往下做。"
  echo "  归档查旧账：这周收尾归档一下（/查一下上周日志）。"
else
  echo "LINK CHECK FAILED"
  exit 1
fi
