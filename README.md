# Copilot ROI Dashboard

This repository contains a Power BI dashboard for measuring Copilot adoption, usage quality, seat utilization, and estimated ROI across an organization.

The project includes:
- sample CSV data for local setup and testing,
- DAX measures for the dashboard,
- Power Query scripts for live GitHub API integration,
- setup and migration guides for onboarding and production use.

## Overview

The dashboard helps answer questions such as:
- How many users are actively using Copilot?
- What is the suggestion acceptance rate?
- What is the chat acceptance rate?
- How many seats are assigned vs active?
- What is the estimated annual productivity value and ROI?

## Repository structure

- `# Organization Adoption Page.md` — dashboard overview / presentation page
- `copilot_roi_powerbi_measures.dax` — main DAX measures used in the report
- `copilot_roi_powerbi_queries.pq` — Power Query M scripts for GitHub API data extraction
- `dashboard.pbix` — Power BI report file for the main dashboard
- `metrics.pbix` — alternate or supporting Power BI file
- `LIVE_API_MIGRATION_GUIDE.md` — step-by-step guide to replace sample CSVs with live GitHub data
- `PBIX_SETUP_INSTRUCTIONS.md` — instructions for loading data, creating relationships, and configuring the model
- `QUICK_MIGRATION_REFERENCE.md` — quick reference for migrating from sample data to live API data
- `ROI_DASHBOARD.md` — summary of ROI logic and dashboard interpretation
- `SAMPLE_DATA_GUIDE.md` — sample dataset reference and expected outputs
- `sample_data_*.csv` — sample data tables used for local testing and demo scenarios

## Quick start

### Option 1: Use the sample data

1. Open the Power BI file in Power BI Desktop.
2. Import the CSV files in the repository.
3. Add the measures from `copilot_roi_powerbi_measures.dax`.
4. Configure the relationships and visuals.
5. Use the sample data guide to validate the dashboard behavior.

### Option 2: Use live GitHub API data

1. Review `LIVE_API_MIGRATION_GUIDE.md`.
2. Replace the sample CSV queries with the Power Query script in `copilot_roi_powerbi_queries.pq`.
3. Update the GitHub token and org/enterprise slug values in the script.
4. Refresh the model and validate the tables and relationships.

## Data model

The dashboard is built around these key tables:

- `DimTeam` — team metadata
- `FactTeamMetricsDaily` — daily team usage
- `FactCompletionByLanguageEditor` — completions by language and editor
- `FactChatByEditorModel` — chat usage by editor and model
- `FactPRReviewsByRepo` — pull request review summary activity
- `FactDotcomChatByModel` — GitHub.com chat activity
- `FactSeatAssignmentsDaily` — seat assignment detail
- `FactSeatSummaryDaily` — seat summary by billing cycle
- `FactUserMetricsDaily` — user-level rolling 28-day metrics

## Key measured concepts

### Acceptance rate

Acceptance rate reflects how often users accept a suggestion versus how many suggestions were shown.

Formula:

```text
Acceptance Rate % = accepted suggestions / total suggestions
```

### Chat acceptance rate

Chat acceptance rate reflects how often a user accepts a chat suggestion by copying or inserting it.

Formula:

```text
Chat Acceptance Rate % = chat acceptances / total chat turns
```

### ROI

The dashboard estimates productivity value based on:
- assigned seats,
- estimated hours saved per developer per day,
- hourly cost assumptions,
- Copilot monthly seat cost.

The result is a directional annualized estimate rather than a precise financial model.

## Important notes

- The sample data is designed for local onboarding and testing.
- The live API flow requires a valid GitHub PAT and Copilot billing access.
- ROI and value measures are based on assumptions; they are best treated as directional indicators unless date-based assumptions are added.
- If you are using live data, keep the query names and column shapes aligned with those used by the measure definitions.

## Recommended onboarding path

1. Read `SAMPLE_DATA_GUIDE.md`.
2. Review `PBIX_SETUP_INSTRUCTIONS.md`.
3. Load the sample data and validate the DAX measures.
4. Review `ROI_DASHBOARD.md` to understand ROI logic.
5. Move to `LIVE_API_MIGRATION_GUIDE.md` when ready for production data.

## License and usage

This repository is intended for internal dashboarding and adoption analysis. Use and adapt the definitions based on your organization’s reporting requirements and data policies.

## Contributors

This project is maintained for internal adoption and productivity reporting in the Renishaw Copilot dashboard context.
