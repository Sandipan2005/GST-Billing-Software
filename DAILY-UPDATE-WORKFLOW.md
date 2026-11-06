# Daily Update Workflow - Quick Reference

## 🔄 Automated Daily Check (GitHub Actions)
**File:** `.github/workflows/daily-upstream-sync.yml`
- Runs daily at 6:00 AM UTC (11:30 AM IST)
- Checks upstream for new commits
- Creates PR with upstream changes for review
- Notifies via GitHub if conflicts occur

## 🖥️ Local Daily Check (Task Scheduler)
**File:** `scripts/daily-update-check.ps1`
- Run via Windows Task Scheduler
- Shows Windows toast notification
- Creates `update-summary.md` with details

### Setup (Run Once as Admin):
```powershell
# Right-click PowerShell → "Run as Administrator"
.\scripts\setup-daily-task.ps1
```

### Manual Run:
```powershell
.\scripts\daily-update-check.ps1 -Notify
```

## 🔀 Merge Upstream Changes
**File:** `scripts/merge-upstream.ps1`
- Safely merges upstream/main into your main
- Rebases your `my-custom-version` branch
- Backs up `data/` folder automatically
- Runs tests after merge

### Usage:
```powershell
# After daily check shows updates:
.\scripts\merge-upstream.ps1

# Force merge (skip confirmations):
.\scripts\merge-upstream.ps1 -Force

# Skip tests (faster):
.\scripts\merge-upstream.ps1 -SkipTest
```

## 📋 Your Branch Structure
```
main                    ← Tracks upstream/main (auto-synced via PR)
my-custom-version       ← YOUR customizations (preserved!)
auto-sync-upstream-*    ← Temporary PR branches (auto-created)
```

## 🛡️ Safety Rules
1. **NEVER** overwrite `data/` folder - always backed up before merge
2. **ALWAYS** test after merge: `npm run dev:win`
3. **ALWAYS** rebase your custom branch after main updates
4. **COMMIT** your customizations before running merge

## 📅 Typical Weekly Flow
| Day | Action |
|-----|--------|
| Mon-Fri | Daily check runs automatically (no action needed) |
| Sat | Official release → PR created → Review & merge |
| Sun | Test your customizations on updated base |

## 🔗 Useful Commands
```powershell
# Check status manually
git fetch upstream
git log HEAD..upstream/main --oneline

# View update summary
cat update-summary.md

# See your custom commits
git log main..my-custom-version --oneline

# Push custom branch after rebase
git push origin my-custom-version --force-with-lease
```

## ⚠️ Troubleshooting
| Issue | Solution |
|-------|----------|
| Merge conflicts | Resolve in VS Code, then `git add . && git commit` |
| Rebase conflicts | Edit your custom files, `git rebase --continue` |
| Tests fail | Check `npm run test` output, fix issues |
| Data lost | Restore from `data-backup-YYYYMMDD-HHMMSS/` |

## 📞 Support
- GitHub Issues: https://github.com/Sandipan2005/GST-Billing-Software/issues
- Upstream: https://github.com/IamRamgarhia/Free-GST-Billing-Software