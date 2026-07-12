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
  .zshrc                       # preview shell config: zinit + jovial only, no
                               # other plugins (based on examples/zinit.zshrc),
                               # loading the live-mounted theme from /work
  gitconfig                    # git identity used for the demo commits (mounted
                               # via GIT_CONFIG_GLOBAL, not generated at runtime)
  projects/                    # example projects the dev-env detector reports on
    node-demo/package.json
    golang-demo/go.mod
    python-demo/requirements.txt
  setup.zsh                    # runtime prep: copy projects, git init, make venv
```

`zinit` itself is pre-installed in the image (see the Dockerfile), so a render
never clones it at run time.

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

## Detection correctness suite (isolated, three layers)

Everything below runs together, fully isolated from the host environment, via
docker compose (repo mounted **read-only**, `network_mode: none`):

```sh
dev/e2e/check.sh          # == docker compose -f dev/e2e/compose.yaml run --build --rm check
```

or individually on any machine with zsh + python3 (no docker needed):

**Layer 1 — unit tests, no tty.** `theme-unit-test.zsh` exercises every
detection helper in isolation: OSC 11 reply parsing (incl. single-hex-digit
channel scaling), reply-vs-typeahead splitting, the
`JOVIAL_THEME_DETECT_TIMEOUT` env preset, non-interactive shells doing env
checks only, the palette-migration once-guard, and `init-affix` idempotency.
`colorfgbg-test.zsh` covers the zero-cost `COLORFGBG` fast path.

```sh
zsh dev/e2e/theme-unit-test.zsh
zsh dev/e2e/colorfgbg-test.zsh
```

**Layer 2 — real PTY.** `osc-pty-test.py` drives the synchronous query
primitive (`@jov.query-terminal-background`) on a PTY whose master answers like
a terminal emulator: light/dark, both reply terminators (ST / BEL), an
OSC-11-less terminal (DA1 sentinel, no wait), a silent terminal (bounded by the
env-preset timeout), and laggy links — asserting the mode, zero input leak, and
the timing invariants. `session-test.py` goes one level up and drives **full
interactive sessions** (`zsh -i` + the theme loaded from ZDOTDIR), one scenario
per behavior around the core contract -- *the first paint budget is a hard
cap, and everything slow races in parallel inside it*: stderr stays visible,
typeahead is replayed, a slower-than-budget reply is swallowed + self-corrects
the palette, the query round-trip overlaps `~/.zshrc`, the budget env preset
is honored, ^C during the wait leaves a working shell, a mute terminal costs
exactly one budget, a fast git check renders synchronously on the first paint
while a slow one joins via rerender, a mute terminal + a slow git together
still cost ONE budget (waits share the deadline, they never stack), the
dev-env segment carries palette colors on the very first paint (workers bake
palette tokens, resolved at compose time), a non-interactive shell does env
checks only, and COLORFGBG / preset send no query at all.

```sh
python3 dev/e2e/osc-pty-test.py jovial.zsh-theme                  # whole matrix
python3 dev/e2e/session-test.py jovial.zsh-theme late-reply-guard # one scenario
```

**Layer 3 — real terminal emulator.** `detect.tape` (rendered by `render.sh`)
launches the themed shell in ttyd's xterm.js **without** a preset mode on a
light background: its `Wait+Screen` assertions only pass when the real OSC 11
round-trip resolved `mode=light` (dark is the fallback), stderr still prints,
and input typed before the first prompt was replayed.

## Files

- `Dockerfile` — preview toolchain (zsh + vhs + runtimes + zinit + Hack Nerd
  Font); no config/example baked in
- `Dockerfile.check` / `compose.yaml` / `check.sh` / `run-checks.zsh` — the
  isolated correctness suite (slim zsh + python3 image, read-only repo mount,
  no network)
- `cases/` — bind-mounted zsh config (zinit + jovial), example projects, `setup.zsh`
- `light.tape` / `dark.tape` — vhs scripts (background color + typed demo, 2x res)
- `detect.tape` — vhs script asserting real OSC 11 detection + stderr canary +
  typeahead replay
- `render.sh` — build the image, render the tapes, and extract the still PNGs
- `theme-unit-test.zsh` — unit tests for the detection helpers
- `osc-pty-test.py` — PTY-based correctness test for the query primitive
- `session-test.py` — interactive-session scenarios, one per detection behavior
- `colorfgbg-test.zsh` — unit test for the `COLORFGBG` fast path
