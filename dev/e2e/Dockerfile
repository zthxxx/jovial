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
        zsh git ca-certificates curl unzip golang-go python3 python3-venv \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Hack Nerd Font (referenced by the vhs tapes) is not bundled in the base image,
# so the prompt's kaomoji / glyphs render as designed.
RUN curl -fsSL -o /tmp/Hack.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip \
    && mkdir -p /usr/share/fonts/hack-nerd \
    && unzip -oq /tmp/Hack.zip -d /usr/share/fonts/hack-nerd \
    && rm /tmp/Hack.zip \
    && fc-cache -f

# pre-install zinit (the plugin manager the e2e zshrc uses), so a render never
# clones it at runtime. matches the path / partial-clone style of examples/zinit.zshrc.
ENV XDG_DATA_HOME=/root/.local/share
RUN git clone --filter=tree:0 \
        https://github.com/zdharma-continuum/zinit "${XDG_DATA_HOME}/zinit/zinit.git"

WORKDIR /work
