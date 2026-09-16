#Requires -Version 5.1
<#
.SYNOPSIS
  Banyan Skill 发现路径重建脚本（Windows）。
  删除三处发现路径下的旧副本/旧链接，以 skills/ 为唯一源重建目录联接（mklink /J，免管理员），并校验 15 条链路。
#>
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Skills = @("banyan-plan-draft", "banyan-plan-track", "banyan-gate-verify", "banyan-exec-log", "banyan-resume")
$Targets = @(".claude/skills", ".opencode/skills", ".agents/skills")

foreach ($t in $Targets) {
  $dir = Join-Path $RepoRoot $t
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  foreach ($s in $Skills) {
    $link = Join-Path $dir $s
    $src = Join-Path $RepoRoot ("skills/" + $s)
    if (Test-Path -LiteralPath $link) {
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
  Write-Output "ALL 15 LINKS OK"
} else {
  Write-Output "LINK CHECK FAILED"
  exit 1
}
