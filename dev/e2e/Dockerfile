# Visual preview harness for jovial's light / dark palettes.
#
# It renders the prompt under a real interactive zsh running inside ttyd's
# xterm.js (driven by `vhs`), so `precmd` fires and the dev-env / git segments
# render exactly as an end user sees them -- not a static color dump.
#
# This image installs ONLY the toolchain. The zsh config, example projects and
# their runtime setup live under dev/e2e/cases/ and are bind-mounted at run time
# (see render.sh), so editing a case takes effect on the next render with no
# rebuild. The theme file is mounted live the same way.
FROM ghcr.io/charmbracelet/vhs

# zsh + the runtimes jovial probes, so the dev-env segment shows real versions
RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh git ca-certificates curl golang-go python3 python3-venv \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
