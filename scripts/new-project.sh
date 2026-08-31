#!/usr/bin/env bash
#
# Turn a fresh copy of this template repo into a new project.
#
#   scripts/new-project.sh <NewName>
#   e.g.  scripts/new-project.sh Acme.Portal
#
# Does the mechanical rename only:
#   - replaces the identifier `dotnetskills` everywhere in tracked text files
#   - renames dotnetskills.csproj -> <NewName>.csproj
#   - regenerates the UserSecretsId
#   - deletes the template-journey docs (parity plan/assessment, setup log,
#     this guide, and this script)
#
# It leaves the project compiling (the Listing reference feature is kept, just
# renamed). See docs/new-project.md for the manual follow-up steps, including
# how to drop the reference feature.

set -euo pipefail

OLD="dotnetskills"
NEW="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -z "$NEW" ]; then
    echo "usage: scripts/new-project.sh <NewName>" >&2
    exit 2
fi
if [ "$NEW" = "$OLD" ]; then
    echo "name is unchanged; nothing to do" >&2
    exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "working tree is dirty — commit or stash first" >&2
    exit 1
fi

echo "==> Replacing identifier '$OLD' -> '$NEW' in tracked text files"
git ls-files -z \
    | grep -zvE '(^|/)(bin|obj)/' \
    | grep -zvE '\.(png|jpe?g|gif|ico|woff2?|ttf|eot)$' \
    | grep -zvE 'scripts/new-project\.sh$' \
    | xargs -0 sed -i "s/${OLD}/${NEW}/g"

echo "==> Renaming ${OLD}.csproj -> ${NEW}.csproj"
git mv "${OLD}.csproj" "${NEW}.csproj"

echo "==> Regenerating UserSecretsId"
NEWID="$(uuidgen 2>/dev/null | tr 'A-Z' 'a-z' \
    || powershell -NoProfile -Command '[guid]::NewGuid().ToString()' | tr -d '\r')"
sed -i "s#<UserSecretsId>.*</UserSecretsId>#<UserSecretsId>${NEWID}</UserSecretsId>#" "${NEW}.csproj"

echo "==> Deleting template-journey docs"
git rm -q --ignore-unmatch \
    docs/rails-parity-plan.md \
    docs/rails-parity-assessment.md \
    docs/ef-migrations.md \
    docs/setup-log.md \
    docs/new-project.md \
    scripts/new-project.sh

cat <<EOF

Mechanical rename done. Now, by hand:

  1. CLAUDE.md — set the title/description; drop the parity-plan references;
     keep the Stack table, Data access, MudBlazor rules, and Conventions.
  2. compose.yaml — set POSTGRES_DB / POSTGRES_USER / POSTGRES_PASSWORD for '${NEW}'.
  3. dotnet user-secrets set "ConnectionStrings:Default" \\
       "Host=localhost;Port=5432;Database=${NEW};Username=${NEW};Password=CHANGE_ME"
  4. (optional) drop the Listing reference feature:
       git rm -r Components/Pages/Listings Data/Listing.cs Data/Seed Data/Migrations
       # then remove DbSet<Listing> + OnModelCreating body from Data/AppDbContext.cs
       # and the SeedCommand dispatch + usings from Program.cs
       mkdir -p Data/Migrations
       dotnet ef migrations add InitialCreate -o Data/Migrations
  5. docker compose up -d db && dotnet tool restore && dotnet ef database update
  6. dotnet build && dotnet format --verify-no-changes
  7. git add -A && git commit -m "Initialize from template"
EOF
