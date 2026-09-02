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

## What's still open (P5.3, P5.4)

- **P5.3** — CI/CD to a live target needs an actual hosting decision (Azure
  Container Apps / App Service / Fly.io / self-host) and real credentials —
  not something to pick unilaterally. GitHub Actions already runs
  restore → build → test (P2.5); extending it to publish + deploy is
  straightforward once a target is chosen.
- **P5.4** — production hardening: HTTPS, persisted Data Protection keys
  (the P5.1 verification run surfaced the exact warning this fixes — "No XML
  encryptor configured... may be persisted in unencrypted form," and without
  persistence, auth cookies don't survive a container restart), secrets via
  env/key vault (already the pattern for connection strings and OAuth
  secrets — P5.4 is about formalizing it, not introducing it), `/health` +
  `/alive` health checks.

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
