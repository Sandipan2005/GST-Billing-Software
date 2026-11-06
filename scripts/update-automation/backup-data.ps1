# Back up local business data before merging upstream changes.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/update-automation/backup-data.ps1

param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$BackupRoot = ""
)

$ErrorActionPreference = "Stop"
if (-not $BackupRoot) { $BackupRoot = Join-Path $RepoRoot "backups" }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$dest = Join-Path $BackupRoot "data-backup-$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$targets = @("data", "Saved Invoices", "Trash")
foreach ($t in $targets) {
  $src = Join-Path $RepoRoot $t
  if (Test-Path $src) {
    Copy-Item -Path $src -Destination (Join-Path $dest $t) -Recurse -Force
    Write-Host "Backed up: $t -> $dest\$t"
  } else {
    Write-Host "Skipped (missing): $t"
  }
}

Write-Host "Backup complete: $dest" -ForegroundColor Green
return $dest