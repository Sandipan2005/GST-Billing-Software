<#>
.SYNOPSIS
    Setup Daily Update Check Task Scheduler
    Creates a Windows Task to run daily update check automatically.

.DESCRIPTION
    Run this ONCE as Administrator to create a scheduled task that runs
    daily-update-check.ps1 every day at 11:30 AM IST (6:00 AM UTC).

.NOTES
    Must run as Administrator!
#>

param(
    [string]$Time = "11:30",           # Daily run time (24-hour format)
    [string]$RepoPath = "D:\Free-GST-Billing-Software",
    [string]$TaskName = "GST Billing Daily Update Check"
)

# Check for Admin rights
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell → 'Run as Administrator' and try again." -ForegroundColor Yellow
    exit 1
}

$scriptPath = Join-Path $RepoPath "scripts\daily-update-check.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

# Create the scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Notify"
$trigger = New-ScheduledTaskTrigger -Daily -At $Time
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -Description "Checks for upstream updates to Free GST Billing Software daily"

Write-Host "✅ Scheduled task created: $TaskName" -ForegroundColor Green
Write-Host "⏰ Runs daily at $Time" -ForegroundColor Cyan
Write-Host "📁 Script: $scriptPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To verify: Task Scheduler → Task Scheduler Library → $TaskName" -ForegroundColor Gray
Write-Host "To run manually: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "To remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:$false" -ForegroundColor Gray