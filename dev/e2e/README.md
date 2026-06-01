# jovial e2e visual preview

Render the jovial prompt under both **light** and **dark** terminal backgrounds,
so the two palettes can be eyeballed side by side. Useful when tuning
`JOVIAL_PALETTE_LIGHT` / `JOVIAL_PALETTE_DARK`.

It runs a **real interactive zsh** inside ttyd's xterm.js (driven by
[`vhs`](https://github.com/charmbracelet/vhs)) within Docker, so `precmd` fires
and the dev-env / git / venv / exit-code segments render exactly as a user sees
them — not a static color dump.

## Requirements

- Docker (only). zsh, vhs, git, node, go and python all live inside the image.

## Usage

```sh
dev/e2e/render.sh          # render both light and dark
dev/e2e/render.sh light    # render a single mode
```

Outputs land in `dev/e2e/output/` (git-ignored), rendered at **2x resolution**:

- `light.gif` / `dark.gif` — the animated session
- `light.png` / `dark.png` — the final frame, for a quick still comparison

## Editing the demo without rebuilding

The Docker image installs **only** the toolchain (zsh, vhs, git, node, go,
python). The zsh config and example projects live under `cases/` and are
bind-mounted at run time, so editing them takes effect on the **next render with
no rebuild**:

```
cases/
  .zshrc                       # the preview shell config (sources the live theme)
  projects/                    # example projects the dev-env detector reports on
    node-demo/package.json
    golang-demo/go.mod
    python-demo/requirements.txt
  setup.zsh                    # runtime prep: copy projects, git init, make venv
```

Add a project, tweak `.zshrc`, or change the demo flow in the `*.tape` files,
then re-run `render.sh` — only the bind-mounted files change, the image is reused.
`setup.zsh` holds the runtime-only steps (git repos, python venv) that can't be
committed as plain files; the tapes run it once before driving the demo.

## How the mode is forced

The theme mode comes from the environment, so one image renders both palettes:
each tape launches the shell as `ZDOTDIR=…/cases JOVIAL_THEME_MODE=light zsh` (or
`dark`), which makes jovial trust the preset and skip terminal background
detection. This keeps the preview deterministic regardless of whether xterm.js
answers OSC 11 queries.

## OSC 11 detection correctness test

`osc-pty-test.py` is a fast, deterministic regression test for
`@jov.query-terminal-background` (no Docker needed — just Python 3 + zsh). It
spins up a real PTY, runs the function on the slave, and has the master act like
a terminal emulator answering the OSC 11 query. For each scenario it asserts the
resolved `JOVIAL_THEME_MODE` **and** that zero reply bytes leak into the shell
input (the bug class where the prompt gets a pre-typed `11;rgb:...` line):

```sh
python3 dev/e2e/osc-pty-test.py             # run the whole matrix
python3 dev/e2e/osc-pty-test.py jovial.zsh-theme light-bel   # one scenario
```

Scenarios cover light/dark backgrounds, both reply terminators (ST `ESC \` and
BEL), and a silent terminal (must fall back without hanging or leaking).

`colorfgbg-test.zsh` covers the zero-cost `COLORFGBG` fast path (the hint iTerm2 /
rxvt / Konsole export, which skips the OSC query). No tty needed:

```sh
zsh dev/e2e/colorfgbg-test.zsh
```

## Files

- `Dockerfile` — toolchain only (zsh + vhs + runtimes); no config/example baked in
- `cases/` — bind-mounted zsh config, example projects, and runtime `setup.zsh`
- `light.tape` / `dark.tape` — vhs scripts (background color + typed demo, 2x res)
- `render.sh` — build the image, render, and extract the still PNG
- `osc-pty-test.py` — PTY-based correctness test for OSC 11 background detection
- `colorfgbg-test.zsh` — unit test for the `COLORFGBG` fast path
