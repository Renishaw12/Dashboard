# Replace Sample CSVs with Live GitHub API Data

## Overview

This guide walks you through replacing the sample CSV files with live Power Query scripts that fetch Copilot metrics directly from GitHub REST API.

**What changes:**
- Sample CSV queries → Dynamic Power Query (M code) pulling from GitHub
- Manual refresh → Automatic daily/hourly refresh in Power BI Service
- Static 9 rows → Unlimited historical trending (30+ days)

## Prerequisites

1. **GitHub Personal Access Token (PAT)**
   - Scope: `manage_billing:copilot` (required)
   - Scope: `read:org` (optional, for team listing)
   - Create at: https://github.com/settings/tokens
   - Keep token secret (store in Power BI Service, not in code)

2. **Organization/Enterprise slug**
   - Org: `your-org-name` (for `orgs` scope)
   - Enterprise: `your-enterprise-slug` (for `enterprises` scope)
   - Verify at: https://github.com/orgs/{slug}/settings or https://github.com/enterprises/{slug}

3. **Copilot billing enabled**
   - Organization must have Copilot for Business license
   - Verify: Go to https://github.com/orgs/{org}/copilot/billing

## Step-by-Step Setup

### Step 1: Delete Sample CSV Queries

In Power BI Desktop:

1. **Home** → **Transform Data** → **Power Query Editor**
2. In **Queries** pane (left), select each sample query:
   - Right-click → **Delete**
   - Or select query → **Home** → **Delete**
3. Delete these 9 queries:
   - DimTeam
   - FactTeamMetricsDaily
   - FactCompletionByLanguageEditor
   - FactChatByEditorModel
   - FactPRReviewsByRepo
   - FactDotcomChatByModel
   - FactSeatAssignmentsDaily
   - FactSeatSummaryDaily
   - FactUserMetricsDaily

4. Keep **DimDate** (or recreate if needed)

### Step 2: Import Power Query Code

1. **Home** → **New Source** → **Blank Query**
2. **Advanced Editor** → Clear default code
3. Open `copilot_roi_powerbi_queries.pq` in a text editor
4. Copy **entire file content**
5. Paste into Power Query **Advanced Editor**
6. Click **Done**

**What happens:**
- Power Query loads as a **section** with multiple shared functions
- All 9 fact/dim queries become available

### Step 3: Update Parameters

At the **top** of the Power Query script, update these 3 values:

```m
shared GitHubToken = "ghp_your_token_here";
shared ScopeType = "orgs";           // Change to "enterprises" if needed
shared ScopeSlug = "your-org-slug";  // Your org name (no spaces, lowercase)
```

**Examples:**

```m
// For organization
shared GitHubToken = "ghp_xxxxxxxxxxxxxxxxxxxx";
shared ScopeType = "orgs";
shared ScopeSlug = "acme-corp";

// For enterprise
shared GitHubToken = "ghp_xxxxxxxxxxxxxxxxxxxx";
shared ScopeType = "enterprises";
shared ScopeSlug = "acme-enterprise";
```

### Step 4: Enable Queries

1. In Power Query Editor, expand the queries list
2. Each `shared` function (DimTeam, FactTeamMetricsDaily, etc.) is now available
3. Right-click each one → **Enable Load**:
   - DimTeam
   - FactTeamMetricsDaily
   - FactCompletionByLanguageEditor
   - FactChatByEditorModel
   - FactPRReviewsByRepo
   - FactDotcomChatByModel
   - FactSeatAssignmentsDaily
   - FactSeatSummaryDaily
   - FactUserMetricsDaily

4. **Home** → **Close & Apply**
5. Power BI will attempt to load data from GitHub API

### Step 5: Test Data Load

**Check if queries loaded:**

1. **Model** view (left panel)
2. Verify all 9 tables appear:
   - Each should show row count (e.g., "DimTeam: 15 rows")
   - If "Error" appears, see **Troubleshooting** below

3. **Data** view → Select each table → Verify data:
   - **DimTeam**: Should show your actual GitHub teams
   - **FactCompletionByLanguageEditor**: Should show last 28 days of metrics
   - **FactSeatAssignmentsDaily**: Should show your assigned seats
   - **FactUserMetricsDaily**: Should show per-user 28-day rolling window

### Step 6: Refresh Relationships & Measures

Since we deleted the sample queries, Power BI may have cleared relationships.

1. **Modeling** → **Manage Relationships**
2. Verify these exist (if not, create them):

| From Table | From Column | To Table | To Column |
|-----------|-----------|---------|----------|
| DimDate | Date | FactCompletionByLanguageEditor | day |
| DimDate | Date | FactChatByEditorModel | day |
| DimDate | Date | FactPRReviewsByRepo | day |
| DimDate | Date | FactDotcomChatByModel | day |
| DimDate | Date | FactTeamMetricsDaily | day |
| DimDate | Date | FactUserMetricsDaily | day |
| DimTeam | team_slug | FactCompletionByLanguageEditor | team_slug |
| DimTeam | team_slug | FactChatByEditorModel | team_slug |
| DimTeam | team_slug | FactPRReviewsByRepo | team_slug |
| DimTeam | team_slug | FactDotcomChatByModel | team_slug |

3. **Modeling** → Verify all measures are still present (they should be)

### Step 7: Test Visuals

1. Create a test visual (e.g., Card showing "Assigned Seats")
2. If it shows a number, live API is working
3. Check a few values against GitHub Copilot Insights UI to validate

## API Calls Made by Each Query

### DimTeam
```
GET /orgs/{org}/teams?page=1&per_page=100
```
- Lists all teams in the organization
- Paginated (100 per page)
- Updates on each refresh

### FactTeamMetricsDaily
```
GET /orgs/{org}/team/{team_slug}/copilot/metrics
```
- Metrics for each team (last 28 days)
- Called once per team
- Returns daily breakdown: suggestions, acceptances, chat, PR reviews

### FactCompletionByLanguageEditor
```
GET /orgs/{org}/team/{team_slug}/copilot/metrics
  └─ Expand copilot_ide_code_completions.editors[].models[].languages[]
```
- Flattens completion data by language/editor
- Includes active users, suggestion counts, line counts
- Auto-calculated acceptance rates

### FactChatByEditorModel
```
GET /orgs/{org}/team/{team_slug}/copilot/metrics
  └─ Expand copilot_ide_chat.editors[].models[]
```
- Chat usage by editor and model
- Chat turns, copy events, insertion events

### FactPRReviewsByRepo
```
GET /orgs/{org}/team/{team_slug}/copilot/metrics
  └─ Expand copilot_dotcom_pull_requests.repositories[].models[]
```
- PR review summaries created per repository

### FactDotcomChatByModel
```
GET /orgs/{org}/team/{team_slug}/copilot/metrics
  └─ Expand copilot_dotcom_chat.models[]
```
- GitHub.com chat usage (not IDE chat)

### FactSeatAssignmentsDaily
```
GET /orgs/{org}/copilot/billing/seats?page=1&per_page=100
```
- Individual seat assignments
- Shows: last_activity_at, assignee_login, assigning_team
- Paginated

### FactSeatSummaryDaily
```
GET /orgs/{org}/copilot/billing
```
- Seat summary: total, active, inactive, pending
- Single row per refresh

### FactUserMetricsDaily
```
GET /orgs/{org}/copilot/metrics/reports/users-28-day/latest
  └─ Download each link in download_links[]
```
- Per-user metrics (28-day rolling window)
- Downloads NDJSON files from Azure Blob Storage
- Parses each line as JSON record

## Refresh Schedule

### Option A: Power BI Desktop (Manual)

1. **Home** → **Refresh**
2. All queries re-run in sequence (~30-60 seconds)
3. Visuals update automatically

### Option B: Power BI Service (Automatic)

1. **Publish** the PBIX to Power BI Service:
   - **File** → **Publish**
   - Select workspace
   - Navigate to published report

2. Go to **Datasets** in Power BI Service:
   - Right-click the dataset
   - **Settings** → **Data source credentials**
   - Select **OAuth2** as authentication method
   - Sign in with your GitHub account (or use PAT in Basic auth)

3. **Scheduled Refresh**:
   - **Settings** → **Scheduled refresh**
   - Enable toggle
   - **Refresh frequency**: Daily or Hourly
   - **Time**: Off-peak hours (e.g., 2 AM)
   - **Timezone**: Your region
   - Click **Apply**

4. Power BI Service will now auto-refresh on schedule

**Note**: If GitHub token expires, update credentials in Power BI Service settings (no PBIX republish needed).

## Troubleshooting

### "Bad credentials" or 401 Error

**Cause**: Invalid or expired GitHub token

**Fix**:
1. Generate new PAT: https://github.com/settings/tokens
2. Verify scope includes `manage_billing:copilot`
3. Update `GitHubToken` value in Power Query
4. **Home** → **Refresh**

### "Rate limit exceeded"

**Cause**: GitHub API rate limits (60 req/min unauthenticated, 5,000/hr authenticated)

**Fix**:
- Refresh is ~20-30 API calls, usually safe
- If hitting limits, ensure PAT is being used (not anonymous)
- Increase refresh interval (e.g., daily instead of hourly)

### No data in tables

**Cause**: Organization doesn't have Copilot or no teams defined

**Fix**:
1. Verify at: https://github.com/orgs/{org}/copilot/billing
2. Ensure Copilot is enabled and has active licenses
3. Create at least one team: https://github.com/orgs/{org}/teams
4. Assign users to teams

### "Query timeout" in Power Query

**Cause**: Network slow or organization has many teams/users

**Fix**:
1. **File** → **Options** → **Query Editor** → **Regional Settings**
2. Increase **Query timeout** to 10-15 minutes
3. Retry

### Measures show errors (#ERROR)

**Cause**: Table didn't load, so measure has no data

**Fix**:
1. Check **Data** view → Verify all tables have rows
2. Recreate relationships (see Step 6)
3. Reload measures if needed

### "Cannot activate Premium feature" error

**Cause**: Some Power Query connectors require Premium in Power BI Service

**Fix**:
- This is unlikely for REST API queries
- If it occurs, try publishing to Premium workspace
- Or refresh only in Power BI Desktop (no Service refresh)

## Migration Checklist

- [ ] Create GitHub PAT with `manage_billing:copilot` scope
- [ ] Note organization/enterprise slug
- [ ] Delete 9 sample CSV queries
- [ ] Import Power Query code from `copilot_roi_powerbi_queries.pq`
- [ ] Update GitHubToken, ScopeType, ScopeSlug parameters
- [ ] Enable load on all 9 queries
- [ ] Refresh data (should see real GitHub data)
- [ ] Create/verify DimDate table
- [ ] Verify all relationships exist
- [ ] Test a few visuals with real data
- [ ] Publish to Power BI Service
- [ ] Configure scheduled refresh
- [ ] Set up data source credentials (OAuth2 or PAT)
- [ ] Monitor first refresh in Service

## What Data You'll See

Once live data loads:

### Expected Row Counts (examples)
- **DimTeam**: N teams in your org (5-50+)
- **FactTeamMetricsDaily**: ~N teams × 28 days = 140-1,400 rows
- **FactCompletionByLanguageEditor**: ~500-5,000 rows (28 days × languages × editors)
- **FactChatByEditorModel**: ~100-500 rows
- **FactPRReviewsByRepo**: ~50-500 rows
- **FactDotcomChatByModel**: ~10-100 rows
- **FactSeatAssignmentsDaily**: Number of assigned seats (10-1,000+)
- **FactSeatSummaryDaily**: 1 row (latest snapshot)
- **FactUserMetricsDaily**: Number of users with activity in last 28 days (10-5,000+)

### Expected Metrics (examples)
- **Suggestions (28 days)**: Hundreds to millions (depends on org size)
- **Acceptance Rate**: Typically 40-75%
- **Active Users**: ~30-80% of assigned seats
- **Chat Adoption**: 20-50% of active developers
- **PR Summaries**: 10-100s per day in active teams

## Next Steps

1. **Go live**: Replace CSVs → configure GitHub API
2. **Monitor**: Check first refresh, validate data against GitHub UI
3. **Customize**: Add more pages, slicers, advanced measures
4. **Share**: Publish to Power BI Service, grant read access to stakeholders
5. **Iterate**: Collect feedback, refine dashboards quarterly

## Support

### Common Questions

**Q: Can I use multiple organizations?**  
A: Yes. Duplicate the Power Query section, set different ScopeSlug values, then append all fact tables.

**Q: How do I exclude inactive teams?**  
A: Filter DimTeam in Power Query before returning (add step: `Table.SelectRows(Teams, each [team_activity] > threshold)`)

**Q: Can I add custom fields (cost allocation, team lead)?**  
A: Yes. Add columns in Power Query or create lookup tables in the model.

**Q: How often should I refresh?**  
A: Daily for trend analysis. Hourly if you want real-time dashboards (uses more API quota).

**Q: What if we switch GitHub accounts?**  
A: Update GitHubToken in Power Query, republish, update credentials in Service.

---

**Ready to go live?** Follow the migration checklist above. Should take ~15-30 minutes total.
