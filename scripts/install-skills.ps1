#Requires -Version 5.1
<#
.SYNOPSIS
  Banyan Skill 发现路径重建脚本（Windows）。
   以 skills/ 为唯一源重建目录联接（mklink /J，免管理员），已正确的链接跳过，并校验 18 条链路。
  用法（一行命令）：powershell -ExecutionPolicy Bypass -File scripts/install-skills.ps1
#>
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Skills = @("banyan-plan-draft", "banyan-plan-track", "banyan-gate-verify", "banyan-exec-log", "banyan-resume", "banyan-archive")
$Targets = @(".claude/skills", ".opencode/skills", ".agents/skills")

foreach ($s in $Skills) {
  $srcCheck = Join-Path $RepoRoot ("skills/" + $s + "/SKILL.md")
  if (-not (Test-Path -LiteralPath $srcCheck)) {
    throw ("ERROR: missing source skills/" + $s + "/SKILL.md")
  }
}

foreach ($t in $Targets) {
  $dir = Join-Path $RepoRoot $t
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  foreach ($s in $Skills) {
    $link = Join-Path $dir $s
    $src = Join-Path $RepoRoot ("skills/" + $s)
    if (Test-Path -LiteralPath $link) {
      $item = Get-Item -LiteralPath $link
      if (($item.LinkType -eq "Junction") -and ($item.Target -eq $src)) {
        Write-Output ("SKIP " + $t + "/" + $s + " (already linked)")
        continue
      }
      Remove-Item -LiteralPath $link -Recurse -Force
    }
    cmd /c mklink /J "$link" "$src" | Out-Null
  }
}

$fail = 0
foreach ($t in $Targets) {
  foreach ($s in $Skills) {
    $f = Join-Path $RepoRoot ($t + "/" + $s + "/SKILL.md")
    if (Test-Path -LiteralPath $f) {
      Write-Output ("OK   " + $t + "/" + $s)
    } else {
      Write-Output ("FAIL " + $t + "/" + $s)
      $fail = 1
    }
  }
}

if ($fail -eq 0) {
  Write-Output "ALL 18 LINKS OK"
  Write-Output ""
  Write-Output "安装完成，直接把下面任一句发给 Agent 即可开始（不用敲 /命令）："
  Write-Output "  出方案：这个需求先出方案再动手，拆成步骤存下来。"
  Write-Output "  更新进度：这步做完了（/卡住了），进度更新下。"
  Write-Output "  验收：这步改完了，跑下门禁看看能不能合。"
  Write-Output "  记现场：刚才的改动和报错记一下。"
  Write-Output "  换会话接力：继续任务，直接从断点往下做。"
  Write-Output "  归档查旧账：这周收尾归档一下（/查一下上周日志）。"
} else {
  Write-Output "LINK CHECK FAILED"
  exit 1
}
