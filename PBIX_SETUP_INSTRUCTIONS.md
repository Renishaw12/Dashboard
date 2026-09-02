# GitHub Copilot ROI Dashboard - Power BI Setup

## Generated Files

- `CopilotROI_Dashboard.pbix` - Power BI template with schema and measures
- This file structure and the accompanying `.pq` and `.dax` files

## Next Steps

### 1. Open the PBIX in Power BI Desktop

```bash
# Windows
start CopilotROI_Dashboard.pbix

# Or open Power BI Desktop and File -> Open
```

### 2. Configure Data Source (Power Query)

1. **Home** -> **Get Data** -> **Blank Query**
2. **Advanced Editor** -> Paste content from `copilot_roi_powerbi_queries.pq`
3. Update these parameters at the top:
   ```
   GitHubToken = "ghp_your_github_pat_here"
   ScopeType = "orgs"  // or "enterprises"
   ScopeSlug = "your-org-name"
   ```
4. Click **Done** and let it load

### 3. Load All Queries

Power Query will auto-load these queries:
- DimTeam
- FactTeamMetricsDaily
- FactCompletionByLanguageEditor
- FactChatByEditorModel
- FactPRReviewsByRepo
- FactDotcomChatByModel
- FactSeatAssignmentsDaily
- FactSeatSummaryDaily
- FactUserMetricsDaily

### 4. Create Date Dimension

**Modeling** -> **New Table**:

```dax
DimDate = CALENDAR(DATE(2024,1,1), TODAY())
```

### 5. Add Measures

1. Go to **Modeling** tab
2. **New Measure**
3. Paste each measure from `copilot_roi_powerbi_measures.dax`
4. Assign each to its appropriate table

### 6. Create Relationships

**Modeling** -> **Manage Relationships**:

| From | To |
|------|-----|
| DimDate[Date] | FactCompletionByLanguageEditor[day] |
| DimDate[Date] | FactChatByEditorModel[day] |
| DimDate[Date] | FactPRReviewsByRepo[day] |
| DimDate[Date] | FactDotcomChatByModel[day] |
| DimDate[Date] | FactTeamMetricsDaily[day] |
| DimDate[Date] | FactUserMetricsDaily[day] |
| DimTeam[team_slug] | FactCompletionByLanguageEditor[team_slug] |
| DimTeam[team_slug] | FactChatByEditorModel[team_slug] |
| DimTeam[team_slug] | FactPRReviewsByRepo[team_slug] |
| DimTeam[team_slug] | FactDotcomChatByModel[team_slug] |

### 7. Build Report Pages

Follow the layout from `copilot_roi_dashboard_build_steps.txt`:

- **Executive ROI** - Cards + trend lines
- **Organization Adoption** - Suggestions/acceptances over time
- **Team Comparison** - Bar charts by team
- **Language + Editor Breakdown** - Matrix with heatmap
- **Chat + PR** - Trends and repository breakdown
- **Seat Utilization** - Seat metrics and user table
- **User Metrics** - User leaderboard

### 8. Publish to Power BI Service (Optional)

1. **File** -> **Publish**
2. Select workspace
3. Configure **Scheduled Refresh** (daily or hourly)
4. Update GitHub token if it expires

## GitHub PAT Requirements

Ensure your Personal Access Token has scope:
- `manage_billing:copilot` (required)
- `read:org` (for team listing)

Create token at: https://github.com/settings/tokens

## Refresh Strategy

- **Daily**: Sufficient for trend analysis
- **Hourly**: For real-time ROI dashboards
- Set via Power BI Service -> Dataset Settings -> Scheduled Refresh

## File Structure

```
CopilotROI_Dashboard.pbix
|- DataModel/model.json          (schema definition)
|- Report/Layout                 (visual placeholders)
|- Metadata.json                 (timestamp, version)
|- [Content_Types].xml
 - _rels/.rels
```

## Troubleshooting

- **"Bad credentials"** -> Check GitHubToken and PAT expiry
- **No data loading** -> Verify organization slug exists and has Copilot billing enabled
- **Query timeout** -> Increase Power Query timeout in Options
- **Measure errors** -> Ensure all fact tables are loaded before adding measures

## Customization

- Add slicers on scope_slug, team_slug, language, editor
- Create What-If parameters for ROI assumptions (hourly cost, daily time savings)
- Add drill-through from Team Comparison -> User Metrics
- Use conditional formatting on Acceptance Rate % heatmaps

---

Questions? Refer to `copilot_roi_powerbi_queries.pq` for data source details and `copilot_roi_powerbi_measures.dax` for measure definitions.
