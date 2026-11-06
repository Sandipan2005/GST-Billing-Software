<#>
.SYNOPSIS
    Merge Upstream Changes - Free GST Billing Software
    Safely merges upstream changes while preserving your customizations.

.DESCRIPTION
    This script merges upstream/main into your main branch, then helps you
    rebase your customization branch. Run after daily-update-check.ps1 shows updates.

.NOTES
    Your customizations on 'my-custom-version' branch are preserved.
    Always backup data/ folder before merging!
#>

param(
    [switch]$Force,           # Force merge even with conflicts
    [switch]$SkipTest,        # Skip running tests after merge
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

function Confirm-Action($Message) {
    $response = Read-Host "`n$Message (y/N)"
    return $response -eq 'y' -or $response -eq 'Y'
}

Write-Color "╔══════════════════════════════════════════════════════════════╗" $Cyan
Write-Color "║        Merge Upstream Changes - GST Billing Software         ║" $Cyan
Write-Color "╚══════════════════════════════════════════════════════════════╝" $Cyan
Write-Host ""

Set-Location $RepoPath

# Verify git repo
if (-not (Test-Path ".git")) {
    Write-Color "❌ Not a git repository: $RepoPath" $Red
    exit 1
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Color "⚠️  You have uncommitted changes:" $Yellow
    git status --short
    if (-not $Force -and -not (Confirm-Action "Commit or stash changes before merging?")) {
        Write-Color "❌ Aborted. Commit or stash your changes first." $Red
        exit 1
    }
}

# Backup data folder
Write-Color "💾 Backing up data/ folder..." $Yellow
$backupDir = "data-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path "data" -Destination $backupDir -Recurse -Force
Write-Color "✅ Backup created: $backupDir" $Green

# Fetch latest upstream
Write-Color "📡 Fetching upstream..." $Yellow
git fetch upstream --quiet

# Show what will be merged
$newCommits = git log HEAD..upstream/main --oneline --no-merges
$commitCount = ($newCommits -split "`n" | Where-Object { $_ }).Count

if ($commitCount -eq 0) {
    Write-Color "✅ Already up to date!" $Green
    exit 0
}

Write-Color "📋 Will merge $commitCount commit(s):" $Yellow
$newCommits | ForEach-Object { Write-Host "   $_" }
Write-Host ""

if (-not $Force -and -not (Confirm-Action "Proceed with merge?")) {
    Write-Color "❌ Aborted by user." $Red
    exit 1
}

# Switch to main and merge
Write-Color "🔄 Switching to main branch..." $Yellow
git checkout main

Write-Color "🔄 Merging upstream/main..." $Yellow
$mergeResult = git merge upstream/main --no-edit 2>&1
$mergeExitCode = $LASTEXITCODE

if ($mergeExitCode -ne 0) {
    Write-Color "⚠️  Merge conflicts detected!" $Red
    Write-Host $mergeResult
    Write-Host ""
    Write-Color "📝 Conflicted files:" $Yellow
    git diff --name-only --diff-filter=U
    Write-Host ""
    Write-Color "🔧 Resolve conflicts manually, then run:" $Cyan
    Write-Color "   git add <resolved-files>" $Gray
    Write-Color "   git commit" $Gray
    Write-Color "   .\scripts\merge-upstream.ps1 -Force" $Gray
    exit 1
}

Write-Color "✅ Merge successful!" $Green

# Get new version
$newVersion = (Get-Content package.json | ConvertFrom-Json).version
Write-Color "📦 Updated to version: $newVersion" $Cyan

# Run tests unless skipped
if (-not $SkipTest) {
    Write-Color "🧪 Running tests..." $Yellow
    npm install 2>&1 | Out-Null
    $testResult = npm run test 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Color "❌ Tests failed!" $Red
        Write-Host $testResult
        if (-not (Confirm-Action "Tests failed. Continue anyway?")) {
            exit 1
        }
    } else {
        Write-Color "✅ All tests passed!" $Green
    }
}

# Now help rebase custom branch
Write-Host ""
Write-Color "🔄 Rebasing your customization branch ($CustomBranch)..." $Yellow
git checkout $CustomBranch

$rebaseResult = git rebase main 2>&1
$rebaseExitCode = $LASTEXITCODE

if ($rebaseExitCode -ne 0) {
    Write-Color "⚠️  Rebase conflicts with your customizations!" $Red
    Write-Host $rebaseResult
    Write-Host ""
    Write-Color "🔧 Resolve conflicts in your custom files, then run:" $Cyan
    Write-Color "   git add <resolved-files>" $Gray
    Write-Color "   git rebase --continue" $Gray
    Write-Host ""
    Write-Color "💡 Your customizations are in: $CustomBranch" $Cyan
    exit 1
}

Write-Color "✅ Rebase successful! Your customizations are updated." $Green

# Push custom branch
if (Confirm-Action "Push updated $CustomBranch to origin?") {
    git push origin $CustomBranch --force-with-lease
    Write-Color "✅ Pushed to origin/$CustomBranch" $Green
}

Write-Host ""
Write-Color "╔══════════════════════════════════════════════════════════════╗" $Cyan
Write-Color "║                    🎉 UPDATE COMPLETE!                       ║" $Cyan
Write-Color "╚══════════════════════════════════════════════════════════════╝" $Cyan
Write-Host ""
Write-Color "📋 Summary:" $Yellow
Write-Color "   • Merged $commitCount upstream commit(s)" $Gray
Write-Color "   • Updated to version $newVersion" $Gray
Write-Color "   • Rebased $CustomBranch" $Gray
Write-Color "   • Data backed up to: $backupDir" $Gray
Write-Host ""
Write-Color "🚀 Next steps:" $Yellow
Write-Color "   1. Test: npm run dev:win" $Gray
Write-Color "   2. Verify your custom features work" $Gray
Write-Color "   3. Delete backup when satisfied: Remove-Item $backupDir -Recurse" $Gray