# Registers a Windows Scheduled Task to run the daily upstream check.
# Run PowerShell as the current user (no admin needed for a user task).
# Usage: powershell -ExecutionPolicy Bypass -File scripts/update-automation/register-daily-task.ps1

param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$TaskName = "GSTBilling-UpstreamDailyCheck",
  [string]$At = "09:00"
)

$ErrorActionPreference = "Stop"
$script = Join-Path $RepoRoot "scripts\update-automation\daily-check.ps1"
if (-not (Test-Path $script)) { throw "Missing script: $script" }

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" -RepoRoot `"$RepoRoot`""
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Host "Registered scheduled task '$TaskName' daily at $At (current user: $env:USERNAME)." -ForegroundColor Green
Write-Host "Check logs: scripts\update-automation\logs\daily-check.log" -ForegroundColor Cyan
Write-Host "Remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Cyan