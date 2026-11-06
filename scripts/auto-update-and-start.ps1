<#>
.SYNOPSIS
    Auto Update & Start - Bharat GST Billing
    Checks for upstream updates, merges if available, then starts the app.

.DESCRIPTION
    Run this instead of 'npm run dev:win'. It will:
    1. Check for upstream updates
    2. Auto-merge if no conflicts (preserves your customizations)
    3. Rebase your custom branch
    4. Start the development server

.NOTES
    Place this in your startup folder or create a shortcut for auto-start.
#>

param(
    [switch]$SkipMerge,        # Skip merge, just start
    [switch]$ForceMerge,       # Force merge even with conflicts (prompts)
    [switch]$NoInstall,        # Skip npm install
    [switch]$NoTest,           # Skip tests
    [string]$CustomBranch = "my-custom-version",
    [string]$RepoPath = "D:\Free-GST-Billing-Software"
)

$Green = [ConsoleColor]::Green
$Yellow = [ConsoleColor]::Yellow
$Red = [ConsoleColor]::Red
$Cyan = [ConsoleColor]::Cyan
$Gray = [ConsoleColor]::Gray

function Write-Color($Message, $Color) {
    Write-Host $Message -ForegroundColor $Color
}

function Show-Toast($Title, $Message) {
    try {
        $script = @"
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)
$text = $xml.GetElementsByTagName("text")
$text[0].AppendChild($xml.CreateTextNode("$Title")) | Out-Null
$text[1].AppendChild($xml.CreateTextNode("$Message")) | Out-Null
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("GST Billing Auto-Update").Show($toast)
"@
        powershell -Command $script 2>$null
    } catch { }
}

# Main
Write-Color "================================================================" $Cyan
Write-Color "     Auto Update & Start - GST Billing Software" $Cyan
Write-Color "================================================================" $Cyan
Write-Host ""

Set-Location $RepoPath

# Verify git repo
if (-not (Test-Path ".git")) {
    Write-Color "ERROR: Not a git repository: $RepoPath" $Red
    exit 1
}

# ============================================================
# STEP 1: Check for upstream updates
# ============================================================
Write-Color "Checking for upstream updates..." $Yellow
git fetch upstream --quiet

$newCommits = git log HEAD..upstream/main --oneline --no-merges
$commitCount = ($newCommits -split "`n" | Where-Object { $_ }).Count

if ($commitCount -eq 0) {
    $currentVersion = (Get-Content package.json | ConvertFrom-Json).version
    Write-Color "Already up to date (v$currentVersion)" $Green
}
else {
    Write-Color "$commitCount new upstream commit(s) found" $Yellow
    $newCommits | ForEach-Object { Write-Host "   $_" }
    Write-Host ""

    if (-not $SkipMerge) {
        # ============================================================
        # STEP 2: Auto-merge (if no conflicts)
        # ============================================================
        Write-Color "Attempting auto-merge..." $Yellow
        
        # Backup data
        $backupDir = "data-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path "data" -Destination $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Color "Data backed up to: $backupDir" $Gray

        # Stash any local changes
        $hasLocalChanges = (git status --porcelain).Length -gt 0
        if ($hasLocalChanges) {
            Write-Color "Stashing local changes..." $Yellow
            git stash push -m "auto-update-stash-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --include-untracked
        }

        # Switch to main and merge
        $currentBranch = git branch --show-current
        git checkout main --quiet
        
        $mergeResult = git merge upstream/main --no-edit 2>&1
        $mergeExitCode = $LASTEXITCODE

        if ($mergeExitCode -eq 0) {
            Write-Color "Auto-merge successful!" $Green
            
            # Get new version
            $newVersion = (Get-Content package.json | ConvertFrom-Json).version
            Write-Color "Updated to version: $newVersion" $Cyan

            # Rebase custom branch
            Write-Color "Rebasing $CustomBranch..." $Yellow
            git checkout $CustomBranch --quiet
            
            $rebaseResult = git rebase main 2>&1
            $rebaseExitCode = $LASTEXITCODE

            if ($rebaseExitCode -eq 0) {
                Write-Color "Rebase successful!" $Green
                
                # Restore stashed changes
                if ($hasLocalChanges) {
                    Write-Color "Restoring local changes..." $Yellow
                    git stash pop 2>$null
                }

                # Push custom branch
                Write-Color "Pushing updated $CustomBranch..." $Yellow
                git push origin $CustomBranch --force-with-lease --quiet
                Write-Color "Pushed to origin/$CustomBranch" $Green

                Show-Toast "GST Billing Updated" "Auto-merged $commitCount upstream commits. Version $newVersion"
            }
            else {
                Write-Color "Rebase conflicts - manual resolution needed" $Red
                Write-Host $rebaseResult
                Write-Host ""
                Write-Color "Resolve conflicts, then run:" $Cyan
                Write-Color "   git rebase --continue" $Gray
                Write-Color "   git push origin $CustomBranch --force-with-lease" $Gray
                Write-Host ""
                Write-Color "Starting app anyway (your custom branch has conflicts)..." $Yellow
                
                # Restore stashed changes
                if ($hasLocalChanges) {
                    git stash pop 2>$null
                }
                
                Show-Toast "GST Billing: Merge Conflict" "Upstream merge has conflicts. Resolve manually."
            }
        }
        else {
            Write-Color "Merge conflicts - manual resolution needed" $Red
            Write-Host $mergeResult
            Write-Host ""
            Write-Color "Resolve conflicts in main, then run:" $Cyan
            Write-Color "   git add <files> && git commit" $Gray
            Write-Color "   .\scripts\merge-upstream.ps1" $Gray
            Write-Host ""
            Write-Color "Starting app with current version..." $Yellow
            
            # Restore stashed changes
            if ($hasLocalChanges) {
                git stash pop 2>$null
            }
            
            # Go back to custom branch
            git checkout $CustomBranch --quiet
            
            Show-Toast "GST Billing: Merge Conflict" "Upstream merge has conflicts. Resolve manually."
        }
    }
    else {
        Write-Color "Skipping merge (--SkipMerge used)" $Yellow
    }
}

# ============================================================
# STEP 3: Install dependencies (if package.json changed)
# ============================================================
if (-not $NoInstall) {
    Write-Color "Checking dependencies..." $Yellow
    npm install 2>&1 | Out-Null
    Write-Color "Dependencies ready" $Green
}

# ============================================================
# STEP 4: Run tests (optional)
# ============================================================
if (-not $NoTest) {
    Write-Color "Running tests..." $Yellow
    $testResult = npm run test 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Color "Tests failed (continuing anyway)..." $Yellow
    } else {
        Write-Color "Tests passed" $Green
    }
}

# ============================================================
# STEP 5: Start the app
# ============================================================
Write-Host ""
Write-Color "Starting GST Billing Software..." $Green
Write-Color "================================================================" $Cyan

# Start server in background
$serverJob = Start-Job -ScriptBlock {
    param($path)
    Set-Location $path
    node server.js
} -ArgumentList $RepoPath

# Give server time to start
Start-Sleep -Seconds 2

# Start Vite dev server (this blocks)
Write-Color "Starting Vite dev server..." $Cyan
npm run dev:win

# Cleanup on exit
$serverJob | Stop-Job | Remove-Job