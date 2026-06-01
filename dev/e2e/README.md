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

Outputs land in `dev/e2e/output/` (git-ignored):

- `light.gif` / `dark.gif` — the animated session
- `light.png` / `dark.png` — the final frame, for a quick still comparison

## How the mode is forced

The theme mode comes from the environment, so one image renders both palettes:
each tape launches the shell as `JOVIAL_THEME_MODE=light zsh` (or `dark`), which
makes jovial trust the preset and skip terminal background detection. This keeps
the preview deterministic regardless of whether xterm.js answers OSC 11 queries.

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

## Files

- `Dockerfile` — zsh + runtimes + demo projects; sources the live-mounted theme
- `light.tape` / `dark.tape` — vhs scripts (background color + typed demo)
- `render.sh` — build the image, render, and extract the still PNG
- `osc-pty-test.py` — PTY-based correctness test for OSC 11 background detection
