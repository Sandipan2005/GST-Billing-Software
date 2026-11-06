# Daily upstream update checker (local). Safe: fetches and reports only; does not merge.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/update-automation/daily-check.ps1

param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$UpstreamRemote = "upstream",
  [string]$UpstreamBranch = "main",
  [switch]$Toast
)

$ErrorActionPreference = "Stop"
Set-Location $RepoRoot

if (-not (Test-Path ".git")) { throw "Not a git repository: $RepoRoot" }

$remotes = git remote
if ($remotes -notcontains $UpstreamRemote) {
  Write-Host "Missing remote '$UpstreamRemote'. Run: git remote add upstream https://github.com/IamRamgarhia/Free-GST-Billing-Software.git" -ForegroundColor Yellow
  exit 1
}

git fetch $UpstreamRemote $UpstreamBranch --quiet
$head = git rev-parse --short HEAD
$baseRef = "$UpstreamRemote/$UpstreamBranch"
$count = [int](git rev-list --count "HEAD..$baseRef")
$logDir = Join-Path $RepoRoot "scripts\update-automation\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "daily-check.log"
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($count -gt 0) {
  $commits = git log --oneline --no-decorate -n 20 "HEAD..$baseRef"
  $msg = "[$stamp] $count upstream commit(s) available ($baseRef). Current HEAD: $head`n$commits`n"
  Add-Content -Path $logFile -Value $msg
  Write-Host "Upstream updates available ($count commit(s)):" -ForegroundColor Green
  Write-Host $commits
  Write-Host "`nReview: git log HEAD..$baseRef --oneline" -ForegroundColor Cyan
  Write-Host "Safe merge: powershell -ExecutionPolicy Bypass -File scripts/update-automation/safe-merge-upstream.ps1" -ForegroundColor Cyan

  if ($Toast) {
    try {
      # Best-effort Windows toast via BurntToast if installed; otherwise no-op.
      if (Get-Module -ListAvailable -Name BurntToast) {
        Import-Module BurntToast -ErrorAction Stop
        New-BurntToastNotification -Text "GST Billing: upstream updates", "$count new commit(s) available. Review before merging."
      }
    } catch { }
  }
  exit 2
} else {
  Add-Content -Path $logFile -Value "[$stamp] Up to date with $baseRef. HEAD: $head`n"
  Write-Host "Already up to date with $baseRef." -ForegroundColor Gray
  exit 0
}