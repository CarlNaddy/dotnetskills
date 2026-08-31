# dotnetskills

ASP.NET Core + **Blazor Web App** with **MudBlazor** for all UI.

> Status: repository initialized; application not yet scaffolded. Sections marked
> _TBD_ get filled in once `dotnet new blazor` has run and decisions are made.

## Stack

| Concern | Choice |
|---|---|
| Framework | .NET 10 (adjust `global.json` if pinning; use `dotnet:setup-local-sdk` for a preview SDK) |
| Web | ASP.NET Core, Blazor Web App template |
| Render mode | Interactive Server, global (`@rendermode="InteractiveServer"` on `Routes` + `HeadOutlet` in `App.razor`) |
| UI library | MudBlazor (replaces the template's default Bootstrap) |
| Data access | _TBD_ (EF Core expected) |
| Tests | _TBD_ (xUnit expected) |

## Build / run / test

Solution file: `dotnetskills.slnx` (XML `.slnx` format). One project so far,
`dotnetskills.csproj` (the Blazor Web App).

```bash
dotnet restore dotnetskills.slnx
dotnet build dotnetskills.slnx
dotnet watch run --project dotnetskills.csproj   # dev loop
dotnet test dotnetskills.slnx                    # once a test project exists (P2.1)
```

Keep this block updated as projects are added to the solution.

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

### Project layout (decided in P0.2)

**Single project.** `dotnetskills.csproj` is the whole app; organize by concern
in folders, not by extracting class-library projects.

```
dotnetskills.csproj
  Components/    Blazor UI (Layout/, Pages/, shared components)
  Data/          AppDbContext, entities, EF Core migrations, seeders
  Features/      application logic — one folder per feature (services, handlers)
  Endpoints/     minimal API endpoint groups
  wwwroot/       static assets
```

Rationale: the parity goal is Rails-like throughput, and Rails is one deployable
with convention-based folders. A single project keeps the inner loop fast (no
cross-project references, one build, one `dotnet watch`) and matches how the
`dotnet-data` / `dotnet-blazor` skills expect to scaffold. Compile-time layer
enforcement (a `.Domain` with no dependencies, etc.) is not worth the ceremony
at this size. Extract a project later only when a real reuse or deployment
boundary appears — the folders above map cleanly onto `.Web` / `.Application` /
`.Domain` / `.Infrastructure` if that day comes.

Tests live in a separate project under `tests/` (added in P2.1), not in the web
project.

### Naming, nullable, analyzers (P0.3)

- **`Directory.Build.props`** (solution-wide): `Nullable` + `ImplicitUsings`
  enable, `LangVersion` latest, `AnalysisMode` Recommended,
  `TreatWarningsAsErrors` true. Compiler and .NET analyzer (CAxxxx) warnings
  fail the build. Project `.csproj` files keep only project-specific settings
  (`TargetFramework`, package references).
- **`.editorconfig`**: CRLF, 4-space C# / 2-space markup, file-scoped
  namespaces, `_camelCase` private fields, full naming rules. Code-style
  (IDExxxx) rules run in the IDE and `dotnet format`, not the build yet —
  `EnforceCodeStyleInBuild` stays `false` until the tree is clean (P0.5).
- Format check: `dotnet format dotnetskills.slnx --verify-no-changes`.
- _P0.4_ — central package management (`Directory.Packages.props`).
- _P0.5_ — remaining naming/folder conventions; decide when to flip
  `EnforceCodeStyleInBuild`.
