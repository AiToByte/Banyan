#!/usr/bin/env bash
# Banyan Skill 发现路径重建脚本（macOS / Linux）。
# 删除三处发现路径下的旧副本/旧链接，以 skills/ 为唯一源重建符号链接，并校验 15 条链路。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="banyan-plan-draft banyan-plan-track banyan-gate-verify banyan-exec-log banyan-resume"
TARGETS=".claude/skills .opencode/skills .agents/skills"

for t in $TARGETS; do
  mkdir -p "$ROOT/$t"
  for s in $SKILLS; do
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
  echo "ALL 15 LINKS OK"
else
  echo "LINK CHECK FAILED"
  exit 1
fi
