# Windows entry point for scripts/preflight.sh.
#
# This repo's scripts (preflight.sh, new-project.sh, check-plugins.sh, ...)
# are bash throughout. Git Bash is the standard way to get bash on Windows,
# and this repo already needs Git -- so if Git Bash is found, delegate to
# the real preflight.sh; otherwise this is the one check that can run
# without it, and tells you what to install.
#
#   powershell -File scripts/preflight.ps1              required tools
#   powershell -File scripts/preflight.ps1 -OpenSpec     also require Node/npm

param(
    [switch]$OpenSpec
)

function Find-GitBash {
    # Prefer bash.exe next to Git's own install. Windows ships its own
    # bash.exe stub at System32\bash.exe (the WSL launcher) on many
    # machines even without Git or WSL configured -- it can't run a
    # Windows-style script path, so it's explicitly excluded below.
    $candidates = @()

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        # git.exe normally lives at <root>\cmd\git.exe or <root>\bin\git.exe
        $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
        $candidates += Join-Path $gitRoot 'bin\bash.exe'
    }

    $candidates += "$env:ProgramFiles\Git\bin\bash.exe"
    $candidates += "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    $candidates += "$env:LocalAppData\Programs\Git\bin\bash.exe"

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }

    # Last resort: any bash.exe on PATH that isn't the System32 WSL stub.
    $onPath = Get-Command bash.exe -ErrorAction SilentlyContinue -All
    foreach ($b in $onPath) {
        if ($b.Source -notlike "$env:WINDIR\System32\*") { return $b.Source }
    }

    return $null
}

$bashPath = Find-GitBash
if ($bashPath) {
    $scriptPath = Join-Path $PSScriptRoot 'preflight.sh'
    $bashArgs = @($scriptPath)
    if ($OpenSpec) { $bashArgs += '--openspec' }
    & $bashPath @bashArgs
    exit $LASTEXITCODE
}

Write-Host "FAIL  Git Bash not found." -ForegroundColor Red
Write-Host ""
Write-Host "This repo's scripts (scripts/preflight.sh, scripts/new-project.sh, ...) need bash."
Write-Host "Install Git for Windows -- it bundles Git Bash and is also this repo's Git requirement:"
Write-Host "  https://git-scm.com/downloads/win"
Write-Host ""
Write-Host "(A plain 'bash.exe' on PATH with no Git Bash found is usually the Windows/WSL"
Write-Host " launcher stub, not Git Bash -- installing Git for Windows above resolves it.)"
Write-Host ""
Write-Host "After installing, close and reopen your terminal, then re-run this script, or:"
Write-Host "  bash scripts/preflight.sh"
exit 1
