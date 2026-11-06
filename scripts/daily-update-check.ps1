<#>
.SYNOPSIS
    Daily Upstream Update Checker for Free GST Billing Software
    Checks for new commits from the official repository and notifies you.

.DESCRIPTION
    This script fetches upstream changes, compares with your local main branch,
    and creates a summary of new commits. Run daily via Task Scheduler.

.NOTES
    Author: Automated setup
    Repository: https://github.com/Sandipan2005/GST-Billing-Software
    Upstream: https://github.com/IamRamgarhia/Free-GST-Billing-Software
#>

param(
    [switch]$Notify,           # Show Windows toast notification
    [switch]$AutoMerge,        # Attempt auto-merge (use with caution)
    [string]$Branch = "main",  # Branch to check against
    [string]$RepoPath = "D:\Free-GST-Billing-Software"
)

# Colors for console output
$Green = [ConsoleColor]::Green
$Yellow = [ConsoleColor]::Yellow
$Red = [ConsoleColor]::Red
$Cyan = [ConsoleColor]::Cyan
$Gray = [ConsoleColor]::Gray

function Write-Color($Message, $Color) {
    Write-Host $Message -ForegroundColor $Color
}

function Show-Toast($Title, $Message) {
    if ($Notify) {
        $script = @"
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
\$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
\$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\$template)
\$text = \$xml.GetElementsByTagName("text")
\$text[0].AppendChild(\$xml.CreateTextNode("$Title")) | Out-Null
\$text[1].AppendChild(\$xml.CreateTextNode("$Message")) | Out-Null
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("GST Billing Updater").Show(\$toast)
"@
        powershell -Command $script 2>$null
    }
}

# Main execution
Write-Color "╔══════════════════════════════════════════════════════════════╗" $Cyan
Write-Color "║     Daily Upstream Update Check - GST Billing Software      ║" $Cyan
Write-Color "╚══════════════════════════════════════════════════════════════╝" $Cyan
Write-Host ""

Set-Location $RepoPath

# Verify git repo
if (-not (Test-Path ".git")) {
    Write-Color "❌ Not a git repository: $RepoPath" $Red
    exit 1
}

# Fetch upstream
Write-Color "📡 Fetching upstream changes..." $Yellow
git fetch upstream --quiet

# Get current version
$currentVersion = (Get-Content package.json | ConvertFrom-Json).version
Write-Color "📦 Current version: $currentVersion" $Cyan

# Check for new commits
$newCommits = git log HEAD..upstream/main --oneline --no-merges
$commitCount = ($newCommits -split "`n" | Where-Object { $_ }).Count

if ($commitCount -gt 0) {
    Write-Color "🔔 NEW UPDATES AVAILABLE: $commitCount commit(s)" $Green
    Write-Host ""
    Write-Color "📋 New commits:" $Yellow
    $newCommits | ForEach-Object { Write-Host "   $_" }
    Write-Host ""
    
    # Get latest upstream version
    $upstreamPkg = git show upstream/main:package.json 2>$null | ConvertFrom-Json
    if ($upstreamPkg) {
        Write-Color "🔖 Upstream version: $($upstreamPkg.version)" $Cyan
    }
    
    # Show notification
    Show-Toast "GST Billing Update" "$commitCount new upstream commits available. Run merge script to update."
    
    # Create summary file
    $summary = @"
# Daily Update Check - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Status: UPDATES AVAILABLE
- **New commits:** $commitCount
- **Current version:** $currentVersion
- **Upstream version:** $($upstreamPkg.version)

## New Commits:
$newCommits

## Next Steps:
1. Review changes: `git log HEAD..upstream/main --oneline`
2. Merge updates: `.\scripts\merge-upstream.ps1`
3. Test: `npm install && npm run test && npm run dev:win`
4. Push your customizations: `git push origin my-custom-version`

---
*Run this script daily via Task Scheduler for automatic checks.*
"@
    $summary | Out-File -FilePath ".\update-summary.md" -Encoding utf8
    Write-Color "📄 Summary saved to: update-summary.md" $Gray
    
    exit 0
}
else {
    Write-Color "✅ Already up to date with upstream" $Green
    Write-Color "📦 Current version: $currentVersion" $Cyan
    
    $summary = @"
# Daily Update Check - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Status: UP TO DATE
- **Current version:** $currentVersion
- **New commits:** 0

---
*Run this script daily via Task Scheduler for automatic checks.*
"@
    $summary | Out-File -FilePath ".\update-summary.md" -Encoding utf8
    
    exit 0
}