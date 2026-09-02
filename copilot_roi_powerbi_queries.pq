section CopilotROI;

shared GitHubApiVersion = "2022-11-28";
shared GitHubToken = "ghp_replace_me";
shared ScopeType = "orgs"; // orgs | enterprises
shared ScopeSlug = "your-scope-slug";
shared TeamPageSize = 100;

shared fnGitHubRequest = (relativePath as text, optional query as nullable record) as any =>
let
    BaseUrl = "https://api.github.com",
    Headers = [
        Accept = "application/vnd.github+json",
        #"X-GitHub-Api-Version" = GitHubApiVersion,
        Authorization = "Bearer " & GitHubToken
    ],
    Options = if query = null
        then [RelativePath = relativePath, Headers = Headers]
        else [RelativePath = relativePath, Headers = Headers, Query = query],
    Response = Web.Contents(BaseUrl, Options),
    Parsed = Json.Document(Response)
in
    Parsed;

shared fnGitHubPagedList = (relativePath as text, optional pageSize as nullable number) as list =>
let
    PerPage = if pageSize = null then 100 else pageSize,
    Pages = List.Generate(
        () => [Page = 1, Items = try fnGitHubRequest(relativePath, [per_page = Text.From(PerPage), page = "1"]) otherwise {}],
        each List.Count([Items]) > 0,
        each [Page = [Page] + 1, Items = try fnGitHubRequest(relativePath, [per_page = Text.From(PerPage), page = Text.From([Page] + 1)]) otherwise {}],
        each [Items]
    ),
    Combined = List.Combine(Pages)
in
    Combined;

shared DimTeam =
let
    TeamsRaw = fnGitHubPagedList(ScopeType & "/" & ScopeSlug & "/teams", TeamPageSize),
    TeamsTable = Table.FromList(TeamsRaw, Splitter.SplitByNothing(), {"team"}, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(
        TeamsTable,
        "team",
        {"id", "slug", "name", "description"},
        {"team_id", "team_slug", "team_name", "team_description"}
    ),
    WithScope = Table.AddColumn(Expanded, "scope_slug", each ScopeSlug, type text)
in
    WithScope;

shared FactTeamMetricsDaily =
let
    Teams = DimTeam,
    TeamSlugs = try Table.Column(Teams, "team_slug") otherwise {},
    TeamBundles = List.Transform(
        TeamSlugs,
        (s) => [
            team_slug = s,
            metrics = try fnGitHubRequest(ScopeType & "/" & ScopeSlug & "/team/" & s & "/copilot/metrics") otherwise {}
        ]
    ),
    TeamBundleTable = Table.FromRecords(TeamBundles),
    ExpandedMetrics = Table.ExpandListColumn(TeamBundleTable, "metrics"),
    ExpandedMetricsRecord = Table.ExpandRecordColumn(
        ExpandedMetrics,
        "metrics",
        {"date", "total_active_users", "copilot_ide_code_completions", "copilot_ide_chat", "copilot_dotcom_pull_requests", "copilot_dotcom_chat"},
        {"day", "total_active_users", "copilot_ide_code_completions", "copilot_ide_chat", "copilot_dotcom_pull_requests", "copilot_dotcom_chat"}
    ),
    AddedScope = Table.AddColumn(ExpandedMetricsRecord, "scope_slug", each ScopeSlug, type text),
    Typed = Table.TransformColumnTypes(AddedScope, {{"day", type date}, {"total_active_users", Int64.Type}})
in
    Typed;

shared FactCompletionByLanguageEditor =
let
    Source = FactTeamMetricsDaily,
    AddEditors = Table.AddColumn(Source, "editors", each try [copilot_ide_code_completions][editors] otherwise {}, type list),
    ExpandEditors = Table.ExpandListColumn(AddEditors, "editors"),
    ExpandEditorRecord = Table.ExpandRecordColumn(ExpandEditors, "editors", {"name", "models"}, {"editor", "models"}),
    ExpandModels = Table.ExpandListColumn(ExpandEditorRecord, "models"),
    ExpandModelRecord = Table.ExpandRecordColumn(ExpandModels, "models", {"name", "languages"}, {"model", "languages"}),
    ExpandLanguages = Table.ExpandListColumn(ExpandModelRecord, "languages"),
    ExpandLanguageRecord = Table.ExpandRecordColumn(
        ExpandLanguages,
        "languages",
        {"name", "total_engaged_users", "total_code_suggestions", "total_code_acceptances", "total_code_lines_suggested", "total_code_lines_accepted"},
        {"language", "engaged_users", "suggestions_count", "acceptances_count", "lines_suggested", "lines_accepted"}
    ),
    Selected = Table.SelectColumns(
        ExpandLanguageRecord,
        {"scope_slug", "team_slug", "day", "editor", "model", "language", "engaged_users", "suggestions_count", "acceptances_count", "lines_suggested", "lines_accepted"}
    ),
    Typed = Table.TransformColumnTypes(
        Selected,
        {
            {"engaged_users", Int64.Type},
            {"suggestions_count", Int64.Type},
            {"acceptances_count", Int64.Type},
            {"lines_suggested", Int64.Type},
            {"lines_accepted", Int64.Type}
        }
    )
in
    Typed;

shared FactChatByEditorModel =
let
    Source = FactTeamMetricsDaily,
    AddEditors = Table.AddColumn(Source, "chat_editors", each try [copilot_ide_chat][editors] otherwise {}, type list),
    ExpandEditors = Table.ExpandListColumn(AddEditors, "chat_editors"),
    ExpandEditorRecord = Table.ExpandRecordColumn(ExpandEditors, "chat_editors", {"name", "models"}, {"editor", "models"}),
    ExpandModels = Table.ExpandListColumn(ExpandEditorRecord, "models"),
    ExpandModelRecord = Table.ExpandRecordColumn(
        ExpandModels,
        "models",
        {"name", "total_chats", "total_chat_copy_events", "total_chat_insertion_events", "total_engaged_users"},
        {"model", "chat_turns", "chat_copy_events", "chat_insertion_events", "chat_engaged_users"}
    ),
    Selected = Table.SelectColumns(
        ExpandModelRecord,
        {"scope_slug", "team_slug", "day", "editor", "model", "chat_turns", "chat_copy_events", "chat_insertion_events", "chat_engaged_users"}
    ),
    Typed = Table.TransformColumnTypes(
        Selected,
        {
            {"chat_turns", Int64.Type},
            {"chat_copy_events", Int64.Type},
            {"chat_insertion_events", Int64.Type},
            {"chat_engaged_users", Int64.Type}
        }
    )
in
    Typed;

shared FactPRReviewsByRepo =
let
    Source = FactTeamMetricsDaily,
    AddRepos = Table.AddColumn(Source, "repos", each try [copilot_dotcom_pull_requests][repositories] otherwise {}, type list),
    ExpandRepos = Table.ExpandListColumn(AddRepos, "repos"),
    ExpandRepoRecord = Table.ExpandRecordColumn(ExpandRepos, "repos", {"name", "total_pr_summaries_created", "models"}, {"repository", "repo_pr_summaries", "models"}),
    ExpandModels = Table.ExpandListColumn(ExpandRepoRecord, "models"),
    ExpandModelRecord = Table.ExpandRecordColumn(ExpandModels, "models", {"name", "total_pr_summaries_created"}, {"model", "model_pr_summaries"}),
    AddPRCount = Table.AddColumn(ExpandModelRecord, "pr_summaries_created", each if [model_pr_summaries] = null then [repo_pr_summaries] else [model_pr_summaries], Int64.Type),
    Selected = Table.SelectColumns(AddPRCount, {"scope_slug", "team_slug", "day", "repository", "model", "pr_summaries_created"})
in
    Selected;

shared FactDotcomChatByModel =
let
    Source = FactTeamMetricsDaily,
    AddModels = Table.AddColumn(Source, "dotcom_models", each try [copilot_dotcom_chat][models] otherwise {}, type list),
    ExpandModels = Table.ExpandListColumn(AddModels, "dotcom_models"),
    ExpandModelRecord = Table.ExpandRecordColumn(ExpandModels, "dotcom_models", {"name", "total_chats", "total_engaged_users"}, {"model", "chat_turns", "engaged_users"}),
    Selected = Table.SelectColumns(ExpandModelRecord, {"scope_slug", "team_slug", "day", "model", "chat_turns", "engaged_users"}),
    Typed = Table.TransformColumnTypes(Selected, {{"chat_turns", Int64.Type}, {"engaged_users", Int64.Type}})
in
    Typed;

shared FactSeatAssignmentsDaily =
let
    SeatsRaw = fnGitHubPagedList(ScopeType & "/" & ScopeSlug & "/copilot/billing/seats", 100),
    SeatsTable = Table.FromList(SeatsRaw, Splitter.SplitByNothing(), {"seat"}, null, ExtraValues.Error),
    ExpandSeat = Table.ExpandRecordColumn(
        SeatsTable,
        "seat",
        {"created_at", "updated_at", "pending_cancellation_date", "last_activity_at", "last_activity_editor", "assignee", "assigning_team"},
        {"created_at", "updated_at", "pending_cancellation_date", "last_activity_at", "last_activity_editor", "assignee", "assigning_team"}
    ),
    ExpandAssignee = Table.ExpandRecordColumn(ExpandSeat, "assignee", {"login", "type"}, {"assignee_login", "assignee_type"}),
    ExpandAssigningTeam = Table.ExpandRecordColumn(ExpandAssignee, "assigning_team", {"slug"}, {"assigning_team_slug"}),
    AddedScope = Table.AddColumn(ExpandAssigningTeam, "scope_slug", each ScopeSlug, type text),
    AddedDay = Table.AddColumn(AddedScope, "snapshot_day", each Date.From(DateTimeZone.UtcNow()), type date)
in
    AddedDay;

shared FactSeatSummaryDaily =
let
    Summary = fnGitHubRequest(ScopeType & "/" & ScopeSlug & "/copilot/billing"),
    AsTable = Table.FromRecords({Summary}),
    ExpandBreakdown = Table.ExpandRecordColumn(AsTable, "seat_breakdown", {"total", "added_this_cycle", "pending_cancellation", "pending_invitation", "active_this_cycle", "inactive_this_cycle"}, {"seats_total", "seats_added_this_cycle", "seats_pending_cancellation", "seats_pending_invitation", "seats_active_this_cycle", "seats_inactive_this_cycle"}),
    AddedScope = Table.AddColumn(ExpandBreakdown, "scope_slug", each ScopeSlug, type text),
    AddedDay = Table.AddColumn(AddedScope, "snapshot_day", each Date.From(DateTimeZone.UtcNow()), type date),
    Selected = Table.SelectColumns(AddedDay, {"scope_slug", "snapshot_day", "plan_type", "seats_total", "seats_added_this_cycle", "seats_pending_cancellation", "seats_pending_invitation", "seats_active_this_cycle", "seats_inactive_this_cycle"})
in
    Selected;

shared FactUserMetricsDaily =
let
    Meta = fnGitHubRequest(ScopeType & "/" & ScopeSlug & "/copilot/metrics/reports/users-28-day/latest"),
    DownloadLinks =
        if Record.HasFields(Meta, "download_links") then
            let
                Links = Meta[download_links]
            in
                if Value.Is(Links, type list) then
                    List.Transform(
                        Links,
                        each if Value.Is(_, type text) then _ else Record.FieldOrDefault(_, "download_url", null)
                    )
                else
                    {}
        else
            {},
    CleanLinks = List.RemoveNulls(DownloadLinks),
    LinkPayloadText = List.Transform(CleanLinks, each Text.FromBinary(Web.Contents(_), TextEncoding.Utf8)),
    JsonLines = List.Combine(
        List.Transform(
            LinkPayloadText,
            (t) =>
                List.RemoveNulls(
                    List.Transform(
                        Text.Split(t, "#(lf)"),
                        (line) =>
                            if Text.Trim(line) = "" then
                                null
                            else
                                try Json.Document(line) otherwise null
                    )
                )
        )
    ),
    MetricsTable = if List.Count(JsonLines) = 0 then #table({}, {}) else Table.FromRecords(JsonLines),
    AddedScope = Table.AddColumn(MetricsTable, "scope_slug", each ScopeSlug, type text),
    AddedSnapshot = Table.AddColumn(AddedScope, "snapshot_day", each Date.From(DateTimeZone.UtcNow()), type date)
in
    AddedSnapshot;
