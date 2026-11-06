# Removes the Windows Scheduled Task for the daily upstream check.
param([string]$TaskName = "GSTBilling-UpstreamDailyCheck")

$ErrorActionPreference = "Stop"
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
} else {
  Write-Host "Task '$TaskName' not found." -ForegroundColor Yellow
}