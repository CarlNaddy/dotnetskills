#!/usr/bin/env bash
#
# Turn a fresh copy of this template repo into a new project.
#
#   scripts/new-project.sh <NewName>                 e.g.  ... Acme.Portal
#   scripts/new-project.sh <NewName> --with-sample   keep the Listing CRUD example
#
# Runs the preflight check, then:
#   - replaces the identifier `dotnetskills` in tracked text files
#   - renames every file/directory whose path contains `dotnetskills`
#   - regenerates the UserSecretsId, resets README.md
#   - removes this repo's history docs
#   - removes the Listing sample feature so you start from a clean skeleton
#     (pass --with-sample to keep it)
#
# Prints the remaining manual steps; full detail in docs/new-project.md.

set -euo pipefail

OLD="dotnetskills"
NEW=""
with_sample=0
for a in "$@"; do
    case "$a" in
        --with-sample) with_sample=1 ;;
        -*) echo "unknown option: $a" >&2; exit 2 ;;
        *) [ -z "$NEW" ] && NEW="$a" || { echo "unexpected argument: $a" >&2; exit 2; } ;;
    esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[ -n "$NEW" ]        || { echo "usage: scripts/new-project.sh <NewName> [--with-sample]" >&2; exit 2; }
[ "$NEW" != "$OLD" ] || { echo "name unchanged; nothing to do" >&2; exit 1; }

"$ROOT/scripts/preflight.sh" || exit 1
echo

[ -z "$(git status --porcelain)" ] || { echo "working tree is dirty — commit or stash first" >&2; exit 1; }

echo "==> Replacing identifier '$OLD' -> '$NEW' in tracked text files"
git ls-files -z \
    | grep -zvE '(^|/)(bin|obj)/' \
    | grep -zvE '\.(png|jpe?g|gif|ico|woff2?|ttf|eot)$' \
    | grep -zvE '(^|/)(scripts/new-project|scripts/update-from-template)\.sh$' \
    | grep -zvE '(^|/)docs/updating-from-template\.md$' \
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
new_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr 'A-Z' 'a-z'
    elif [ -r /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        # Git Bash / MSYS has neither — build a v4 UUID from /dev/urandom.
        local b
        b="$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')"
        printf '%s-%s-4%s-8%s-%s\n' \
            "${b:0:8}" "${b:8:4}" "${b:13:3}" "${b:17:3}" "${b:20:12}"
    fi
}
NEWID="$(new_uuid)"
sed -i "s#<UserSecretsId>.*</UserSecretsId>#<UserSecretsId>${NEWID}</UserSecretsId>#" "${NEW}.csproj"

if [ "$with_sample" = 1 ]; then
    seed_line='dotnet run -- seed        # apply migrations + seed sample data'
else
    seed_line='dotnet ef database update # once you add your first model'
fi

echo "==> Resetting README.md to a project stub"
cat > README.md <<EOF
# ${NEW}

ASP.NET Core Blazor Web App — .NET 10, MudBlazor, EF Core + PostgreSQL.
Started from the [dotnetskills](https://github.com/CarlNaddy/dotnetskills) template.

## Run locally

\`\`\`bash
docker compose up -d db
dotnet tool restore
${seed_line}
dotnet watch run
dotnet test
\`\`\`

Conventions and AI tooling: see \`CLAUDE.md\`.
EOF

echo "==> Removing this repo's history docs"
git rm -qf --ignore-unmatch \
    docs/rails-parity-plan.md \
    docs/rails-parity-assessment.md \
    docs/setup-log.md

echo "==> Recording template baseline (.template-version)"
# scripts/update-from-template.sh diffs the template from this commit forward.
# HEAD is still the pristine template tree here (nothing has been committed yet),
# so its tree hash matches the template commit we were created from.
git remote get-url template >/dev/null 2>&1 \
    || git remote add template "https://github.com/CarlNaddy/${OLD}.git"
base=""
if git fetch -q template 2>/dev/null; then
    head_tree="$(git rev-parse 'HEAD^{tree}')"
    while IFS= read -r c; do
        if [ "$(git rev-parse "${c}^{tree}")" = "$head_tree" ]; then base="$c"; break; fi
    done < <(git rev-list template/main)
fi
if [ -n "$base" ]; then
    printf '%s\n' "$base" > .template-version
    echo "    baseline: $base"
else
    printf 'UNKNOWN\n' > .template-version
    echo "    could not detect the baseline (offline, or no tree match)."
    echo "    Set .template-version to the commit you started from before running"
    echo "    scripts/update-from-template.sh  (git log --oneline template/main)."
fi
git add .template-version 2>/dev/null || true

if [ "$with_sample" = 0 ]; then
    echo
    "$ROOT/scripts/remove-sample.sh"
fi

cat <<EOF

Rename done$([ "$with_sample" = 0 ] && echo " (clean skeleton — Listing sample removed)"). Remaining manual steps:

  1. CLAUDE.md — retitle; replace the "Reuse — starting a new project" section
     and parity-plan references with your own notes. Keep Stack, Data access,
     MudBlazor rules, Conventions, Tests, Localization.
  2. compose.yaml — set POSTGRES_DB / POSTGRES_USER / POSTGRES_PASSWORD.
  3. In the folder containing ${NEW}.csproj:
       dotnet user-secrets set "ConnectionStrings:Default" \\
         "Host=localhost;Port=5432;Database=<db>;Username=<user>;Password=<pw>"
  4. docker compose up -d db && dotnet tool restore
  5. dotnet format ${NEW}.slnx && dotnet build && dotnet test
  6. AI tooling — open the repo in Claude Code and accept the marketplace-trust
     prompts (.claude/settings.json installs the dotnet* / mudblazor plugins).
     Verify:  bash scripts/check-plugins.sh   (add --fix to install headlessly)
  7. (optional) spec-driven development:  bash scripts/setup-openspec.sh
       then, in Claude Code:  /opsx:propose <feature>  ->  /opsx:apply
  8. Remove the templating helpers you no longer need:
       git rm scripts/new-project.sh scripts/remove-sample.sh docs/new-project.md
     Keep: scripts/preflight.sh, scripts/check-plugins.sh, scripts/setup-openspec.sh,
     docs/ef-migrations.md, and — to pull future template updates —
     scripts/update-from-template.sh, docs/updating-from-template.md, .template-version.
  9. git add -A && git commit -m "Initialize from template"

Later, to pull template changes into this project:
     bash scripts/update-from-template.sh --dry-run   # preview
     bash scripts/update-from-template.sh             # apply
   See docs/updating-from-template.md.
EOF
