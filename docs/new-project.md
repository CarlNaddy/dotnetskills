# Starting a new project from this repo

This repo is a **reference app + a curated Claude Code setup**, usable as a
starting point for new .NET monoliths. The app code is a worked example, not
something to copy blindly — the reusable parts are the plugin/skill setup
(`.claude/settings.json`), the conventions (`CLAUDE.md`), and the patterns the
`Listing` feature demonstrates.

> A proper `dotnet new` template is the eventual goal — parity plan **P7.2**.
> Until then this is the **GitHub template-repository** route (Option A).

## One-time, by a maintainer of this repo

On GitHub: **Settings → General → check "Template repository"**. This cannot be
done from the CLI. After that, the repo shows a **Use this template** button.

## Per new project

1. **Create the repo** — click **Use this template → Create a new repository** on
   GitHub. You get a fresh repo with no history.
2. **Clone it**, then from the repo root:
   ```bash
   scripts/new-project.sh <NewName>      # e.g. Acme.Portal
   ```
   This replaces the `dotnetskills` identifier everywhere, renames the `.csproj`,
   regenerates the `UserSecretsId`, and deletes the template-journey docs
   (`rails-parity-*.md`, `ef-migrations.md`, `setup-log.md`, this file, and the
   script itself). It leaves the project **compiling** — the `Listing` reference
   feature is kept, just renamed.
3. **Follow the manual steps** the script prints:
   - `CLAUDE.md` — retitle; drop the parity-plan references; keep Stack, Data
     access, MudBlazor rules, Conventions.
   - `compose.yaml` — set `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD`.
   - `dotnet user-secrets set "ConnectionStrings:Default" "...Database=<NewName>;Username=<NewName>;..."`
   - Optionally remove the `Listing` feature (commands in the script output) and
     regenerate `InitialCreate`.
   - `docker compose up -d db && dotnet tool restore && dotnet ef database update`
   - `dotnet build && dotnet format --verify-no-changes`
   - `git commit -m "Initialize from template"`
4. **Re-run onboarding for the Claude Code plugins** — open the new repo in
   Claude Code and accept the marketplace-trust prompts (`.claude/settings.json`
   is carried over unchanged).

## What carries over vs. what to strip

| Keep | Strip / rewrite |
|---|---|
| `.claude/settings.json` (plugins/marketplaces) | `docs/rails-parity-*.md`, `docs/setup-log.md`, `docs/new-project.md` |
| `CLAUDE.md` Stack / Data access / MudBlazor / Conventions | `CLAUDE.md` status blockquote + parity-plan pointers |
| `Directory.Build.props`, `.editorconfig`, `global.json` | `Components/Pages/Listings/`, `Data/Listing.cs`, `Data/Seed/` (optional) |
| `compose.yaml` shape (retarget the DB name) | existing `Data/Migrations/*` if the sample is removed |
| `Program.cs` wiring (MudBlazor, EF factory) | `SeedCommand` dispatch in `Program.cs` if `Data/Seed/` is removed |
| `Data/AppDbContext.cs` shell | `DbSet<Listing>` + its `OnModelCreating` block |
