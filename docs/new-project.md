# Starting a new project from this template

This repo is a **reference app + a curated Claude Code setup**. It works as a
GitHub *template repository* — you get a full, running .NET 10 / Blazor /
MudBlazor / EF Core + PostgreSQL monolith, then rename it and (optionally) strip
the sample feature.

> A `dotnet new` template is the eventual goal (parity plan **P7.2**). Until then
> this is the template-repo route, verified end-to-end.

## Prerequisites

- .NET 10 SDK (`dotnet --version` → 10.0.x) — <https://dotnet.microsoft.com/download/dotnet/10.0>
- Docker (for local PostgreSQL) — <https://docs.docker.com/get-docker/>
- Git, plus **bash** to run the scripts — on Windows use **Git Bash**
- Node 18+ *(optional)* — only for OpenSpec (step 7) — <https://nodejs.org>

`scripts/new-project.sh` runs `scripts/preflight.sh` first and stops if a
required tool is missing; run `bash scripts/preflight.sh` yourself any time.

**On Windows, without Git Bash yet:** every script has a `.ps1` counterpart —
`scripts/preflight.ps1`, `scripts/new-project.ps1` — that runs from
PowerShell/CMD with no bash needed to get that far. Each one delegates to Git
Bash if it finds one (checked against Git's own install, not just anything
named `bash.exe` on PATH — Windows ships an unrelated WSL `bash.exe` stub that
runs a separate Linux toolchain and can't see your Windows-side tools), or
tells you to install [Git for Windows](https://git-scm.com/downloads/win) if
it doesn't. Windows users can use the `.ps1` commands throughout this guide in
place of the `bash ...` ones shown.

## One-time (maintainer of *this* repo)

GitHub → **Settings → General → check "Template repository"**. Already done here —
the repo shows a **Use this template** button.

---

## Step 1 — Create and clone

On GitHub click **Use this template → Create a new repository**, then:

```bash
git clone https://github.com/<you>/<new-repo>.git
cd <new-repo>
```

## Step 2 — Rename (scripted)

```bash
bash scripts/new-project.sh Contoso.Portal                 # clean skeleton (recommended)
bash scripts/new-project.sh Contoso.Portal --with-sample   # keep the Listing CRUD example
```

**Windows without Git Bash yet:**

```powershell
powershell -File scripts/new-project.ps1 Contoso.Portal
powershell -File scripts/new-project.ps1 Contoso.Portal -WithSample
```

Same script either way — `new-project.ps1` delegates to `new-project.sh` via
Git Bash (see the Prerequisites note above).

The working tree must be clean. Both `new-project.sh` and `remove-sample.sh`
refuse to run if this repo's `origin` remote is still the canonical
`github.com/CarlNaddy/dotnetskills` — a project created via "Use this
template" always gets its own new `origin`, so this only ever fires if
you're accidentally in the template repo itself, not a project made from it
(bypass with `I_UNDERSTAND_THIS_IS_THE_TEMPLATE=1`, template-maintenance
only). The script:

- replaces the `dotnetskills` identifier in every tracked text file
  (namespaces, usings, `_Imports.razor`, `.slnx`, launch profiles, …);
- renames `dotnetskills.csproj` → `Contoso.Portal.csproj`,
  `dotnetskills.slnx` → `Contoso.Portal.slnx`, and
  `tests/dotnetskills.Tests/` → `tests/Contoso.Portal.Tests/`;
- regenerates `<UserSecretsId>`;
- resets `README.md` to a short project stub;
- deletes this repo's history docs (`rails-parity-plan.md`, `setup-log.md`);
- **removes the `Listing` sample feature** (`scripts/remove-sample.sh`) unless
  `--with-sample` — deletes `Components/Pages/Listings/`, `Data/Listing.cs`,
  `Data/Seed/`, `Data/Migrations/`, `ListingTests.cs`; empties `AppDbContext`;
  drops the seed dispatch from `Program.cs` and the Listings nav link. A
  placeholder test replaces `ListingTests`.
- installs the Claude Code plugins/skills from `.claude/settings.json`
  (idempotent — `check-plugins.sh --fix`; skipped with a warning if the
  `claude` CLI isn't on PATH, rerun any time);
- prints the remaining manual steps.

The project **compiles** either way. A skeleton has no entities, migrations, or
seed data — like `rails new`.

## Step 3 — Point at your database

Edit `compose.yaml` — set the Postgres identifiers (and the host port if 5432 is
taken):

```yaml
    environment:
      POSTGRES_DB: contosoportal
      POSTGRES_USER: contosoportal
      POSTGRES_PASSWORD: dev_only_change_me
    ports:
      - "5432:5432"
```

Store the dev connection string in user-secrets (run in the folder with
`Contoso.Portal.csproj`):

```bash
dotnet user-secrets set "ConnectionStrings:Default" \
  "Host=localhost;Port=5432;Database=contosoportal;Username=contosoportal;Password=dev_only_change_me"
```

## Step 4 — Bring it up

```bash
docker compose up -d db
dotnet format Contoso.Portal.slnx   # normalise line endings from the rename
dotnet build
dotnet test                         # xUnit v3 via MTP
dotnet watch run                    # http://localhost:5xxx  →  Home
```

With `--with-sample`, also run `dotnet run -- seed` (applies the 3 migrations
and seeds 5 listings) and the nav has a **Listings** page.

## Step 5 — Make it yours (`CLAUDE.md`)

- Retitle; delete the status blockquote and the **"Reuse — starting a new
  project"** section.
- Keep: Stack table, **Data access**, **MudBlazor rules**, **Conventions**
  (incl. Tests and Localization).
- Drop the `Listing` / `dotnet run -- seed` mentions (skeleton), and fix the
  `docs/ef-migrations.md` link — its conventions still apply; the worked example
  just refers to the (removed) sample.

## Step 6 — Add your first model

Like `rails g model` / `rails g scaffold`:

```bash
# create Data/<Entity>.cs, add DbSet<Entity> to AppDbContext, then:
dotnet ef migrations add InitialCreate -o Data/Migrations
dotnet ef database update
```

Use `dotnet-data:create-datadriven-aspnetcore` + `mudblazor:mudblazor` for the
CRUD UI. (With `--with-sample`, the `Listing` feature is the worked pattern.)

## Step 7 — (optional) Spec-driven development with OpenSpec

To plan features as specs before implementing them:

```bash
bash scripts/setup-openspec.sh      # needs Node 18+; installs the CLI, runs `openspec init`
```

`openspec init` creates `openspec/` (`specs/`, `changes/`, `archive/`) and wires
slash commands into Claude Code. Workflow:

```
/opsx:explore <idea>       weigh options
/opsx:propose <feature>    -> openspec/changes/<id>/ : proposal.md, specs/, design.md, tasks.md
/opsx:apply                implement the tasks
/opsx:archive              fold the spec deltas into openspec/specs/, archive the change
```

Implement the feature with the bundled skills (CRUD via
`dotnet-data:create-datadriven-aspnetcore` + `mudblazor:mudblazor`, etc.),
following the `Listing` feature as the pattern. `openspec update` refreshes the
agent guidance after CLI upgrades.

## Step 8 — Commit

```bash
git rm scripts/new-project.sh scripts/new-project.ps1 scripts/remove-sample.sh \
  scripts/_guard-not-template.sh docs/new-project.md   # templating helpers
git add -A
git commit -m "Initialize from template"
```

---

## What carries over vs. what to strip

| Carries over | Removed by the script |
|---|---|
| `.claude/settings.json` — plugins & marketplaces | `docs/rails-parity-*.md`, `docs/setup-log.md` |
| `CLAUDE.md`, `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`, `.gitattributes`, `global.json` | `Components/Pages/Listings/`, `Data/Listing.cs`, `Data/Seed/`, `Data/Migrations/`, `ListingTests.cs` *(kept with `--with-sample`)* |
| `compose.yaml` shape | the `Listing` `DbSet` + `OnModelCreating` in `AppDbContext.cs`; the `SeedCommand` dispatch in `Program.cs`; the Listings nav link *(kept with `--with-sample`)* |
| `Program.cs` wiring, `Endpoints/`, `Localization/`, `Resources/`, `tests/<Name>.Tests/` harness | — |
| `scripts/preflight.sh`, `scripts/preflight.ps1`, `scripts/_find-git-bash.ps1`, `scripts/check-plugins.sh`, `scripts/setup-openspec.sh`, `docs/ef-migrations.md` | *(keep these)* |

Remove by hand once set up: `scripts/new-project.sh`, `scripts/new-project.ps1`,
`scripts/remove-sample.sh`, `scripts/_guard-not-template.sh`, `docs/new-project.md`.
Rewrite: `CLAUDE.md` title + "Reuse" section, `README.md` stub.
