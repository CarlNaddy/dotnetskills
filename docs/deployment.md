# Deployment

The `rails-parity` **P5** phase (Kamal analog). Follows official Microsoft
container guidance throughout — no bespoke tooling, no Aspire (orchestration
for multi-service apps, overkill for this monolith, per the standing scoping
decision).

## P5.1 — Container image: the SDK's built-in container publish

```bash
dotnet publish dotnetskills.csproj -t:PublishContainer -c Release
```

**Not a hand-maintained `Dockerfile`.** The .NET SDK's container publish
target (`Microsoft.NET.Build.Containers`, built in since .NET 7) builds the
image directly from `dotnet publish` output — base image and tag resolve
automatically from `TargetFramework` (`mcr.microsoft.com/dotnet/aspnet:10.0`
here); only the repository name is worth pinning explicitly
(`<ContainerRepository>dotnetskills</ContainerRepository>` in
`dotnetskills.csproj`). Falls back to a standard multi-stage `Dockerfile`
only if this ever needs more control than the SDK path gives — not needed
yet. `.dockerignore` is present for that fallback and for any future
`docker build` usage, even though the SDK publish path doesn't read it
(it builds from `dotnet publish`'s output, not a build context).

The image listens on **port 8080** (the MS container images' default
`ASPNETCORE_HTTP_PORTS`) — not 5066/7105, which are only the `dotnet
watch run` dev-server ports from `launchSettings.json`.

**Known-benign startup message:** `Cannot load library libgssapi_krb5.so.2`
— Npgsql probing for optional GSSAPI/Kerberos auth support, which this app
doesn't use (password auth only). Confirmed harmless: the app still connects
to Postgres and serves real data (see verification below). Not worth adding
the Kerberos libraries or switching off the SDK-publish base image to
silence a log line that doesn't indicate a real problem.

## P5.2 — Full local stack in one command

```bash
bash scripts/run-stack.sh              # build + start, seed if the DB is empty
bash scripts/run-stack.sh --no-seed    # build + start only
bash scripts/run-stack.sh --down       # stop everything
```

`compose.yaml`'s `app` service uses `image: dotnetskills:latest` — the image
P5.1 builds — **not** a Dockerfile `build:` section, so `docker compose up`
alone can't build it from source (Compose's own build mechanism expects a
Dockerfile, and P5.1 deliberately doesn't have one). `scripts/run-stack.sh`
is what makes it genuinely **one command**: it runs the SDK container
publish, then `docker compose up -d`, then seeds
(`docker compose run --rm app seed` — the same `dotnet run -- seed` verb
dispatch, reached by appending `seed` to the image's exec-form
`ENTRYPOINT ["dotnet", "/app/dotnetskills.dll"]`; idempotent, safe to rerun).

- `db` and `mail` are unchanged from P1.2/P4.2 — `app` is new. It talks to
  them by **service name** (`db`, `mail`), not `localhost` — a different
  network namespace than the host-side `dotnet watch run` dev loop uses,
  which is why `Email__Host`/`ConnectionStrings__Default` differ between the
  two (`compose.yaml`'s `app` service env vars vs. user-secrets).
- `depends_on: db: condition: service_healthy` — `app` waits for Postgres's
  existing healthcheck (P1.2), not just "container started."
- Redis is **(vNext)**, per the standing scoping decision — added only if
  the app ever runs more than one instance.

## P5.4 — Production hardening

### Data Protection keys persist in Postgres, not in memory

`AppDbContext` implements `IDataProtectionKeyContext`;
`AddDataProtection().SetApplicationName("dotnetskills").PersistKeysToDbContext<AppDbContext>()`
(`Program.cs`) stores the key ring in a new `DataProtectionKeys` table
instead of the in-memory default, which silently regenerates a fresh key
ring on every restart — invalidating every issued auth cookie and
antiforgery token without any visible error, just users getting logged out
and CSRF-token mismatches after every deploy. Same "no separate infra"
pattern as everything else in this app (Hangfire, caching): Postgres, not a
new store.

`SetApplicationName` matters specifically because `dotnet watch run` (host,
content root `C:\...\dotnetskills`) and the container (content root `/app`)
have different `ContentRootPath`s, which Data Protection otherwise folds
into the key ring's identity — without a fixed name, keys written by one
environment wouldn't be recognized as belonging to "this app" by the other,
even sharing the same Postgres table.

**Persistence, not encryption-at-rest.** The XML key material is stored
un-encrypted in the database — ASP.NET Core's own "No XML encryptor
configured" warning still prints, and still should: that's flagging a
*different, separate* concern (protecting the keys themselves via a
certificate or cloud KMS) from what was actually broken (keys not
surviving a restart at all). Encrypting them needs real key-management
infrastructure this environment doesn't have — the same category of gap as
P5.3's live deploy target: a real decision needing real infrastructure, not
something to fake. Documented here rather than silently left unmentioned.

### `/health` and `/alive`

The MS-documented split for container orchestrators that probe the two
differently: `/health` runs every registered check (a `"self"` check plus
`AddDbContextCheck<AppDbContext>()`) — readiness, "can this instance
actually serve requests." `/alive` runs only checks tagged `"live"` (just
`"self"`) — liveness, "is the process running," with no dependency calls,
for a fast probe that shouldn't fail just because the database is briefly
unreachable.

### Forwarded headers, for correct HTTPS detection behind a proxy

A containerized deploy terminates TLS at the ingress/reverse-proxy layer,
not in-process — the container itself only ever speaks plain HTTP inside
the platform's network. Without `UseForwardedHeaders`, the app never sees
the original request as HTTPS, so `UseHttpsRedirection` would redirect-loop
behind a proxy that already terminated TLS for the client. Placed **before**
`UseHttpsRedirection` in the pipeline, and deliberately clears
`KnownIPNetworks`/`KnownProxies` (the default only trusts loopback, which is
a silent no-op behind a real cloud load balancer whose IP isn't loopback and
usually isn't static enough to allowlist) — trusting the platform's own
network boundary (only the load balancer can reach the container) instead
of an IP allowlist, the standard tradeoff for this deployment shape.

### Secrets via env / key vault — already the pattern, not new here

Every secret already follows env-in-prod / user-secrets-in-dev: the
connection string (P1.3), OAuth client secrets (P3.4), the seed admin
password (P3.6, and the seeder throws if it's unset outside Development).
P5.4 doesn't introduce a new mechanism — it's the confirmation that the
pattern already covers everything, including the two things P5.4 itself
added (Data Protection needs no secret at all; health checks expose no
secret either).

## P5.3 — CI/CD to a live target (Fly.io)

**The pipeline is fully written and locally verified where it can be
without an account — it hasn't deployed anywhere live yet.** That needs
account-side setup only you can do (a Fly.io account, credentials, real
secrets) — this section is the exact, complete list.

### How it's wired

```
.github/workflows/deploy.yml   # publish + deploy, gated on CI (P2.5) passing on main
fly.toml                       # Fly app config
```

- **Triggered by `workflow_run`**, not its own copy of the test job —
  `deploy.yml` only runs after the existing `CI` workflow (P2.5) completes
  successfully on `main`. No duplicated restore/build/test step.
- **Image**: the same P5.1 `dotnet publish -t:PublishContainer` used
  locally, pushed to **GitHub Container Registry** (`ghcr.io`) — no extra
  registry account or secret needed beyond the `GITHUB_TOKEN` Actions
  already provides. Tagged by **commit SHA**, never `latest` — every deploy
  references one exact, reproducible image.
- **`fly.toml`** has no `[build]` section — `flyctl deploy` in the workflow
  always gets `--image ghcr.io/<owner>/dotnetskills:<sha>` explicitly. A
  bare `fly deploy` run by hand without `--image` would otherwise look for
  a Dockerfile, which this repo deliberately doesn't have.
- **`/alive`** (P5.4 — liveness only, no DB dependency) is the configured
  health check, not `/health` — the right choice for "is this Machine up,"
  not "can it reach every dependency right now" (which a database blip
  would then wrongly flag as *this Machine* being unhealthy).

### Account-side setup (you, once, to make this real)

```bash
# 1. Install flyctl and log in
curl -L https://fly.io/install.sh | sh
fly auth login

# 2. Create the app — pick a globally-unique name and a region; update
#    fly.toml's `app` and `primary_region` to match what you chose
fly apps create <your-app-name>

# 3. Postgres — Fly Postgres is the natural default (same "no separate
#    infra" pattern as everything else in this app), but any reachable
#    Postgres works, it's just a connection string
fly postgres create --name <your-app-name>-db
fly postgres attach <your-app-name>-db -a <your-app-name>

# 4. Every secret this app needs in prod — none of these are in fly.toml
#    or the repo, on purpose (same env-var-in-prod pattern as everywhere
#    else — P1.3, P3.4, P3.6, P4.2). `fly postgres attach` above already
#    set ConnectionStrings__Default for you; the rest need setting by hand:
fly secrets set Seed__AdminPassword="<a real password>" -a <your-app-name>
fly secrets set Email__Host="<your real SMTP host>" \
  Email__Port="<port>" Email__Username="<user>" Email__Password="<password>" \
  -a <your-app-name>
# Only if you're using external OAuth logins (P3.4):
fly secrets set Authentication__Google__ClientId="..." Authentication__Google__ClientSecret="..." \
  -a <your-app-name>

# 5. FLY_API_TOKEN, so the GitHub Actions workflow can deploy on your behalf
fly tokens create deploy -a <your-app-name>
# Add the output as a repository secret: Settings -> Secrets and variables
# -> Actions -> New repository secret -> name it FLY_API_TOKEN
```

After that, the next push to `main` (once `CI` passes) triggers a real
deploy automatically. `fly logs -a <your-app-name>` and
`fly status -a <your-app-name>` are the equivalents of the `docker compose
logs -f app` / `docker compose ps` used locally in P5.2.

**Not done for you, deliberately:** creating the Fly app, provisioning
Postgres, and every secret value above are account-and-money decisions —
the same reasoning P5.3 itself was blocked on before a target was chosen.
Once you've run the steps above, this phase's own accept criterion ("green
pipeline deploys to a live environment") is something *you* can watch
happen on the next push, not something to fake here.

## Verified end-to-end (2026-09-03)

**P5.1**, standalone, connected to the existing `dotnetskills_default`
compose network: `dotnet publish -t:PublishContainer` → image builds
(`docker images dotnetskills` confirms it, 381MB) → `docker run` with
`ConnectionStrings__Default` pointing at the `db` service → home page and
`/listings` both `200`, `/api/listings` returns real seeded data through
the container network — genuine Postgres connectivity proven, not just "the
process starts."

**P5.2**, from a truly fresh state (`docker compose down -v`, wiping the
Postgres volume, then `bash scripts/run-stack.sh` with nothing pre-existing):
image builds, all three services start (`db` reaches `healthy`), the seed
step applies migrations and inserts sample + admin data inside the
container, and the running stack immediately serves that seeded data —
home page `200`, `/api/listings` returns the real sample listings, mail
sink UI `200`. Reran the script against the now-seeded stack — idempotent,
logs `"Admin user ... already present"`, no duplicate. `--down` cleanly
stops and removes all three containers plus the network.

**P5.4**, against the running `run-stack.sh` stack: app logs show real
`SELECT`/`INSERT` traffic against the new `DataProtectionKeys` table (keys
genuinely persisting, not just configured to); `/health` and `/alive` both
return `200 Healthy`. **The actual claim, proven with a real restart, not
just log-reading:** logged in as the seeded admin via `curl` (real cookie),
confirmed `/Account/Manage` → `200` with that cookie, then
`docker compose restart app` (a full container restart, not a graceful
reload), then replayed the **exact same pre-restart cookie** against
`/Account/Manage` again → still `200`, still the admin's own account page.
Without persisted keys, that second request would have failed (the cookie
encrypted with a now-gone in-memory key) and redirected to login instead —
confirmed the negative shape of this by recalling P5.1's run, which *did*
show the "unencrypted form" warning under the *previous*, non-persisted
configuration. An unauthenticated request to the same page after the
restart still correctly redirects (`302`) — persistence didn't weaken the
auth boundary itself. `dotnet test` → 29/29 (unchanged — no test-covered
code path changed), clean build with analyzers, `dotnet format
--verify-no-changes` clean.
