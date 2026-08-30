# dotnetskills

ASP.NET Core + **Blazor Web App** with **MudBlazor** for all UI.

> Status: repository initialized; application not yet scaffolded. Sections marked
> _TBD_ get filled in once `dotnet new blazor` has run and decisions are made.

## Stack

| Concern | Choice |
|---|---|
| Framework | .NET 10 (adjust `global.json` if pinning; use `dotnet:setup-local-sdk` for a preview SDK) |
| Web | ASP.NET Core, Blazor Web App template |
| Render mode | _TBD_ — use Interactive Server or Auto; Static SSR alone can't drive most MudBlazor components |
| UI library | MudBlazor (replaces the template's default Bootstrap) |
| Data access | _TBD_ (EF Core expected) |
| Tests | _TBD_ (xUnit expected) |

## Build / run / test

Solution not created yet. Once it is:

```bash
dotnet restore
dotnet build
dotnet watch run --project <WebProject>   # dev loop
dotnet test
```

Keep this block updated with the real project paths after scaffolding.

## Claude Code plugins & skills

AI tooling for this repo is pinned in `.claude/settings.json` (committed). It
declares two marketplaces and enables their plugins:

| Marketplace | Source | Plugins |
|---|---|---|
| `dotnet-agent-skills` | GitHub `dotnet/skills` | `dotnet`, `dotnet-aspnetcore`, `dotnet-blazor`, `dotnet-data`, `dotnet-test`, `dotnet11` |
| `mudblazor-agent-skills` | GitHub `CarlNaddy/claude-plugins-dotnet` | `mudblazor` |

**Onboarding:** open the repo in Claude Code and accept the prompts to trust the
`dotnet-agent-skills` and `mudblazor-agent-skills` marketplaces. The plugins
listed under `enabledPlugins` install automatically. No plugin content is
committed — it is cached under `~/.claude/plugins/` and re-fetched from GitHub.
Keep `.claude/settings.json` to project config only; personal prefs (`theme`,
etc.) belong in your user `~/.claude/settings.json`.

The `dotnet` plugin provides the C# LSP. It needs the **.NET 10 SDK** on PATH
(`dnx roslyn-language-server`); with only .NET 8 installed it won't start — add
one via `dotnet:setup-local-sdk`.

### Which skill for which task

| Task | Skill |
|---|---|
| Install/pin a specific or preview .NET SDK | `dotnet:setup-local-sdk` |
| Create the Blazor project, choose render mode | `dotnet-blazor:create-blazor-project` |
| Plan a multi-section page / component breakdown | `dotnet-blazor:plan-ui-change` |
| Write or review a `.razor` component | `dotnet-blazor:author-component` |
| Forms, validation, user input | `dotnet-blazor:collect-user-input` |
| Share state across components / render modes | `dotnet-blazor:coordinate-components` |
| Call APIs, loading/error states | `dotnet-blazor:fetch-and-send-data` |
| JS interop (incl. MudBlazor's JS timing issues) | `dotnet-blazor:use-js-interop` |
| Prerendering bugs (flicker, double load, null) | `dotnet-blazor:support-prerendering` |
| Auth / `[Authorize]` / AuthenticationStateProvider | `dotnet-blazor:configure-auth` |
| REST API endpoints, OpenAPI, error middleware | `dotnet-aspnetcore:dotnet-webapi` |
| File upload endpoints (minimal API) | `dotnet-aspnetcore:minimal-api-file-upload` |
| OpenTelemetry tracing / metrics / logs | `dotnet-aspnetcore:configuring-opentelemetry-dotnet` |
| Scaffold CRUD pages/endpoints over EF Core | `dotnet-data:create-datadriven-aspnetcore` |
| Slow EF Core query / too many round-trips | `dotnet-data:optimizing-ef-core-queries` |
| `System.Text.Json` on .NET 11 | `dotnet11:system-text-json-net11` |
| Create the first test project / wire CI discovery | `dotnet-test:scaffold-dotnet-test-project` |
| Write unit tests for existing code | `dotnet-test:code-testing-agent` |
| Run tests / get the right `dotnet test` command | `dotnet-test:run-tests` |
| Audit test quality / coverage / gaps | `dotnet-test:test-anti-patterns`, `dotnet-test:coverage-analysis`, `dotnet-test:test-gap-analysis` |
| Any MudBlazor work — setup, components, theming, app-owned components | `mudblazor:mudblazor` |

No upstream skill covers MudBlazor, so we maintain our own: the **`mudblazor`
plugin** (`mudblazor-agent-skills` marketplace →
`github.com/CarlNaddy/claude-plugins-dotnet`). It provides the `mudblazor:mudblazor`
skill — `SKILL.md` plus `references/patterns.md` (consumer code patterns) and
`references/authoring-components.md` (conventions for components this app builds
on MudBlazor). Read it before any MudBlazor work. The `dotnet-blazor:*` skills
still apply to the component architecture around MudBlazor. To change the
guidance, edit the plugin repo and bump its `version`, not this file.

## MudBlazor rules (always apply)

- **All UI is MudBlazor.** No Bootstrap, Tailwind, or hand-rolled grid/utility
  CSS. Component-local tweaks go in a collocated `.razor.css`.
- **Pin the version exactly** in the `.csproj`. The API differs a lot across
  v6/v7/v8 and model knowledge is often stale — check the installed version and
  confirm signatures against `https://mudblazor.com/api/<component>` before
  writing component code.
- MudBlazor needs an **interactive render mode**; `MainLayout` must host
  `<MudThemeProvider>`, `<MudPopoverProvider>`, `<MudDialogProvider>`,
  `<MudSnackbarProvider>`, and `MudBlazor.min.js` must load **after**
  `blazor.web.js`.
- Model-bound forms: `EditForm` + `DataAnnotationsValidator` + Mud inputs.
  Use `MudForm` only for dynamic/standalone validation.
- Modals via `IDialogService.ShowAsync<T>()`; toasts via `ISnackbar.Add()`.
  Don't build custom overlay/notification infrastructure.
- Tables: prefer `MudDataGrid<T>`; push paging/sorting/filtering into the query
  for server-side data.

First-time setup and every code pattern (wiring, `MainLayout`, forms, dialogs,
data grid, theme, dark mode, pitfalls), plus the rules for authoring our own
MudBlazor-based components, are in the `mudblazor:mudblazor` skill.
Scaffolding alternative: `dotnet new install MudBlazor.Templates`.

## Conventions

- _TBD_ — add naming, folder layout, and nullable/analyzer settings once the
  solution exists.
