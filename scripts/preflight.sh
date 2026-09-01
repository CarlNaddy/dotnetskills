#!/usr/bin/env bash
#
# Check the tools this project needs.
#   scripts/preflight.sh              required tools (OpenSpec/Node = optional)
#   scripts/preflight.sh --openspec   also make Node/npm a hard requirement
#
# Exits non-zero if a required tool is missing or misconfigured.

set -uo pipefail

need_openspec=0
[ "${1:-}" = "--openspec" ] && need_openspec=1

fail=0
ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$1"; }

echo "Preflight — required:"

if command -v git >/dev/null 2>&1; then
    ok "git $(git --version | awk '{print $3}')"
else
    bad "git — install from https://git-scm.com/downloads"
fi

if command -v dotnet >/dev/null 2>&1; then
    if dotnet --list-sdks 2>/dev/null | grep -qE '^1[0-9]\.'; then
        ok "dotnet SDK $(dotnet --list-sdks | grep -E '^1[0-9]\.' | tail -1 | awk '{print $1}')"
    else
        have="$(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | paste -sd, - )"
        bad "dotnet SDK 10+ not found (have: ${have:-none}) — https://dotnet.microsoft.com/download/dotnet/10.0"
    fi
else
    bad "dotnet — install the .NET 10 SDK from https://dotnet.microsoft.com/download/dotnet/10.0"
fi

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        ok "docker $(docker info --format '{{.ServerVersion}}' 2>/dev/null) (daemon running)"
    else
        bad "docker is installed but its daemon is not running — start Docker Desktop"
    fi
else
    bad "docker — install from https://docs.docker.com/get-docker/"
fi

echo "Optional — OpenSpec (spec-driven development):"
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    ok "node $(node --version) + npm $(npm --version)"
elif [ "$need_openspec" = 1 ]; then
    bad "node + npm — required for OpenSpec; install Node 18+ from https://nodejs.org"
else
    warn "node/npm not found — only needed for scripts/setup-openspec.sh"
fi

echo "Optional — Claude Code AI tooling:"
here="$(dirname "$0")"
if [ ! -f "$here/../.claude/settings.json" ]; then
    warn ".claude/settings.json not found — AI tooling config missing"
elif ! command -v claude >/dev/null 2>&1; then
    warn "'claude' CLI not on PATH — open the repo in Claude Code to install plugins"
elif "$here/check-plugins.sh" >/dev/null 2>&1; then
    ok "Claude Code plugins installed and enabled"
else
    warn "some Claude Code plugins missing — run scripts/check-plugins.sh [--fix]"
fi

echo
if [ "$fail" = 1 ]; then
    echo "Preflight failed. Install the tools marked FAIL, then re-run." >&2
    exit 1
fi
echo "Preflight OK."
