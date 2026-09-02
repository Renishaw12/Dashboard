# Quick Reference: Sample Data → Live API

## Files Involved

| File | Purpose |
|------|---------|
| `copilot_roi_powerbi_queries.pq` | Power Query M code (fetches live API data) |
| `copilot_roi_powerbi_measures.dax` | DAX measures (ROI %, adoption rates, etc.) |
| `LIVE_API_MIGRATION_GUIDE.md` | **START HERE** - Step-by-step migration |
| `CopilotROI_Dashboard.pbix` | Power BI template |
| `PBIX_SETUP_INSTRUCTIONS.md` | Initial setup (with sample data) |
| `SAMPLE_DATA_GUIDE.md` | How to use sample CSVs |
| `sample_data_*.csv` | Sample data files (9 files) |

## 3-Step Migration (Quick)

### Step 1: Prepare GitHub Token
```
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Set scope: manage_billing:copilot (required)
4. Copy token (you'll need this in Power BI)
```

### Step 2: Replace Queries in Power BI
```
1. Open CopilotROI_Dashboard.pbix
2. Home → Transform Data
3. Delete these 9 queries (keep DimDate):
   - DimTeam
   - FactTeamMetricsDaily
   - FactCompletionByLanguageEditor
   - FactChatByEditorModel
   - FactPRReviewsByRepo
   - FactDotcomChatByModel
   - FactSeatAssignmentsDaily
   - FactSeatSummaryDaily
   - FactUserMetricsDaily
4. Home → New Source → Blank Query
5. Advanced Editor → Paste entire copilot_roi_powerbi_queries.pq
6. Done
```

### Step 3: Configure & Load
```
In Power Query Editor, update (top of script):
  GitHubToken = "ghp_your_token_here"
  ScopeType = "orgs"  (or "enterprises")
  ScopeSlug = "your-org-name"

Then:
1. For each query (DimTeam, FactTeamMetricsDaily, etc):
   - Right-click → Enable Load
2. Home → Close & Apply
3. Wait 30-60 seconds for data to load
4. Check Data view → All tables should have rows
```

## API Structure

```
GitHub REST API
├── /orgs/{org}/teams                    → DimTeam
├── /orgs/{org}/team/{slug}/copilot/metrics → FactTeamMetricsDaily
│   ├── copilot_ide_code_completions     → FactCompletionByLanguageEditor
│   ├── copilot_ide_chat                 → FactChatByEditorModel
│   ├── copilot_dotcom_pull_requests     → FactPRReviewsByRepo
│   └── copilot_dotcom_chat              → FactDotcomChatByModel
├── /orgs/{org}/copilot/billing          → FactSeatSummaryDaily
├── /orgs/{org}/copilot/billing/seats    → FactSeatAssignmentsDaily
└── /orgs/{org}/copilot/metrics/reports/users-28-day/latest
    └─ download_links[] → FactUserMetricsDaily
```

## Key Differences: Sample vs Live

| Aspect | Sample CSVs | Live API |
|--------|-----------|----------|
| Data Refresh | Manual | Auto (daily/hourly) |
| Data Age | Static | Last 28 days (rolling) |
| Rows per Table | ~50-100 | Hundreds to thousands |
| Row Count | Fixed | Grows over time |
| Update Location | Local files | GitHub servers |
| Cost | Free | Free (GitHub API) |
| Setup Time | 5 min | 15-30 min |
| Ongoing Effort | None | Minimal (auto-refresh) |

## Troubleshooting Quick Ref

| Issue | Solution |
|-------|----------|
| 401 Bad credentials | Regenerate GitHub token, check scope |
| Rate limit exceeded | Use PAT (not anonymous), wait or refresh less often |
| No data in tables | Verify org has Copilot, teams exist, licenses active |
| Query timeout | Increase timeout in Options (10-15 min) |
| #ERROR in measures | Reload data, recreate relationships |

## Power BI Service Setup (Auto-Refresh)

```
1. File → Publish (to Power BI Service)
2. Go to Datasets, click dataset
3. Settings → Data source credentials
   - Method: OAuth2 (GitHub)
   - Sign in with your GitHub account
4. Settings → Scheduled refresh
   - Enable: ON
   - Frequency: Daily (or Hourly)
   - Time: 2:00 AM (off-peak)
   - Timezone: Your region
   - Save
```

## Parameters to Update

In `copilot_roi_powerbi_queries.pq`, line ~1-10:

```m
shared GitHubToken = "ghp_YOUR_TOKEN_HERE";
shared ScopeType = "orgs";         // or "enterprises"
shared ScopeSlug = "your-org-name";
```

**Example for ACME Corp:**
```m
shared GitHubToken = "ghp_1234567890abcdefghijklmnopqrstuvwxyz";
shared ScopeType = "orgs";
shared ScopeSlug = "acme-corp";
```

## Verification Checklist

After migration, verify:
- [ ] DimTeam has your teams (not sample teams)
- [ ] FactCompletionByLanguageEditor has your languages/editors
- [ ] FactSeatAssignmentsDaily matches your org's seat count
- [ ] At least one acceptance rate visual shows real %-values
- [ ] No #ERROR or loading indicators in tables

## What to Delete

❌ Delete these sample files (optional, after going live):
- `sample_data_*.csv` (all 9 files)
- `SAMPLE_DATA_GUIDE.md`

✅ Keep these:
- `copilot_roi_powerbi_queries.pq`
- `copilot_roi_powerbi_measures.dax`
- `PBIX_SETUP_INSTRUCTIONS.md`
- `LIVE_API_MIGRATION_GUIDE.md`
- `CopilotROI_Dashboard.pbix`

## Timeline

- **Preparation**: 5 min (get GitHub token)
- **Migration**: 15 min (delete queries, paste new ones, configure)
- **First Refresh**: 30-60 sec (Power Query fetches from API)
- **Validation**: 5 min (spot-check data against GitHub UI)
- **Go Live**: Publish to Service, enable auto-refresh

**Total: ~30-45 minutes first time. Subsequent refreshes: <1 min.**

---

Need help? See `LIVE_API_MIGRATION_GUIDE.md` for detailed troubleshooting.
