# Power BI Sample Data Import Guide

## Files Generated

1. `sample_data_DimTeam.csv` - Team dimension (5 teams)
2. `sample_data_FactTeamMetricsDaily.csv` - Daily active users by team (50 rows)
3. `sample_data_FactCompletionByLanguageEditor.csv` - Code completions by language/editor (36 rows)
4. `sample_data_FactChatByEditorModel.csv` - Chat usage by editor (18 rows)
5. `sample_data_FactPRReviewsByRepo.csv` - PR reviews by repository (16 rows)
6. `sample_data_FactDotcomChatByModel.csv` - GitHub.com chat usage (10 rows)
7. `sample_data_FactSeatAssignmentsDaily.csv` - Individual seat assignments (20 users)
8. `sample_data_FactSeatSummaryDaily.csv` - Seat summary (1 row)
9. `sample_data_FactUserMetricsDaily.csv` - Per-user metrics (17 users)

## Sample Data Overview

**Organization**: ACME Corp  
**Teams**: 5 (Backend, Frontend, DevOps, Data Science, Mobile)  
**Date Range**: 2025-02-01 to 2025-02-10  
**Active Users**: 17 developers  
**Seat Plan**: Business (20 seats, 16 active, 4 inactive)  

### Key Metrics (from sample):
- **Total Code Suggestions**: ~8,500 (Feb 1-2)
- **Total Acceptances**: ~6,100 (71% acceptance rate)
- **Lines of Code Suggested**: ~31,000
- **Lines of Code Accepted**: ~22,200 (71% line acceptance)
- **Chat Turns**: ~650 (Feb 1-2)
- **PR Summaries Created**: ~120
- **Assigned Seats**: 20
- **Active Users (Billing Cycle)**: 16

## Import Steps

### Option 1: Manual CSV Import (Recommended for first-time)

1. **Open CopilotROI_Dashboard.pbix** in Power BI Desktop
2. **Home** → **Get Data** → **Text/CSV**
3. For each sample data file:
   - Select file
   - Click **Load** (or **Transform Data** for edits)
   - Verify column types
   - Name the query to match the table name

4. **Repeat for all 9 files**:
   - `sample_data_DimTeam.csv` → Query: `DimTeam`
   - `sample_data_FactTeamMetricsDaily.csv` → Query: `FactTeamMetricsDaily`
   - `sample_data_FactCompletionByLanguageEditor.csv` → Query: `FactCompletionByLanguageEditor`
   - `sample_data_FactChatByEditorModel.csv` → Query: `FactChatByEditorModel`
   - `sample_data_FactPRReviewsByRepo.csv` → Query: `FactPRReviewsByRepo`
   - `sample_data_FactDotcomChatByModel.csv` → Query: `FactDotcomChatByModel`
   - `sample_data_FactSeatAssignmentsDaily.csv` → Query: `FactSeatAssignmentsDaily`
   - `sample_data_FactSeatSummaryDaily.csv` → Query: `FactSeatSummaryDaily`
   - `sample_data_FactUserMetricsDaily.csv` → Query: `FactUserMetricsDaily`

5. **Create DimDate table**:
   - Modeling → New Table
   - Paste:
   ```dax
   DimDate = CALENDAR(DATE(2025,2,1), DATE(2025,2,10))
   ```

6. **Add DAX measures** from `copilot_roi_powerbi_measures.dax`

7. **Create relationships** (see PBIX_SETUP_INSTRUCTIONS.md)

8. **Build visuals** and test the dashboard

### Option 2: Append via Power Query (Advanced)

If you want to use Power Query M code to import all CSVs programmatically:

```m
let
    FolderPath = "C:\Users\tulikap\.copilot\chats\0e9fd005-517e-4253-8402-8af38adaa36c",
    Files = Folder.Files(FolderPath),
    SampleDataFiles = Table.SelectRows(Files, each Text.StartsWith([Name], "sample_data_")),
    
    LoadAndTransform = Table.AddColumn(
        SampleDataFiles,
        "Data",
        each
            let
                File = [Content],
                Csv = Csv.Document(File),
                Table = Table.PromoteHeaders(Csv)
            in
                Table
    ),
    
    ExpandData = Table.ExpandTableColumn(
        LoadAndTransform,
        "Data",
        Table.ColumnNames(LoadAndTransform{0}[Data])
    )
in
    ExpandData
```

### Option 3: Use Linked Tables (if data updates)

To keep data linked to source CSVs:

1. Do NOT click "Load" after importing CSV
2. Instead, click **Close & Apply** to keep query active
3. Right-click query → **Enable Load**
4. Now data auto-refreshes when CSVs change

## Sample Data Schema Reference

### DimTeam
- 5 teams with IDs, slugs, names
- Scope: acme-corp

### FactTeamMetricsDaily
- 50 rows covering 2025-02-01 to 2025-02-10
- Daily active user counts by team
- Values: 4-16 active users per team per day

### FactCompletionByLanguageEditor
- 36 rows with language/editor breakdowns
- Languages: Python, JavaScript, Go, Java, TypeScript, CSS, YAML, Shell, HCL, Swift, Kotlin
- Editors: VSCode, JetBrains, Jupyter, PyCharm, WebStorm, Xcode, AndroidStudio
- Metrics: suggestions, acceptances, lines (all with ~65-70% acceptance rate)

### FactChatByEditorModel
- 18 rows of Copilot Chat usage by editor
- Chat turns, copy events, insertion events
- Avg 40-50 turns/day per editor

### FactPRReviewsByRepo
- 16 rows of PR summaries by repository
- Repos: api-server, database-lib, web-app, component-lib, infrastructure, ml-models, ios-app, android-app
- ~4-15 PR summaries per repo per day

### FactDotcomChatByModel
- 10 rows of GitHub.com chat usage
- Teams using chat on GitHub.com
- ~15-52 turns/day

### FactSeatAssignmentsDaily
- 20 individual seat assignments
- 17 active, 2 never activated, 1 inactive in past 5 days
- Last activity tracked (most within 2025-02-08 to 2025-02-10)

### FactSeatSummaryDaily
- Single summary row
- 20 total seats, 16 active this cycle, 4 inactive
- 2 added this cycle, 1 pending cancellation

### FactUserMetricsDaily
- 17 users (matching the 17 active seats)
- Code activity: 25-55 suggestions/day
- Acceptance rates: 60-75%
- Chat usage: 14 users used chat, 6 used agents

## Expected Dashboard Behavior (with sample data)

### Executive ROI Page
- **Assigned Seats**: 20
- **Estimated Annual Copilot Cost**: $4,560 (20 * 19 * 12)
- **Estimated Productivity Gain**: $998,400 (20 * 0.4 hrs * $48/hr * 260 days)
- **Estimated ROI**: 2,089%

### Organization Adoption
- **Avg Acceptance Rate**: ~71%
- **Total Suggestions (2 days)**: ~8,500
- **Total Acceptances (2 days)**: ~6,100
- **Active Users**: 43 (sum across teams over 2 days, with overlap)

### Team Comparison
- **Backend**: Highest by suggestions (avg 1,600+/day)
- **Frontend**: Strong adoption, high chat usage
- **DevOps**: Lower usage (4-6 active users)
- **Data Science**: High chat engagement
- **Mobile**: Moderate usage (5-7 active users)

### Language Breakdown
- **Python**: Dominant (data science, backend)
- **JavaScript**: High in frontend teams
- **TypeScript**: Frontend component library
- **Other langs**: Less used but present

### Chat + PR
- **Avg Chat Acceptance Rate**: ~75% (copy + insertion events)
- **PR Reviews**: Strong adoption (120+ summaries over 2 days)

### Seat Utilization
- **16/20 active** (80% activation)
- **2 never activated** (assigned but no login)
- **1 inactive** (last activity > 2 days ago, within this cycle)
- **1 pending cancellation**

### User Metrics Leaderboard
- **jack.anderson** (Data Science): 96 activities (highest)
- **diana.miller** (Frontend): 89 activities
- **evelyn.brown** (Frontend): 82 activities
- **laura.thomas** (Data Science): 77 activities

## Customizing Sample Data

To create your own sample data matching your organization:

1. **Adjust team names/slugs** in DimTeam
2. **Scale metrics** (double suggestions if 40 developers instead of 20)
3. **Match your languages** (remove unused, add custom)
4. **Match your editors** (VS Code dominates most orgs)
5. **Add your repositories**
6. **Use realistic dates** (last 30-90 days)

## Cleanup

When switching to real GitHub API data:

1. Disable or delete the sample CSV queries
2. Enable the Power Query scripts from `copilot_roi_powerbi_queries.pq`
3. Configure GitHub token
4. Let it auto-refresh

The visuals will automatically switch to real data since they're bound to table/measure names, not query names.

---

**Next Step**: Import the CSVs, create DimDate, add measures, build relationships, then create your first visual!
