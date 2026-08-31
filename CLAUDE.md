# dotnetskills

ASP.NET Core + **Blazor Web App** with **MudBlazor** for all UI.

> Status: Blazor Web App scaffolded and running on MudBlazor. Being brought to
> Ruby on Rails-level productivity through a phased plan — see
> [`docs/rails-parity-plan.md`](docs/rails-parity-plan.md).

## Stack

| Concern | Choice |
|---|---|
| Framework | .NET 10 (adjust `global.json` if pinning; use `dotnet:setup-local-sdk` for a preview SDK) |
| Web | ASP.NET Core, Blazor Web App template |
| Render mode | Interactive Server, global (`@rendermode="InteractiveServer"` on `Routes` + `HeadOutlet` in `App.razor`) |
| UI library | MudBlazor (replaces the template's default Bootstrap) |
| Data access | EF Core 10 + **PostgreSQL** (Npgsql), all environments; not yet wired — parity plan P1.2+ |
| Tests | xUnit — test project added in the parity plan (P2.1) |

## Build / run / test

One project: `dotnetskills.csproj` (the Blazor Web App). No solution file — work
against the `.csproj` directly. A `.slnx` gets added when the test project lands
(rails-parity plan P2.1).

```bash
docker compose up -d db     # PostgreSQL for local dev
dotnet tool restore         # dotnet-ef (first run only)
dotnet run -- seed          # apply migrations + seed sample data (idempotent)
dotnet watch run            # dev loop
# dotnet test               # once the test project exists (plan P2.1)
```

## Data access

**EF Core 10 + PostgreSQL** (`Npgsql.EntityFrameworkCore.PostgreSQL`), the same
provider in every environment — no SQLite-in-dev split, so migrations and SQL
never diverge from production. Decided in parity plan P1.1; wiring starts at P1.2.

- **Local dev:** PostgreSQL runs in Docker via `compose.yaml` (the Microsoft
  "ASP.NET Core with Docker Compose" pattern); the file is added in P1.2. Bring
  the DB up with `docker compose up -d db` before `dotnet watch run`.
- **Connection string:** configuration key `ConnectionStrings:Default`. The dev
  value lives in user-secrets (`dotnet user-secrets set ...`), never in
  `appsettings*.json`. Prod supplies it from the environment
  (`ConnectionStrings__Default`).
- **DbContext:** `AppDbContext` under `Data/`, registered with
  `AddDbContext<AppDbContext>(o => o.UseNpgsql(...))` (P1.3).
- **Migrations:** `dotnet ef` via a local tool manifest (`dotnet tool restore`
  first). Workflow, naming, rename/backfill gotchas, rollback, squashing, and
  the CI/deploy story are in [`docs/ef-migrations.md`](docs/ef-migrations.md).
- **Seeding:** `dotnet run -- seed` — applies pending migrations, then inserts
  sample data if the DB is empty (idempotent). Fresh clone → one command.
- Entities are the model — query `DbContext` directly, no repository layer.

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

### Build settings & analyzers

- **`Directory.Build.props`** (repo-wide): `Nullable` + `ImplicitUsings` enable,
  `LangVersion` latest, `AnalysisMode` Recommended, `TreatWarningsAsErrors`
  true. Compiler and .NET analyzer (CAxxxx) warnings fail the build. `.csproj`
  files keep only project-specific settings (`TargetFramework`, package refs).
- **`.editorconfig`**: CRLF, 4-space C# / 2-space markup, file-scoped
  namespaces, `_camelCase` private fields, full naming rules. Code-style
  (IDExxxx) rules run in the IDE and `dotnet format`, not the build —
  `EnforceCodeStyleInBuild` stays `false`; flip it to `true` once
  `dotnet format --verify-no-changes` runs clean (not a blocker).
- Format check: `dotnet format --verify-no-changes`.
- Central package management (`Directory.Packages.props`) is deferred until a
  second project exists (parity plan P2.1); until then MudBlazor's version is
  pinned in the `.csproj`.

### Naming & style

- File-scoped namespaces; namespace mirrors the folder
  (`dotnetskills.Features.Listings`).
- One public type per file; file name matches the type.
- `_camelCase` private fields; `PascalCase` types / members / constants;
  `camelCase` locals & parameters; `I`-prefixed interfaces. Async methods end
  with `Async` (except Blazor lifecycle overrides and UI event handlers).
- Nullable reference types are on — model nullability honestly; no
  `#nullable disable`, no reflexive `!`.

### Folder conventions

- `Components/Pages/` — routable components (`@page`). `Components/Layout/` —
  layout, `NavMenu`. `Components/Shared/` — reusable non-routable components
  (create when the first one appears).
- `Data/` — `AppDbContext`, entities (one per file), `Data/Migrations/`
  (EF-generated), `Data/Seed/`.
- `Features/<Feature>/` — feature services, view models, validators; may hold
  components specific to that feature.
- `Endpoints/` — minimal-API `Map*` extension methods grouped by resource,
  called from `Program.cs`. No `Controllers/` unless a real MVC need appears.
- Repo root holds `Program.cs` only.

### Services, DI, data access

- Register services in `Program.cs`, or a small `Add<Feature>()` extension per
  feature folder. Anything that touches `DbContext` is `Scoped`.
- EF Core entities are the model — query `DbContext` with LINQ from feature
  services or components; no repository layer (Guiding principle 4 in the parity
  plan). Migration workflow: [`docs/ef-migrations.md`](docs/ef-migrations.md).

### Blazor

- Global Interactive Server render mode (see the Stack table). Move `@code` into
  a code-behind `.razor.cs` once it passes ~30 lines; component-local styles go
  in a collocated `.razor.css`. All UI is MudBlazor — see the rules above.

## Reuse — starting a new project

This repo doubles as a starting point for new .NET monoliths. Route: GitHub
**"Use this template"** (a maintainer enables it under repo Settings), then
`scripts/new-project.sh <NewName>` for the mechanical rename, then the manual
follow-up. Full checklist: [`docs/new-project.md`](docs/new-project.md). A real
`dotnet new` template — the `rails new` equivalent — is parity plan **P7.2**.

`docs/rails-parity-*.md`, `docs/ef-migrations.md`, `docs/setup-log.md`, and
`docs/new-project.md` are template-journey artifacts; `new-project.sh` deletes
them from a spun-off project.
