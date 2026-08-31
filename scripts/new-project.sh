#!/usr/bin/env bash
#
# Turn a fresh copy of this template repo into a new project.
#
#   scripts/new-project.sh <NewName>          e.g.  scripts/new-project.sh Acme.Portal
#
# Mechanical rename only:
#   - replaces the identifier `dotnetskills` in tracked text files
#   - renames every file/directory whose path contains `dotnetskills`
#     (.csproj, .slnx, tests/dotnetskills.Tests/, ...)
#   - regenerates the UserSecretsId
#   - removes this repo's history docs (parity plan/assessment, setup log)
#
# Leaves the project compiling (the Listing reference feature is kept, just
# renamed). Prints the remaining manual steps; full detail in docs/new-project.md.

set -euo pipefail

OLD="dotnetskills"
NEW="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[ -n "$NEW" ]        || { echo "usage: scripts/new-project.sh <NewName>" >&2; exit 2; }
[ "$NEW" != "$OLD" ] || { echo "name unchanged; nothing to do" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree is dirty — commit or stash first" >&2; exit 1; }

echo "==> Replacing identifier '$OLD' -> '$NEW' in tracked text files"
git ls-files -z \
    | grep -zvE '(^|/)(bin|obj)/' \
    | grep -zvE '\.(png|jpe?g|gif|ico|woff2?|ttf|eot)$' \
    | grep -zvE '(^|/)scripts/new-project\.sh$' \
    | xargs -0 sed -i "s/${OLD}/${NEW}/g"

echo "==> Renaming files/directories that contain '$OLD'"
git ls-files | grep -F "$OLD" | while IFS= read -r f; do
    newf="${f//${OLD}/${NEW}}"
    [ "$f" = "$newf" ] && continue
    mkdir -p "$(dirname "$newf")"
    git mv "$f" "$newf"
done
find . -type d -empty -not -path './.git/*' -delete 2>/dev/null || true

echo "==> Regenerating UserSecretsId"
NEWID="$(uuidgen 2>/dev/null | tr 'A-Z' 'a-z' \
    || powershell -NoProfile -Command '[guid]::NewGuid().ToString()' | tr -d '\r')"
sed -i "s#<UserSecretsId>.*</UserSecretsId>#<UserSecretsId>${NEWID}</UserSecretsId>#" "${NEW}.csproj"

echo "==> Removing this repo's history docs"
git rm -qf --ignore-unmatch \
    docs/rails-parity-plan.md \
    docs/rails-parity-assessment.md \
    docs/setup-log.md

cat <<EOF

Mechanical rename done. Remaining manual steps:

  1. CLAUDE.md — retitle; replace the "Reuse — starting a new project" section
     and any parity-plan references with your own notes. Keep Stack, Data access,
     MudBlazor rules, Conventions, Tests, Localization.
  2. compose.yaml — set POSTGRES_DB / POSTGRES_USER / POSTGRES_PASSWORD.
  3. In the folder containing ${NEW}.csproj:
       dotnet user-secrets set "ConnectionStrings:Default" \\
         "Host=localhost;Port=5432;Database=<db>;Username=<user>;Password=<pw>"
  4. (optional) drop the Listing reference feature — steps in docs/new-project.md.
  5. docker compose up -d db && dotnet tool restore && dotnet ef database update
  6. dotnet build && dotnet test && dotnet format ${NEW}.slnx --verify-no-changes
  7. Remove the templating helpers you no longer need:
       git rm scripts/new-project.sh docs/new-project.md
     (keep docs/ef-migrations.md — the EF migration conventions still apply.)
  8. git add -A && git commit -m "Initialize from template"
EOF
