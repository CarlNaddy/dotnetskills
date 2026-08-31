# Rails-parity assessment: .NET + Blazor + AI agent skills

_Assessment date: 2026-08-31. Reviews whether this repo's stack plus its Claude Code
plugins/skills can match Ruby on Rails developer productivity._

## Verdict

For the **inner loop of building a UI-over-data CRUD feature**, this setup gets close
to Rails once EF Core is actually wired — and it is **ahead of Rails on testing and
type safety**. But out of the box today it is **not** at Rails productivity, for two
reasons:

1. The data layer is still `TBD` — no ORM is installed at all, so the single biggest
   Rails superpower (ActiveRecord + migrations from minute one) is not there yet.
2. The "batteries included" tier — background jobs, mailers, caching, real-time, file
   storage, seeds, deploy — has **no skill and no library** behind it.

## Project state inspected

- `dotnetskills.csproj` — single project, no `.sln`, no Domain/Infra/Web layering.
- Blazor Web App, .NET 10, MudBlazor 9.9.0, global Interactive Server render mode.
- No EF Core package, no `DbContext`, no provider, no connection string, no
  `dotnet ef` tool, no local tool manifest.
- No test project.
- No auth / Identity.
- `CLAUDE.md` marks Data access / Tests / Conventions all `TBD`.
- Template pages (Counter, Weather) still present alongside a Havenly landing page
  and a gallery dialog.

## Skills / plugins available (7 plugins)

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

## Rails feature -> where this stack lands

| Rails capability | Status here |
|---|---|
| Opinionated layout / conventions | :warning: Template only; `Conventions - TBD`, no solution or layering |
| ActiveRecord ORM | :x: EF Core not installed |
| Migrations, rollback, `schema.rb` | :warning: EF Core migrations exist as tooling; `create-datadriven` *uses* the lifecycle, but no skill owns schema evolution / rollback / data backfills |
| `rails g scaffold` | :white_check_mark: `create-datadriven-aspnetcore` — once a `DbContext` exists |
| RESTful routing | :white_check_mark: `dotnet-webapi` for APIs; Blazor page routing stays manual `@page` |
| Auth (Devise) | :warning: `configure-auth` skill is solid, but no Identity scaffolded, no user model |
| Authorization (Pundit) | :warning: Covered conceptually by `configure-auth` (policies / roles) |
| Test framework | :white_check_mark::white_check_mark: **Exceeds Rails** — coverage, mutation-gap, CRAP, anti-pattern audits, testability refactors |
| `rails console` (REPL over app DI) | :x: No skill, no ergonomic equivalent |
| `db/seeds.rb` | :x: Skill explicitly forbids seeding in `Program.cs`, gives no seed pattern |
| Test factories (FactoryBot) / fixtures | :x: Strong on test *logic*, nothing on test *data* setup |
| ActionMailer | :x: No skill, nothing wired |
| ActiveJob + Sidekiq | :x: No skill (Hangfire / Quartz / hosted service / Aspire) |
| ActionCable | :warning: Blazor rides SignalR internally; no skill for app-level hubs |
| ActiveStorage (files + variants) | :warning: `minimal-api-file-upload` = ingest endpoint only, no storage abstraction |
| Fragment / Russian-doll caching | :x: No skill for `OutputCache` / `HybridCache` / response caching |
| i18n / localization | :x: No skill |
| Environments (dev/test/prod) | :white_check_mark: Native ASP.NET config |
| Asset pipeline | :white_check_mark: Handled by Blazor static assets + MudBlazor |
| Deploy (Kamal / Heroku one-liner) | :x: No Dockerfile, no containerize/deploy skill |
| Admin panel (ActiveAdmin) | :warning: `MudDataGrid` + `create-datadriven` gets you there by generation |

## What's missing, in priority order

### Blocking Rails-parity for the core loop

1. **Wire EF Core** — pick a provider (Postgres / SQLite), add
   `Microsoft.EntityFrameworkCore.*` + `.Design`, create a `DbContext`, add a
   connection string, add `.config/dotnet-tools.json` with `dotnet-ef`. Until this
   exists, `create-datadriven-aspnetcore` and `optimizing-ef-core-queries` have
   nothing to act on.
2. **A migrations workflow doc / skill** — the current data skill only does "add
   InitialCreate + update". Rails devs lean hard on rollback, renames, backfills,
   and squashing; that guidance does not exist here. Write a repo convention in
   `CLAUDE.md`.
3. **A seed strategy** — `IHostEnvironment`-gated seeding or a `dotnet run seed`
   command; needs deciding since the skill bans the obvious spot.
4. **Test project** — `dotnet-test:scaffold-dotnet-test-project` will do it in one
   shot, but it has not been run; plus a factory / builder convention for test data.

### Batteries with no coverage (each = add a library + write a short skill / convention)

5. **Background jobs** — Hangfire or Quartz.NET, or adopt **.NET Aspire** (which also
   covers local Postgres / Redis orchestration, closing gap #1's dev-DB story too).
6. **Email** — MailKit + Razor-templated messages.
7. **Output / Hybrid caching + rate limiting** conventions.
8. **App-level SignalR hubs** (if chat / notifications are needed beyond Blazor's
   built-in circuit).
9. **File storage abstraction** (local <-> Azure Blob / S3).
10. **Deployment** — Dockerfile + `dotnet publish` container target, plus a deploy
    target choice.

### Lower stakes

- i18n / localization.
- A `rails console` substitute (`dotnet run -- <verb>` one-off commands, or a C#
  script host).
- Auth pages actually scaffolded via `configure-auth`.

## Bottom line

The **UI + testing story is excellent** — better than what a Rails dev gets from AI
tooling — and the API / CRUD story is competent and one EF Core setup away from
usable. The gap to "as productive as Rails" is:

1. **Finish the data layer** (EF Core + provider + `DbContext` + migrations tooling).
2. Then decide whether to pull in **.NET Aspire** (covers local infra and gives jobs
   / cache / service wiring a home) versus bolting on Hangfire + MailKit
   individually.

Neither the framework nor the skills will hand you jobs / mail / cache / deploy the
way Rails hands you ActiveJob / ActionMailer / Kamal — those stay decisions to make
and document in `CLAUDE.md`.
