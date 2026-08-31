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
bash scripts/new-project.sh Acme.Portal        # your project name; a dotted name is fine
```

The working tree must be clean. The script:

- replaces the `dotnetskills` identifier in every tracked text file
  (namespaces, usings, `_Imports.razor`, `.slnx`, launch profiles, …);
- renames `dotnetskills.csproj` → `Acme.Portal.csproj`,
  `dotnetskills.slnx` → `Acme.Portal.slnx`, and
  `tests/dotnetskills.Tests/` → `tests/Acme.Portal.Tests/`;
- regenerates `<UserSecretsId>`;
- resets `README.md` to a short project stub;
- deletes this repo's history docs (`rails-parity-plan.md`,
  `rails-parity-assessment.md`, `setup-log.md`);
- prints the remaining manual steps.

The project still **compiles** after this — the `Listing` sample feature is kept,
just renamed.

## Step 3 — Point at your database

Edit `compose.yaml` — set the Postgres identifiers (and the host port if 5432 is
taken):

```yaml
    environment:
      POSTGRES_DB: acmeportal
      POSTGRES_USER: acmeportal
      POSTGRES_PASSWORD: dev_only_change_me
    ports:
      - "5432:5432"
```

Store the dev connection string in user-secrets (run in the folder with
`Acme.Portal.csproj`):

```bash
dotnet user-secrets set "ConnectionStrings:Default" \
  "Host=localhost;Port=5432;Database=acmeportal;Username=acmeportal;Password=dev_only_change_me"
```

## Step 4 — Bring it up

```bash
docker compose up -d db
dotnet tool restore                 # dotnet-ef
dotnet run -- seed                  # apply all migrations + seed 5 sample listings
#   ...or, for an empty schema:  dotnet ef database update
dotnet build
dotnet test                         # xUnit v3 via MTP — 3 smoke tests pass
dotnet watch run                    # http://localhost:5xxx  →  Home + /listings
```

If `dotnet format Acme.Portal.slnx --verify-no-changes` flags line endings, your
clone checked files out as LF; run `git add --renormalize . && git checkout .`
or ensure `git config --get core.autocrlf` is `true` before cloning.

## Step 5 — Make it yours (`CLAUDE.md`)

- Retitle; delete the status blockquote and the **"Reuse — starting a new
  project"** section.
- Keep: Stack table, **Data access**, **MudBlazor rules**, **Conventions**
  (incl. Tests and Localization).
- Fix the `docs/ef-migrations.md` link target if you keep that file (recommended
  — the migration conventions still apply; its worked example just refers to the
  sample feature).

## Step 6 — (optional) Remove the `Listing` sample feature

Not scripted — it's a judgement call. To do it:

```bash
git rm -r Components/Pages/Listings Data/Listing.cs Data/Seed Data/Migrations
git rm tests/Acme.Portal.Tests/Data/ListingTests.cs
mkdir Data/Migrations
```

Then edit:

| File | Change |
|---|---|
| `Data/AppDbContext.cs` | remove `DbSet<Listing> Listings` and the `OnModelCreating` body |
| `Program.cs` | remove `using Acme.Portal.Data.Seed;` and the `if (args.Contains(SeedCommand.Verb))` block |
| `Components/Layout/NavMenu.razor` | drop the `listings` `MudNavLink` |
| `Resources/Localization/SharedResource*.resx` | drop `Nav_Listings` (optional) |

Then re-baseline the schema:

```bash
dotnet ef migrations add InitialCreate -o Data/Migrations
docker compose down -v && docker compose up -d db
dotnet ef database update
dotnet build && dotnet test
```

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
git rm scripts/new-project.sh docs/new-project.md      # templating helpers, no longer needed
git add -A
git commit -m "Initialize from template"
```

## Step 9 — Claude Code

Open the new repo in Claude Code and accept the marketplace-trust prompts —
`.claude/settings.json` carries over unchanged, so the same `dotnet*` /
`mudblazor` plugins and skills apply.

---

## What carries over vs. what to strip

| Carries over | Strip / rewrite |
|---|---|
| `.claude/settings.json` — plugins & marketplaces | `docs/rails-parity-*.md`, `docs/setup-log.md` (script removes these) |
| `CLAUDE.md` — Stack, Data access, MudBlazor, Conventions | `CLAUDE.md` status blockquote + "Reuse" section; `README.md` (script stubs it — flesh it out) |
| `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`, `.gitattributes`, `global.json` | `scripts/new-project.sh`, `docs/new-project.md` (step 8) |
| `scripts/preflight.sh`, `scripts/setup-openspec.sh`, `docs/ef-migrations.md` | — keep |
| `compose.yaml` shape | its Postgres identifiers (step 3) |
| `Program.cs` wiring (MudBlazor, EF factory, localization) | `SeedCommand` dispatch — only if you remove `Data/Seed/` (step 6) |
| `Data/AppDbContext.cs` shell, `Endpoints/`, `Localization/`, `Resources/` | `Components/Pages/Listings/`, `Data/Listing.cs` — only if you do step 6 |
| `tests/<Name>.Tests/` harness (xUnit v3, MTP) | `ListingTests.cs` — only with step 6 |
