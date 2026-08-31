# Rails-parity plan

Working backlog to bring this repo's developer productivity to Ruby on Rails
parity. Companion to [`rails-parity-assessment.md`](./rails-parity-assessment.md)
(the analysis); this file is the task list.

- **Completed** items (`[x]`) = capabilities we already have: installed plugins,
  available skills, and setup steps already done.
- **Open** items (`[ ]`) = the gaps, grouped into phases with dependencies and
  acceptance criteria.

## Why markdown and not OpenSpec

OpenSpec pays off when every change flows through a proposal + delta-spec +
per-change task list, backed by its tooling. This is a one-time roadmap, and no
OpenSpec tooling is set up in the repo. A phased checklist with explicit
acceptance criteria is more directly usable now. If OpenSpec is adopted later,
each open phase below maps cleanly onto one change proposal.

---

## Definition of "parity"

A developer can, without leaving the toolchain:

1. Define a model and evolve its schema through reversible migrations.
2. Scaffold CRUD (list / details / create / edit / delete) over it in one pass.
3. Seed a working dataset with one command on a fresh clone.
4. Authenticate and authorize users.
5. Run background jobs, send email, cache, store uploaded files, push real-time
   updates.
6. Write model, integration, and component tests with reusable test data.
7. Run the whole stack locally with one command and deploy it with one pipeline.

Items 1-4 and 6-7 are mostly reachable with what we have once EF Core is wired.
Item 5 has no skill or library behind it and is net-new work.

---

## Inventory — what we already have

### Plugins (pinned in `.claude/settings.json`)

- [x] `dotnet@dotnet-agent-skills` (0.2.3) — SDK management, C# LSP
- [x] `dotnet-aspnetcore@dotnet-agent-skills` (0.1.1) — Web API, file upload, OTel, Blazor Server→WebApp conversion
- [x] `dotnet-blazor@dotnet-agent-skills` (0.1.1) — Blazor component authoring, forms, state, auth, prerendering, JS interop
- [x] `dotnet-data@dotnet-agent-skills` (0.1.5) — EF Core CRUD scaffold + query optimization
- [x] `dotnet-test@dotnet-agent-skills` (0.2.18) — full test lifecycle + quality analysis + sub-agents
- [x] `dotnet11@dotnet-agent-skills` (0.1.1) — System.Text.Json on .NET 11
- [x] `mudblazor@mudblazor-agent-skills` (0.1.0) — all MudBlazor work (own-maintained)

### Skills by plugin

**dotnet**
- [x] `setup-local-sdk` — install / pin / replace a local .NET SDK, global.json paths

**dotnet-aspnetcore**
- [x] `dotnet-webapi` — endpoints (controllers or minimal API), OpenAPI, error middleware, `.http` files
- [x] `minimal-api-file-upload` — file upload endpoints, .NET 8+
- [x] `configuring-opentelemetry-dotnet` — tracing / metrics / logs, OTLP exporters
- [x] `convert-blazor-server-to-webapp` — pre-.NET 8 Blazor Server → Blazor Web App (not needed here; already a Web App)

**dotnet-blazor**
- [x] `create-blazor-project` — scaffold, render-mode choice
- [x] `plan-ui-change` — decompose a multi-section page into components
- [x] `author-component` — write / review a `.razor` component (no JS interop)
- [x] `collect-user-input` — forms, validation, SSR form patterns, file inputs
- [x] `coordinate-components` — cascading values, scoped state services across render modes
- [x] `fetch-and-send-data` — call APIs, loading / error states, HttpClient for Auto/WASM
- [x] `use-js-interop` — JS ↔ .NET, module lifecycle, timing rules
- [x] `support-prerendering` — double-load, flicker, null-during-prerender, state persistence
- [x] `configure-auth` — `[Authorize]`, `AuthorizeView`, roles / policies, Identity pages, AuthenticationStateProvider

**dotnet-data**
- [x] `create-datadriven-aspnetcore` — scaffold CRUD (Razor Pages / Blazor / MVC / minimal API) over a `DbContext`, uses the EF migration lifecycle
- [x] `optimizing-ef-core-queries` — reduce SQL, fewer round-trips, faster reads

**dotnet-test**
- [x] `scaffold-dotnet-test-project` — create first test project, wire `.sln` / CI discovery
- [x] `code-testing-agent` — write / add / generate tests for existing code (+ builder/fixer/generator/implementer/linter/planner/researcher/tester sub-agents)
- [x] `run-tests` — exact repo-compatible `dotnet test` command, filters, TRX, dumps
- [x] `platform-detection` — identify test platform / framework / runner (VSTest vs MTP)
- [x] `mtp-hot-reload` — edit / re-run loop for tests
- [x] `writing-mstest-tests` — correct MSTest assertions / attributes / lifecycle / config
- [x] `test-anti-patterns` — severity-ranked diagnostic audit
- [x] `test-smell-detection` — testsmells.org 19-smell academic taxonomy
- [x] `assertion-quality` — weak / shallow / tautological assertion report
- [x] `test-gap-analysis` — pseudo-mutation: what production changes would survive the suite
- [x] `coverage-analysis` — interpret Cobertura line/branch/condition, project-wide CRAP
- [x] `crap-score` — CRAP for one named method / class / file
- [x] `find-untested-sources` — static source-to-test pairing
- [x] `grade-tests` — per-test A-F PR table
- [x] `test-tagging` — trait distributions, happy vs error mix
- [x] `detect-static-dependencies` — scan for `DateTime.Now`, `File.*`, `HttpClient`, statics
- [x] `generate-testability-wrappers` — abstractions + DI for statics
- [x] `migrate-static-to-wrapper` — move call sites to a named abstraction (`TimeProvider`, `IFileSystem`, …)
- [x] `testability-obstacle` — one behavior blocked on a missing seam
- [x] sub-agents: `test-quality-auditor`, `testability-migration`

**dotnet11**
- [x] `system-text-json-net11` — STJ on .NET 11

**mudblazor**
- [x] `mudblazor` — setup, components, layout (`MudLayout`/`MudAppBar`/`MudDrawer`), `MudDataGrid`/`MudTable`, `MudForm`, `MudDialog`, theming / dark mode, render-mode & popover fixes, authoring app-owned wrapper components

### Cross-cutting workflow skills (the "rubocop / brakeman / Rails guides" analog)

- [x] `code-review` — diff / PR / branch review for correctness + cleanup
- [x] `simplify` — reuse / simplification / efficiency pass, applies fixes
- [x] `security-review` — security review of pending changes
- [x] `run` — launch and drive the app to confirm a change
- [x] `frontend-design`, `design`, `dataviz` — visual design direction, mockups, charts
- [x] `loop`, `schedule` — recurring / scheduled task automation
- [x] `update-config`, `fewer-permission-prompts`, `keybindings-help` — harness config
- [x] `claude-api`, `claude-in-chrome` — API reference, browser automation

### Setup already done (from git history + `docs/setup-log.md`)

- [x] Repo initialized; Claude Code plugin/marketplace config committed
- [x] Blazor Web App scaffolded (`dotnet new blazor -int Server`)
- [x] Retargeted to `net10.0`; .NET 10 SDK (10.0.400) installed
- [x] `global.json` pins SDK to 10.0.400, `rollForward: latestFeature`
- [x] MudBlazor 9.9.0 wired (services, imports, providers in `MainLayout`, script order); Bootstrap removed
- [x] Global Interactive Server render mode; `Error.razor` forced to static SSR via `[ExcludeFromInteractiveRouting]`
- [x] First feature page committed (Havenly landing page + gallery dialog)

---

## Open phases

Dependency order: **P0 → P1 → (P2, P3 in parallel) → P4 → P5**. P6 any time.

### P0 — Foundations & conventions

Rails gives layout and conventions for free; `CLAUDE.md` still says `TBD`.

- [ ] **P0.1** Create a solution file (`dotnetskills.slnx`) and add the web project.
  _Skill:_ — · _Accept:_ `dotnet sln list` shows the project; build from the `.slnx`.
- [ ] **P0.2** Decide project layering: stay single-project (fastest, Rails-like)
  vs split Web / Application / Domain / Infrastructure. Record the decision and
  rationale. _Skill:_ — · _Accept:_ decision written in `CLAUDE.md`.
- [ ] **P0.3** Add `Directory.Build.props` (`Nullable`, `ImplicitUsings`,
  `LangVersion`, analyzers, `TreatWarningsAsErrors`) and `.editorconfig`.
  _Skill:_ — · _Accept:_ `dotnet build` clean with analyzers enabled.
- [ ] **P0.4** Add `Directory.Packages.props` (central package management); move
  the MudBlazor version there. _Skill:_ — · _Accept:_ no versions left in `.csproj`.
- [ ] **P0.5** Fill in the `CLAUDE.md` "Conventions" section (naming, folder
  layout, nullable/analyzer policy) and the Build/run/test block with real paths.
  _Skill:_ `init` (assist) · _Accept:_ no `TBD` left in `CLAUDE.md`.
- [ ] **P0.6** Decide the fate of template pages (`Counter`, `Weather`) — delete
  or keep as reference. _Skill:_ — · _Accept:_ decision applied.

### P1 — Data layer (EF Core) — the critical blocker

Nothing in `dotnet-data` can act until a `DbContext` exists.

- [ ] **P1.1** Choose DB provider + local-dev DB story: **SQLite** (zero-config,
  closest to Rails' default) vs **PostgreSQL + Npgsql** with Docker Compose or
  .NET Aspire for local infra. Note: choosing Aspire here also satisfies parts of
  P4/P5. _Skill:_ — · _Accept:_ decision + connection strategy in `CLAUDE.md`.
- [ ] **P1.2** Add packages: `Microsoft.EntityFrameworkCore`, the provider
  package, `Microsoft.EntityFrameworkCore.Design` (`PrivateAssets=all`).
  _Skill:_ `create-datadriven-aspnetcore` · _Accept:_ `dotnet build` clean.
- [ ] **P1.3** Create `AppDbContext`, register with `AddDbContext`, add the
  connection string to `appsettings*.json`. _Skill:_ `create-datadriven-aspnetcore`
  · _Accept:_ app starts with the context resolvable from DI.
- [ ] **P1.4** Add local tool manifest `.config/dotnet-tools.json` with
  `dotnet-ef`; `dotnet tool restore`. _Skill:_ `create-datadriven-aspnetcore`
  · _Accept:_ `dotnet tool run dotnet-ef --version` works.
- [ ] **P1.5** Create + apply the `InitialCreate` migration.
  _Skill:_ `create-datadriven-aspnetcore` · _Accept:_ schema created; migration
  committed.
- [ ] **P1.6** Write a **migrations conventions doc** — reversible migrations,
  renames, data backfills, squashing, naming, and how CI applies them. This is
  the "no skill owns schema evolution" gap. _Skill:_ — · _Accept:_ `docs/` doc +
  `CLAUDE.md` pointer; one non-trivial migration (e.g. a column rename) done as a
  worked example.
- [ ] **P1.7** Seed strategy: `IHostEnvironment`-gated seeder run at startup, or a
  `dotnet run -- seed` verb. The `create-datadriven` skill forbids seeding in
  `Program.cs`, so this needs a deliberate choice. _Skill:_ — · _Accept:_ fresh
  clone → one command → working sample data.
- [ ] **P1.8** End-to-end validation: one real domain entity with full CRUD via
  `create-datadriven-aspnetcore`, UI in MudBlazor. _Skill:_
  `create-datadriven-aspnetcore` + `mudblazor` · _Accept:_ list/details/create/
  edit/delete all work against the DB.

### P2 — Testing

`dotnet-test` is strong on test *logic*; the gap is a test project on disk and a
test-*data* convention.

- [ ] **P2.1** Scaffold the test project (xUnit), wire into the solution + CI
  discovery. _Skill:_ `scaffold-dotnet-test-project` · _Accept:_ `dotnet test`
  from the solution discovers and runs it.
- [ ] **P2.2** Test-data strategy (FactoryBot analog): builder / object-mother
  pattern, `Bogus` for fake data. _Skill:_ `code-testing-agent` (assist)
  · _Accept:_ convention doc + one reusable builder.
- [ ] **P2.3** EF Core test approach: SQLite in-memory vs Testcontainers; shared
  fixture / base class. _Skill:_ `code-testing-agent` · _Accept:_ one
  `DbContext`/repository test passing.
- [ ] **P2.4** Blazor component tests with `bUnit`. _Skill:_ `author-component`
  (context) + `code-testing-agent` · _Accept:_ one render + interaction test
  passing.
- [ ] **P2.5** Coverage baseline + CI report. _Skill:_ `coverage-analysis`,
  `run-tests` · _Accept:_ Cobertura report produced in CI; baseline recorded.

### P3 — Authentication & authorization

- [ ] **P3.1** Choose the model: **ASP.NET Core Identity** (self-contained, Devise
  analog) vs external IdP. _Skill:_ `configure-auth` · _Accept:_ decision in
  `CLAUDE.md`.
- [ ] **P3.2** Add Identity + EF stores; migration for the Identity tables.
  _Skill:_ `configure-auth` + `create-datadriven-aspnetcore` · _Accept:_ user
  tables migrated.
- [ ] **P3.3** Login / logout / register / manage pages, respecting render mode
  (Identity UI as static SSR under a global-interactive app). _Skill:_
  `configure-auth` + `support-prerendering` · _Accept:_ register + sign in works.
- [ ] **P3.4** Authorization: policies / roles, `[Authorize]` on a protected page,
  `AuthorizeView` in the nav. _Skill:_ `configure-auth` · _Accept:_ anonymous hit
  on a protected route redirects to login.
- [ ] **P3.5** Seed an admin user in the P1.7 seeder. _Skill:_ — · _Accept:_ known
  dev admin credentials.

### P4 — Batteries (no skill exists — net-new, document as you go)

- [ ] **P4.1** Background jobs: pick **Hangfire** / **Quartz.NET** / **Aspire +
  hosted services**. Implement one recurring + one fire-and-forget job. _Skill:_ —
  · _Accept:_ job runs on schedule; enqueued job executes; `docs/` convention
  written.
- [ ] **P4.2** Email (ActionMailer analog): `MailKit` + Razor-templated bodies;
  dev sink (`smtp4dev` / Papercut / file drop). Wire the P3.3 confirmation email.
  _Skill:_ — · _Accept:_ confirmation email rendered and delivered to the dev
  sink.
- [ ] **P4.3** Caching + rate limiting: `HybridCache` (in-memory now, Redis-ready),
  `OutputCache` on suitable endpoints, rate-limiter middleware. _Skill:_ — ·
  _Accept:_ demonstrated cache hit path; limiter returns 429 under load.
- [ ] **P4.4** File storage (ActiveStorage analog): `IFileStore` abstraction with
  a local-disk implementation now, blob (Azure/S3) later; ingest via
  `minimal-api-file-upload`. _Skill:_ `minimal-api-file-upload` · _Accept:_ upload
  persists and is retrievable; implementation swappable by config.
- [ ] **P4.5** Real-time (ActionCable analog, _only if needed_): app-level
  SignalR hub for notifications / presence, with a typed client. _Skill:_ — ·
  _Accept:_ two clients receive a pushed event.
- [ ] **P4.6** Observability: wire OpenTelemetry (traces / metrics / logs) to
  console or an OTLP collector. _Skill:_ `configuring-opentelemetry-dotnet` ·
  _Accept:_ a request produces a trace with DB spans.

### P5 — Deployment (Kamal analog — no skill)

- [ ] **P5.1** Multi-stage `Dockerfile` (`dotnet publish`) + `.dockerignore`.
  _Skill:_ — · _Accept:_ image builds and runs.
- [ ] **P5.2** Full local stack in one command: `docker-compose` (app + db + redis
  + smtp sink) **or** an Aspire AppHost if adopted in P1.1. _Skill:_ — ·
  _Accept:_ one command serves the app with all dependencies.
- [ ] **P5.3** CI/CD pipeline (GitHub Actions): restore → build → test → publish →
  deploy; pick a target (Azure App Service / Container Apps / Fly.io / self-host).
  _Skill:_ — · _Accept:_ green pipeline deploys to a live environment.
- [ ] **P5.4** Production hardening: HTTPS, persisted Data Protection keys,
  secrets via env / key vault, `/health` endpoint. _Skill:_ — · _Accept:_
  `/health` returns 200; auth cookies survive an app restart.

### P6 — Lower stakes

- [ ] **P6.1** Localization: `IStringLocalizer`, resource files, culture
  middleware. _Skill:_ — · _Accept:_ one page renders in two cultures.
- [ ] **P6.2** `rails console` substitute: a DI-wired CLI verb host
  (`dotnet run -- <command>`) or `dotnet-script` with a DI bootstrap. _Skill:_ —
  · _Accept:_ run an ad-hoc query against real services from the terminal.
- [ ] **P6.3** `.http` request collections per API area. _Skill:_ `dotnet-webapi`
  · _Accept:_ checked-in `.http` covering each endpoint.

---

## Gap → owning mechanism (quick reference)

| Gap | Mechanism | Skill? |
|---|---|---|
| ORM + `DbContext` | EF Core | `create-datadriven-aspnetcore` (indirect) |
| CRUD scaffold | EF Core + MudBlazor | ✅ `create-datadriven-aspnetcore`, `mudblazor` |
| Schema evolution / rollback / backfills | EF Core migrations | ❌ write a convention |
| Seeds | env-gated seeder or CLI verb | ❌ decide + build |
| Test project | xUnit | ✅ `scaffold-dotnet-test-project` |
| Test data factories | builder / `Bogus` | ❌ convention |
| Auth | ASP.NET Core Identity | ✅ `configure-auth` |
| Background jobs | Hangfire / Quartz / Aspire | ❌ net-new |
| Email | MailKit + Razor | ❌ net-new |
| Caching / rate limiting | HybridCache / OutputCache | ❌ net-new |
| File storage | `IFileStore` abstraction | ⚠️ `minimal-api-file-upload` (endpoint only) |
| Real-time | SignalR hub | ❌ net-new |
| Observability | OpenTelemetry | ✅ `configuring-opentelemetry-dotnet` |
| Deploy | Docker + CI/CD | ❌ net-new |
| i18n | `IStringLocalizer` | ❌ net-new |
| `rails console` | DI-wired CLI verbs | ❌ net-new |
