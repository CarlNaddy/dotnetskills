#!/usr/bin/env bash
#
# Remove the `Listing` sample feature, leaving a clean skeleton — the state a
# `rails new` gives you: an app wired up (DB, MudBlazor, localization, tests)
# but with no domain code, migrations, or seed data.
#
# Run standalone, or let scripts/new-project.sh call it (it does, unless you
# pass --with-sample).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=_guard-not-template.sh
. "$ROOT/scripts/_guard-not-template.sh"
guard_not_template_repo

ns="$(sed -nE 's/^namespace (.+)\.Data;.*/\1/p' Data/AppDbContext.cs | head -1)"
[ -n "$ns" ] || { echo "could not read the root namespace from Data/AppDbContext.cs" >&2; exit 1; }

echo "==> Deleting sample files"
git rm -qrf --ignore-unmatch \
    Components/Pages/Listings \
    Data/Listing.cs \
    Data/Seed \
    Data/Migrations \
    tests/*/Data/ListingTests.cs

echo "==> Resetting Data/AppDbContext.cs to an empty context"
cat > Data/AppDbContext.cs <<EOF
using Microsoft.EntityFrameworkCore;

namespace ${ns}.Data;

/// <summary>The application's Entity Framework Core context.</summary>
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
}
EOF

echo "==> Trimming Program.cs, NavMenu.razor, resx"
# drop the `using <ns>.Data.Seed;` line and the `dotnet run -- seed` dispatch block
perl -ni -e 'print unless /^using \S+\.Data\.Seed;\s*$/' Program.cs
awk '
  /dotnet run -- seed/ && /^\/\// { skip = 1 }
  !skip                           { print }
  skip && /^\}/                   { skip = 0; next }
' Program.cs > Program.cs.tmp && mv Program.cs.tmp Program.cs
perl -0pi -e 's/\R\R\R+/\n\n/g' Program.cs
# drop the Listings nav link and the now-unused resource key
perl -ni -e 'print unless /Href="listings"/' Components/Layout/NavMenu.razor
perl -0pi -e 's{[ \t]*<data name="Nav_Listings".*?</data>\R}{}s' \
    Resources/Localization/SharedResource.resx Resources/Localization/SharedResource.de.resx

echo "==> Adding a placeholder test in place of ListingTests"
testdir="$(ls -d tests/*/ 2>/dev/null | head -1)Data"
mkdir -p "$testdir"
cat > "$testdir/AppDbContextTests.cs" <<EOF
using ${ns}.Data;
using Microsoft.EntityFrameworkCore;

namespace ${ns}.Tests.Data;

public class AppDbContextTests
{
    [Fact]
    public void AppDbContext_derives_from_DbContext() =>
        Assert.True(typeof(AppDbContext).IsSubclassOf(typeof(DbContext)));
}
EOF
git add "$testdir/AppDbContextTests.cs"

find . -type d -empty -not -path './.git/*' -delete 2>/dev/null || true

cat <<'EOF'

Sample removed — the project builds as an empty skeleton (no entities, no
migrations, no seed data). Tidy the remaining prose by hand:
  - CLAUDE.md ...... drop the Listing / "dotnet run -- seed" mentions
  - README.md ...... the "dotnet run -- seed" line, if your stub still has it
  - docs/ef-migrations.md ... its worked example refers to the removed feature

Add your first model, then:  dotnet ef migrations add InitialCreate -o Data/Migrations
EOF
