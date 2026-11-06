# Safe upstream merge: backup data, fetch, show diff, merge (no auto-push), optional tests.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/update-automation/safe-merge-upstream.ps1

param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$UpstreamRemote = "upstream",
  [string]$UpstreamBranch = "main",
  [switch]$RunTests,
  [switch]$NoBackup
)

$ErrorActionPreference = "Stop"
Set-Location $RepoRoot

if (-not (Test-Path ".git")) { throw "Not a git repository: $RepoRoot" }
$status = git status --porcelain
if ($status) {
  throw "Working tree is not clean. Commit/stash your changes before merging upstream.`n$status"
}

if (-not $NoBackup) {
  & (Join-Path $PSScriptRoot "backup-data.ps1") -RepoRoot $RepoRoot | Out-Null
}

git fetch $UpstreamRemote $UpstreamBranch
$baseRef = "$UpstreamRemote/$UpstreamBranch"
$count = [int](git rev-list --count "HEAD..$baseRef")
if ($count -le 0) {
  Write-Host "Already up to date with $baseRef." -ForegroundColor Gray
  exit 0
}

Write-Host "Incoming commits ($count):" -ForegroundColor Cyan
git log --oneline --no-decorate -n 50 "HEAD..$baseRef"
Write-Host "`nFiles likely affected:" -ForegroundColor Cyan
git diff --name-status "HEAD..$baseRef" | Select-Object -First 60

Write-Host "`nMerging $baseRef into current branch..." -ForegroundColor Yellow
git merge --no-edit $baseRef

if (Test-Path "package-lock.json") {
  Write-Host "package-lock.json present. If deps changed, run: npm install" -ForegroundColor Cyan
}

if ($RunTests) {
  if (Test-Path "package.json") {
    Write-Host "Running tests..." -ForegroundColor Cyan
    npm run test
  }
}

Write-Host "`nMerge complete (not pushed). Review, test 'npm run dev:win', then push:" -ForegroundColor Green
Write-Host "  git push origin $(git branch --show-current)"