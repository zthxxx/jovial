# Visual preview harness for jovial's light / dark palettes.
#
# It renders the prompt under a real interactive zsh running inside ttyd's
# xterm.js (driven by `vhs`), so `precmd` fires and the dev-env / git segments
# render exactly as an end user sees them -- not a static color dump.
#
# Build context is the repo root (see render.sh). The theme file is mounted live
# at /work, so re-rendering after editing the theme needs no rebuild.
FROM ghcr.io/charmbracelet/vhs

# zsh + the runtimes jovial probes, so the dev-env segment shows real versions
RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh git ca-certificates curl golang-go python3 python3-venv \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# minimal zsh config: source the live-mounted theme. the theme mode is taken from
# the environment, so one image renders both palettes by launching zsh as
# `JOVIAL_THEME_MODE=light zsh` / `JOVIAL_THEME_MODE=dark zsh`.
RUN printf '%s\n' \
      'autoload -Uz colors && colors' \
      'source ${JOVIAL_THEME_FILE:-/work/jovial.zsh-theme}' \
      > /root/.zshrc

# demo projects so the dev-env detector has something to report, plus a clean
# git repo (node-demo) to exercise the git "clean" state and colors.
RUN mkdir -p /root/Project/node-demo /root/Project/golang-demo /root/Project/python-demo \
    && touch /root/Project/node-demo/package.json \
    && printf 'module demo\n\ngo 1.21\n' > /root/Project/golang-demo/go.mod \
    && touch /root/Project/python-demo/requirements.txt \
    && python3 -m venv /root/Project/python-demo/venv \
    && git config --global user.email demo@jovial.theme \
    && git config --global user.name jovial \
    && git config --global init.defaultBranch main \
    && cd /root/Project/node-demo \
    && git init -q && git add -A && git commit -qm 'init' \
    && cd /root/Project/golang-demo \
    && git init -q && git add -A && git commit -qm 'init'

WORKDIR /work
