# Automated Upstream Update System (custom fork)

This keeps **your customizations** on `my-custom-version` while safely tracking updates from `IamRamgarhia/Free-GST-Billing-Software` (`upstream/main`). It **checks daily** and **never auto-merges** your local working copy.

## What’s included

| Component | Purpose |
|---|---|
| `.github/workflows/upstream-sync-check.yml` | Runs daily on GitHub Actions; opens/updates a PR into `my-custom-version` when upstream has new commits (no blind merge). |
| `scripts/update-automation/daily-check.ps1` | Local daily checker (fetch + report + log). Exit code `2` means updates available. |
| `scripts/update-automation/backup-data.ps1` | Backs up `data/`, `Saved Invoices/`, `Trash/` to `backups/`. |
| `scripts/update-automation/safe-merge-upstream.ps1` | Backup → fetch → show changes → merge upstream. Requires clean working tree. Optional `-RunTests`. |
| `scripts/update-automation/register-daily-task.ps1` | Registers a Windows Scheduled Task to run the local checker daily. |
| `scripts/update-automation/unregister-daily-task.ps1` | Removes that scheduled task. |

## One-time setup (already done in this repo clone)

```powershell
git remote -v
# origin   = https://github.com/Sandipan2005/GST-Billing-Software.git (your fork)
# upstream = https://github.com/IamRamgarhia/Free-GST-Billing-Software.git (original)

git checkout my-custom-version
git push -u origin my-custom-version   # requires access/auth to your fork
```

## Enable daily checks

### GitHub Actions (recommended)
1. Push this repo (including `.github/workflows/upstream-sync-check.yml`) to your fork.
2. Ensure Actions are enabled in the fork settings.
3. It runs daily (06:00 UTC) and on manual dispatch. When updates exist, it opens a PR to `my-custom-version`. **Review, back up data, test, then merge.**

### Local Windows scheduled task (optional)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/update-automation/register-daily-task.ps1 -At 09:00
```
Logs: `scripts/update-automation/logs/daily-check.log`

## Safe update flow (manual merge)
```powershell
# review only
powershell -ExecutionPolicy Bypass -File scripts/update-automation/daily-check.ps1

# backup + merge (after review)
powershell -ExecutionPolicy Bypass -File scripts/update-automation/safe-merge-upstream.ps1 -RunTests

# test
npm install          # if deps changed
npm run dev:win

# push your customized branch
git push origin my-custom-version
```

## Safety rules
- **Never auto-overwrite your working copy.** The workflow creates a PR; local scripts only merge when you run them.
- **Always back up `data/`, `Saved Invoices/`, and local business data** before merging.
- **Expect conflicts** in files you customize (branding/UI/GST logic). Resolve carefully and re-test.
- The upstream app also has an **in-app update checker** (separate from this Git workflow). If you customize heavily, prefer Git-based merges over replacing files/zips.

## Tuning
- Change schedule in the workflow `cron`.
- Change `-At` when registering the scheduled task.
- If your default branch differs, update `upstream_branch`/`UpstreamBranch` and PR `base`.