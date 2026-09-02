# Copilot ROI Dashboard

This page explains the key measures used in the Power BI dashboard and how the ROI and acceptance metrics are calculated.

## 1. Core adoption and quality measures

These measures summarize how much Copilot usage is happening and how much of that usage is actually being accepted.

### Completion metrics

```dax
Suggestions Count = SUM(FactCompletionByLanguageEditor[suggestions_count])
Acceptances Count = SUM(FactCompletionByLanguageEditor[acceptances_count])
Lines Suggested = SUM(FactCompletionByLanguageEditor[lines_suggested])
Lines Accepted = SUM(FactCompletionByLanguageEditor[lines_accepted])

Acceptance Rate % = DIVIDE([Acceptances Count], [Suggestions Count], 0)
Line Acceptance Rate % = DIVIDE([Lines Accepted], [Lines Suggested], 0)

Active Users (Completion) = SUM(FactCompletionByLanguageEditor[engaged_users])
```

Interpretation:
- `Suggestions Count` = total code suggestions shown
- `Acceptances Count` = total suggestions accepted by users
- `Acceptance Rate %` = accepted suggestions ÷ total suggestions
- `Lines Suggested` and `Lines Accepted` track the volume of code lines suggested vs accepted
- `Active Users (Completion)` = engaged users in the completion dataset

### Chat metrics

```dax
Chat Turns = SUM(FactChatByEditorModel[chat_turns])

Chat Acceptances = SUM(FactChatByEditorModel[chat_copy_events]) + SUM(FactChatByEditorModel[chat_insertion_events])

Chat Acceptance Rate % = DIVIDE([Chat Acceptances], [Chat Turns], 0)

Active Users (Chat) = SUM(FactChatByEditorModel[chat_engaged_users])
```

Interpretation:
- `Chat Turns` = total chat interactions
- `Chat Acceptances` = sum of copy + insertion events when users accepted a chat suggestion
- `Chat Acceptance Rate %` = accepted chat actions ÷ total chat turns

Formula:

```text
Chat Acceptance Rate % = Chat Acceptances / Chat Turns
```

Example:
- 1,200 accepted chat actions
- 5,000 chat turns
- Chat acceptance rate = 1,200 / 5,000 = 24%

---

## 2. Seat utilization

```dax
Assigned Seats = DISTINCTCOUNT(FactSeatAssignmentsDaily[assignee_login])

Never Active Seats =
CALCULATE(
    DISTINCTCOUNT(FactSeatAssignmentsDaily[assignee_login]),
    ISBLANK(FactSeatAssignmentsDaily[last_activity_at])
)

Seat Activation Rate % = DIVIDE([Assigned Seats] - [Never Active Seats], [Assigned Seats], 0)

Inactive Seats (Billing Cycle) = SUM(FactSeatSummaryDaily[seats_inactive_this_cycle])
Active Seats (Billing Cycle) = SUM(FactSeatSummaryDaily[seats_active_this_cycle])
```

Interpretation:
- `Assigned Seats` = total seats assigned to users
- `Never Active Seats` = employees assigned a seat but with no recorded activity
- `Seat Activation Rate %` = active assigned seats ÷ total assigned seats
- Billing-cycle measures track seat activity within the current billing period

---

## 3. User metrics (28-day API snapshots)

```dax
User Metrics Users = DISTINCTCOUNT(FactUserMetricsDaily[user_login])

User Metrics Suggestions = SUM(FactUserMetricsDaily[code_generation_activity_count])
User Metrics Acceptances = SUM(FactUserMetricsDaily[code_acceptance_activity_count])

User Metrics Acceptance Rate % = DIVIDE([User Metrics Acceptances], [User Metrics Suggestions], 0)
User Metrics Active Days = DISTINCTCOUNT(FactUserMetricsDaily[day])
```

Interpretation:
- These are based on user-level snapshots over recent 28-day windows
- They help explain user engagement and adoption in a stabilized view
- `User Metrics Acceptance Rate %` is computed the same way as the general acceptance rate

---

## 4. ROI calculation

This dashboard uses a simplified ROI model based on assumptions.

```dax
Assumed Hours Saved Per Dev Per Day = 0.4
Assumed Developer Hourly Cost = 48
Assumed Copilot Monthly Cost Per Seat = 19
```

Then:

```dax
Estimated Daily Productivity Gain =
[Assigned Seats] * [Assumed Hours Saved Per Dev Per Day] * [Assumed Developer Hourly Cost]

Estimated Annual Productivity Gain =
[Estimated Daily Productivity Gain] * 260

Estimated Annual Copilot Cost =
[Assigned Seats] * [Assumed Copilot Monthly Cost Per Seat] * 12

Estimated Net Annual Benefit =
[Estimated Annual Productivity Gain] - [Estimated Annual Copilot Cost]

Estimated ROI % =
DIVIDE([Estimated Net Annual Benefit], [Estimated Annual Copilot Cost], 0)
```

Interpretation:
- The model assumes each assigned developer saves 0.4 hours per day
- Each hour is valued at $48
- Each seat costs $19 per month
- ROI is estimated as annual benefit minus annual cost, divided by annual cost

---

## 5. Why the ROI or value line may look flat

The ROI measures are intentionally based on fixed assumptions and a snapshot calculation. Because the formulas use constants such as:

- `Assumed Hours Saved Per Dev Per Day = 0.4`
- `Assumed Developer Hourly Cost = 48`
- `Assumed Copilot Monthly Cost Per Seat = 19`

...the value can appear flat across a trend if the `Assigned Seats` value does not materially change in the selected filter context.

In other words, the current model is closer to a static annualized estimate than a true time-series trend calculation.

If the dashboard is showing a flat line, that is usually expected unless:
- seat counts change over time,
- date context is included in the calculation,
- or the assumptions are intentionally made dynamic.

This is not necessarily a bug; it reflects the current design of the measures.

---

## 6. Summary of the key formulas

```text
Acceptance Rate % = accepted suggestions / total suggestions
Chat Acceptance Rate % = chat acceptances / total chat turns
Seat Activation Rate % = active assigned seats / total assigned seats
Estimated ROI % = (annual productivity gain - annual Copilot cost) / annual Copilot cost
```

---

## 7. Recommended onboarding note

When reviewing the dashboard:
1. Use the completion and chat acceptance measures to understand user behavior.
2. Use seat activation to understand whether the assigned seats are actually being used.
3. Use ROI as a directional estimate, not a precise financial model.
4. Treat the value and ROI trend as a snapshot unless a date-aware model is added.

This dashboard is best used for executive trend reporting and directional value estimation, not for detailed financial forecasting without additional assumptions and date-based modeling.
