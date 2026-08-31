# dotnetskills — .NET monolith template

A ready-to-run **ASP.NET Core Blazor** monolith, plus a curated **Claude Code**
plugin/skill setup and coding conventions. Click **Use this template** and you
have a working app in minutes.

## Stack

| Concern | Choice |
|---|---|
| Framework | .NET 10 |
| Web | ASP.NET Core, Blazor Web App — global Interactive Server |
| UI | MudBlazor (no Bootstrap/Tailwind) |
| Data | EF Core 10 + PostgreSQL (Npgsql), migrations, `dotnet run -- seed` |
| Tests | xUnit v3 on the Microsoft Testing Platform |
| Local infra | `compose.yaml` (PostgreSQL) |

Also included: central package management, analyzers-as-errors + `.editorconfig`,
EF migration conventions (`docs/ef-migrations.md`), an `en`/`de` localization
scaffold, and a worked reference feature — `Listing` CRUD end to end
(entity → migration → MudBlazor grid/form/dialog → seed data).

## Use it for your own project

1. On GitHub click **Use this template → Create a new repository**, then clone it.
2. Rename it (needs **bash** — Git Bash on Windows):
   ```bash
   bash scripts/new-project.sh Acme.Portal
   ```
   Replaces the `dotnetskills` identifier and every `dotnetskills`-named file and
   folder, regenerates the `UserSecretsId`, resets this README, and removes the
   template's own history docs.
3. Point at a database — edit `compose.yaml` (Postgres db/user/password) and:
   ```bash
   dotnet user-secrets set "ConnectionStrings:Default" \
     "Host=localhost;Port=5432;Database=acmeportal;Username=acmeportal;Password=dev_only_change_me"
   ```
4. Bring it up:
   ```bash
   docker compose up -d db
   dotnet tool restore
   dotnet run -- seed
   dotnet build && dotnet test
   dotnet watch run
   ```
5. Make `CLAUDE.md` yours; optionally strip the `Listing` sample feature;
   `git rm scripts/new-project.sh docs/new-project.md`; commit.
6. Open the repo in Claude Code and accept the marketplace-trust prompts —
   `.claude/settings.json` carries the `dotnet*` / `mudblazor` plugins over.

**Full step-by-step (verified end to end): [`docs/new-project.md`](docs/new-project.md).**

## Run this repo as-is

```bash
docker compose up -d db
dotnet tool restore
dotnet run -- seed          # apply migrations + seed 5 sample listings
dotnet watch run            # http://localhost:5xxx  →  Home, /listings
dotnet test
```

## Conventions & AI tooling

`CLAUDE.md` is the source of truth: stack, project layout, naming/analyzer
policy, MudBlazor rules, data-access and migration conventions, tests,
localization. The pinned Claude Code plugins/skills live in
`.claude/settings.json` (two GitHub marketplaces — `dotnet/skills` and
`CarlNaddy/claude-plugins-dotnet`).

## Roadmap

This repo is being brought to Ruby on Rails-level developer productivity through
a phased plan — see [`docs/rails-parity-plan.md`](docs/rails-parity-plan.md) and
the [assessment](docs/rails-parity-assessment.md).
