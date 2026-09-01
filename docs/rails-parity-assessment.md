# Rails-parity assessment: .NET + Blazor + AI agent skills

_Assessment date: 2026-09-01 (supersedes the 2026-08-31 baseline). Reviews whether
this repo's stack plus its Claude Code plugins/skills can match Ruby on Rails
developer productivity._

_Companion to [`rails-parity-plan.md`](./rails-parity-plan.md) — that file is the
sequenced task list; this file is the analysis._

## Verdict

**The core inner loop is at Rails parity.** A developer can define a model, evolve
its schema through reversible migrations, scaffold a list/details/create/edit/delete
UI over it, and seed a working dataset — all without leaving the toolchain, in a
few agent prompts. The single biggest gap in the 2026-08-31 baseline (no ORM
installed at all) is closed: EF Core 10 + PostgreSQL, `dotnet ef`, a migrations
convention doc, and a `dotnet run -- seed` verb are wired and verified end-to-end
against a real entity.

**Full-app parity is roughly half done.** What remains is the larger half by
volume and the part where Rails' "it's already there" advantage is structural:

1. **Auth is functional but not finished** (P3) — Identity, a user model,
   working register/login/logout/manage pages, and role/policy authorization on
   the `Listing` feature all exist and are verified end-to-end against Postgres
   (P3.1–P3.3, P3.5). External OAuth2 (P3.4) and the `Admin`-role seed (P3.6)
   are still open.
2. **The batteries tier has no library and no skill** (P4) — background jobs,
   mailers, caching/rate-limiting, file storage, real-time. Each is a
   decide-a-library + wire-a-seam + write-a-convention exercise. Rails hands these
   over; here they stay decisions to make and document.
3. **No deployment story** (P5) — local DB comes up with one command, but there is
   no app container, no full-stack `compose.yaml`, and no CI/CD pipeline.

On **testing** and **type safety** the setup is **ahead of Rails** and was already
ahead at baseline.

## Progress since the 2026-08-31 baseline

| Phase | Then | Now |
|---|---|---|
| **P0** Foundations & conventions | all open | ✅ **complete** — `Directory.Build.props` (nullable, analyzers, warnings-as-errors), `.editorconfig`, central package management, `CLAUDE.md` conventions filled in, template demo pages removed, localization foundation (`en`/`de`) wired |
| **P1** Data layer (EF Core) | nothing installed | ✅ **complete** — Npgsql EF Core 10, `AppDbContext` via `AddDbContextFactory`, `dotnet-ef` local tool, `InitialCreate` + real-entity migrations applied, [`docs/ef-migrations.md`](./ef-migrations.md) conventions with a worked column-rename, `dotnet run -- seed` (idempotent, migrates first), full `Listing` CRUD in MudBlazor verified against Postgres |
| **P2** Testing | no project | 🟡 **P2.1 done** — `tests/dotnetskills.Tests/` (xUnit v3 on MTP, `OutputType=Exe`, no `Microsoft.NET.Test.Sdk`), discovered by `dotnet test`. P2.2–P2.5 open |
| **P3** Auth | open | 🟡 **P3.1–P3.3 + P3.5 done** — model recorded; Identity + EF stores wired, `AddIdentity` migration applied; Register/Login/Logout/Manage pages built and **verified end-to-end against Postgres**. Authorization applied to the `Listing` feature: public read, `ListingsWriter` policy gates create/edit pages, `ListingsAdmin` (role) gates delete, `AuthorizeView` in nav + list — anon hits on write routes 302 to login, verified. Surfaced a real MudBlazor constraint: its inputs can't post through static-SSR forms — fixed with native `InputText`/`InputCheckbox`, recorded as the one exception to "all UI is MudBlazor". OAuth2 (P3.4) and the `Admin`-role seed (P3.6) open |
| **P4** Batteries | open | ❌ open |
| **P5** Deployment | open | 🟡 local Postgres via `compose.yaml`; app image / full stack / CI-CD open |
| **P7** Packaging & reuse | open | ✅ **done at P7.1** — GitHub template repo + `scripts/new-project.sh` (skeleton by default, `--with-sample` keeps the `Listing` feature) + `scripts/update-from-template.sh` (forward-sync for spun-off projects), all verified on fresh clones. **P7.2 (`dotnet new` template) deferred to (vNext)** — the scripts already produce a building project; the gap is ergonomics + distribution, not capability, and a `dotnet new` project loses the forward-sync path |

## Project state inspected (2026-09-01)

- `dotnetskills.csproj` — single Web SDK project at the repo root; `tests/**`
  excluded from its globs. `dotnetskills.slnx` holds web + test projects.
- Blazor Web App, .NET 10 (SDK 10.0.400 pinned), MudBlazor 9.9.0, global
  Interactive Server render mode; `Error.razor` forced to static SSR.
- **EF Core 10 + PostgreSQL** — `Npgsql.EntityFrameworkCore.PostgreSQL` 10.0.3,
  `Microsoft.EntityFrameworkCore.Design` 10.0.11 (build-only), Relational
  transitively pinned to 10.0.11. `AppDbContext` registered with
  `AddDbContextFactory` (MS "Blazor with EF Core"). Connection string
  `ConnectionStrings:Default` — user-secrets in dev, env var in prod, startup
  guard if unset.
- **Migrations** — `dotnet-ef` 10.0.11 via `.config/dotnet-tools.json`; three
  migrations in `Data/Migrations/` (`InitialCreate`, `AddListing`,
  `RenameAreaColumn`) applied to the Docker Postgres.
- **Seed** — `dotnet run -- seed` dispatched before the web host
  (`Data/Seed/SeedCommand.cs` → `MigrateAsync()` then `DbSeeder`, 5 idempotent
  sample listings).
- **Sample feature** — `Data/Listing.cs` (+ `ListingStatus` enum stored as
  string), full CRUD in `Components/Pages/Listings/`. Present in this repo as the
  P1 validation vehicle / test fixture / `--with-sample` payload; stripped by
  default in spun-off projects.
- **Tests** — `tests/dotnetskills.Tests/` xUnit v3 on MTP; smoke tests on
  `Listing` + its data annotations. `dotnet test` green.
- **Localization** — `AddLocalization` + `UseRequestLocalization` (`en` default,
  `de`), `IStringLocalizer<SharedResource>`, `CultureSelector` in the app bar →
  `GET /culture/set` cookie + `LocalRedirect`. Nav + `Home` localized.
- **Auth** — ASP.NET Core Identity, `ApplicationUser`, Identity tables in
  `AppDbContext`; Register/Login/Logout/Manage pages under `Components/Account/`;
  `ListingsWriter` / `ListingsAdmin` policies gating the `Listing` write pages,
  buttons, and delete action. Verified end-to-end against Postgres (P3.1–P3.3,
  P3.5). No external OAuth2 (P3.4), no `Admin`-role seed (P3.6).
- No background jobs, mail, cache abstraction, file storage, or app-level
  SignalR. No app Dockerfile / container publish, no CI/CD.
- `CLAUDE.md` — conventions, data-access, MudBlazor rules, localization, and
  reuse sections all filled in; no `TBD` left.

## Skills / plugins available (7 plugins)

All enabled from one vendored marketplace (`dotnet-agent-skills` →
`CarlNaddy/claude-plugins-dotnet`, a frozen copy of `dotnet/skills` + the
app-maintained `mudblazor` plugin).

| Area | Skills |
|---|---|
| Project scaffold + SDK | `create-blazor-project`, `setup-local-sdk` |
| Blazor UI | `plan-ui-change`, `author-component`, `collect-user-input`, `coordinate-components`, `fetch-and-send-data`, `use-js-interop`, `support-prerendering` |
| Auth | `configure-auth` |
| ASP.NET Core API | `dotnet-webapi`, `minimal-api-file-upload` |
| Data (EF Core) | `create-datadriven-aspnetcore` (CRUD scaffold + migration lifecycle), `optimizing-ef-core-queries` |
| Observability | `configuring-opentelemetry-dotnet` |
| Upgrade/migration | `convert-blazor-server-to-webapp` |
| .NET 11 | `system-text-json-net11` |
| Testing | Large `dotnet-test` suite: scaffold, generate (`code-testing-agent`), run, hot-reload, platform-detection, coverage-analysis, crap-score, test-gap-analysis, assertion-quality, test-anti-patterns, test-smell-detection, find-untested-sources, grade-tests, test-tagging, testability-obstacle / migrate-static-to-wrapper / generate-testability-wrappers, writing-mstest-tests — plus dedicated sub-agents |
| MudBlazor | `mudblazor` |
| Design | `frontend-design`, `design`, `dataviz`, `artifact-*` |
| Cross-cutting workflow | `code-review`, `simplify`, `security-review`, `run`, `loop`, `schedule` |

No skill covers the P4 batteries tier, deployment, a `rails console` substitute,
or schema evolution beyond "add + update" (the repo's own
[`docs/ef-migrations.md`](./ef-migrations.md) fills the last gap by convention).

## Rails feature → where this stack lands

| Rails capability | Status here |
|---|---|
| `rails new` (project baseline) | :white_check_mark: GitHub template repo + `scripts/new-project.sh` + `scripts/update-from-template.sh`, verified (P7.1). Two steps + Git Bash instead of one command; a `dotnet new` template (P7.2) is deferred to **(vNext)**, triggered by org-wide sharing |
| Opinionated layout / conventions | :white_check_mark: single project + concern folders, documented in `CLAUDE.md`; analyzers + `.editorconfig` enforced |
| ActiveRecord ORM | :white_check_mark: EF Core 10 + Npgsql, `AppDbContext`, entities-are-the-model (no repository layer) |
| Migrations, rollback, `schema.rb` | :white_check_mark: `dotnet ef` + `Data/Migrations/` + `AppDbContextModelSnapshot`; rollback / rename / backfill / squash covered in `docs/ef-migrations.md` with a worked example |
| `rails g scaffold` | :white_check_mark: `create-datadriven-aspnetcore` + `mudblazor` — agent-driven, not a one-liner CLI, but one prompt; `Listing` is the worked pattern |
| RESTful routing | :white_check_mark: `dotnet-webapi` for APIs; Blazor page routing stays manual `@page` |
| `db/seeds.rb` | :white_check_mark: `dotnet run -- seed` — explicit verb, migrates first, idempotent |
| Environments (dev/test/prod) | :white_check_mark: native ASP.NET config |
| Asset pipeline | :white_check_mark: Blazor static assets + MudBlazor |
| i18n / localization | :white_check_mark: `IStringLocalizer` wired (`en`/`de`), cookie-persisted culture selector (P0.7) |
| Test framework | :white_check_mark::white_check_mark: **exceeds Rails** — coverage, mutation-gap, CRAP, anti-pattern / smell audits, testability refactors, per-test grading |
| Auth (Devise) | :white_check_mark: Identity wired, EF stores, Register/Login/Logout/Manage pages verified end-to-end (P3.1–P3.3). OAuth2 (P3.4), admin seed (P3.6) still open |
| Authorization (Pundit) | :white_check_mark: `ListingsWriter` / `ListingsAdmin` policies on the `Listing` feature — `[Authorize(Policy)]` on pages, `AuthorizeView` on buttons + nav, code-level role re-check on delete (P3.5) |
| Test factories (FactoryBot) / fixtures | :x: strong on test *logic*, nothing on test *data* — no builders, no `Bogus` (P2.2) |
| EF Core test approach | :x: no shared `DbContext` fixture, no Testcontainers / in-memory decision (P2.3) |
| Component tests | :x: no `bUnit` (P2.4) |
| `rails console` (REPL over app DI) | :x: no skill, no ergonomic equivalent (P6.2) |
| ActionMailer | :x: no skill, nothing wired (P4.2) |
| ActiveJob + Sidekiq | :x: no skill; no MS first-party — Hangfire (recommended) / Quartz.NET (P4.1) |
| ActionCable | :warning: Blazor rides SignalR internally; no skill / pattern for app-level hubs (P4.5) |
| ActiveStorage (files + variants) | :warning: `minimal-api-file-upload` = ingest endpoint only, no storage abstraction (P4.4) |
| Fragment / Russian-doll caching | :x: no wiring for `OutputCache` / `HybridCache` / rate limiting (P4.3) |
| Deploy (Kamal / Heroku one-liner) | :x: no app container / publish target, no full-stack `compose.yaml`, no CI/CD (P5) |
| Admin panel (ActiveAdmin) | :warning: `MudDataGrid` + `create-datadriven` gets you there by generation |
| Observability | :warning: built-in `ILogger` now; health checks + OpenTelemetry deferred (P4.6 / vNext) |

## Scorecard against the plan's 8-point "parity" definition

| # | Capability | Status |
|---|---|---|
| 1 | Model + reversible migrations | ✅ at parity |
| 2 | One-pass CRUD scaffold | ✅ close (agent-driven, proven by `Listing`) |
| 3 | One-command seed on fresh clone | ✅ at parity |
| 4 | Authenticate & authorize users | 🟡 register/login/logout/manage + role/policy authorization on the `Listing` feature work end-to-end (P3.1–P3.3, P3.5); OAuth2 (P3.4) + admin seed (P3.6) open |
| 5 | Jobs / email / cache / file storage / real-time | ❌ not started (P4) |
| 6 | Model + integration + component tests, reusable test data | 🟡 test project runs; builders / EF fixture / bUnit / coverage baseline open |
| 7 | One-command local stack + one deploy pipeline | 🟡 local DB only; app stack + CI/CD open (P5) |
| 8 | Start a new project from the baseline in one step | ✅ template-repo + script route verified (P7.1); one-command `dotnet new` (P7.2) deferred to (vNext) |

## What's missing, in priority order

### Finish testing (P2.2–P2.5) — small, unblocks confident iteration

- Test-data builders / object-mother + `Bogus` (FactoryBot analog).
- EF Core test approach: shared fixture / base class; SQLite-in-memory vs
  Testcontainers decision.
- `bUnit` for component render + interaction tests.
- Coverage baseline + Cobertura report in CI.

### Finish auth (P3.4, P3.6) — the core is done

Identity + EF stores + migration + register/login/logout/manage pages +
role/policy authorization on the `Listing` feature are done and verified
(P3.1–P3.3, P3.5). Remaining: external OAuth2 (Google / Microsoft first-party,
GitHub via `AspNet.Security.OAuth.GitHub`); seed the `Admin` role + a dev admin
user in `DbSeeder`. The `configure-auth` skill covers the design; this is a
focused build-out.

### Batteries (P4) — the structural gap, net-new, document as you go

Each item = choose a library + wire a thin app-owned seam + write a `docs/`
convention. No skill assists.

5. Background jobs — **Hangfire** (persistent queue + dashboard, Sidekiq-closest)
   or Quartz.NET; store jobs in the app Postgres DB.
6. Email — **MailKit** + Razor-templated bodies; dev sink (smtp4dev / Papercut).
7. Caching + rate limiting — first-party `HybridCache` / `OutputCache` +
   `AddRateLimiter`. Redis backplane is vNext (triggered by >1 instance).
8. File storage — `IFileStore` abstraction, local disk now, blob later.
9. Real-time — app-level SignalR hub, only if a feature needs it.

### Deployment (P5) — standard MS guidance, no skill

Container image via `dotnet publish -t:PublishContainer`; full-stack
`compose.yaml` (app + Postgres + mail sink); GitHub Actions restore → build →
test → publish → deploy to one target; production hardening (persisted Data
Protection keys, `/health` + `/alive`).

### Lower stakes (P6)

- `rails console` substitute — a DI-wired `dotnet run -- <verb>` host.
- `.http` request collections per API area.

### Deferred (vNext)

- **P7.2** — real `dotnet new` custom template with `--sample` / `--db`
  parameters. The P7.1 scripts already produce a building project from the
  baseline and add a forward-sync path (`update-from-template.sh`) that a
  `dotnet new` template cannot; the remaining gap is one-command ergonomics and
  `dotnet new list` / NuGet distribution. Pick up when a second team or org-wide
  sharing appears. Known limitation until then: the scripts require bash (Git
  Bash on Windows).

## Bottom line

For **building a UI-over-data feature**, this stack is now genuinely at Rails
productivity and ahead of it on testing and type safety. **Starting a new project
from the baseline is settled** — the P7.1 script route is the accepted answer;
a one-command `dotnet new` template stays deferred until org-wide sharing makes
it worth the maintenance. The distance to **"clone it and ship a real product"**
is the rest of P3 plus P4–P5: auth's OAuth2 + admin-seed tail (P3.4, P3.6),
the batteries tier (net-new, five libraries behind seams), and a deploy pipeline
(standard, unskilled). Roughly
**half the plan by volume remains**, and the batteries half is the part where the
goal is parity of *documentation and convention* with Rails — not the effortless
"it's already wired" that Rails and its AI tooling will always have there.

## Scoping decisions (carried forward from the 2026-08-31 review)

- **Monolith-first, Microsoft-standard-first.** Official .NET / ASP.NET Core
  patterns, templates, and the installed `dotnet*` skills take priority over
  third-party or bespoke solutions — most robust path, and the AI agents are
  trained on them. Third-party only where there is no first-party option (jobs →
  Hangfire, email → MailKit), kept behind a thin seam. Feature modules / light
  DDD inside the one project are fine.
- **PostgreSQL + Npgsql in every environment** — no SQLite-in-dev split, so
  migration SQL never diverges from prod.
- **Drop .NET Aspire** everywhere it appeared (data, jobs, deploy) — orchestration
  tooling aimed at multi-service apps, overkill for a monolith.
- **Redis** (distributed cache / SignalR backplane / DP key store) → **vNext**,
  triggered by running more than one instance.
- **Full OpenTelemetry** → **vNext**; `ILogger` + health checks cover the
  near-term need.
- **External OAuth2 login** (Google / GitHub / Microsoft) is part of the auth
  phase.
- **Localization promoted** to a foundational task (P0.7) — done.
- **Deployment follows official MS container guidance** (SDK container publish or
  the standard `Dockerfile`, plus `compose.yaml`) — no custom tooling.
- **Reuse model:** the app is a worked reference, not the deliverable. The
  reusable parts are `.claude/settings.json` (plugins/skills), the `CLAUDE.md`
  conventions, and `docs/`. New projects go through the GitHub template-repo +
  `scripts/` route (P7.1, done) — **this is the accepted answer for P7**. A
  `dotnet new` template (P7.2) is deferred to (vNext); it would not replace
  `update-from-template.sh`, so the scripts stay either way.
