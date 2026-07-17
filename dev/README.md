# jovial dev & test stack

All entry points live in the repo-root [`Taskfile.yaml`](../Taskfile.yaml)
(run with [go-task](https://taskfile.dev)) and are **isomorphic** across a
local shell, the docker e2e container, and GitHub CI
([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) — the same
`task <name>` reproduces any CI job locally.

```sh
task            # list all tasks
task test       # lint + unit + pty + integration, all local, no docker
task e2e        # the same `task test` inside an isolated docker container
task preview    # render the vhs previews (light / dark / detect)
task bench      # time 10 prompt renders of the working tree
task dev:link   # symlink the working tree into the host zinit / oh-my-zsh
```

## Directory layout (grouped by test type)

```
dev/
  cases/          shared fixtures, bind-mounted into docker at run time:
                  preview shell config (.zshrc), git identity (gitconfig),
                  example projects, and their runtime setup (setup.zsh)
  unit/           layer 1 -- pure-zsh unit tests, no tty needed
  integration/    layer 2 -- real-PTY tests (function matrix + full sessions)
  e2e/            layer 3 -- docker compose isolation wrapper around `task test`
  preview/        vhs tapes + render harness (+ legacy manual-preview scripts)
  benchmark.zsh   local render benchmark          (task bench)
  dev-link.zsh    live-link working tree to host  (task dev:link)
  dev-unlink.zsh  restore the installed files     (task dev:unlink)
```

## Layer 1 — lint & unit (`task lint`, `task test:unit`)

`zsh -n` syntax checks, then `unit/theme-unit-test.zsh` exercises every
detection helper in isolation: OSC 11 reply parsing (incl. single-hex-digit
channel scaling), reply-vs-typeahead splitting, worker palette-token
substitution, the `JOVIAL_THEME_DETECT_TIMEOUT` env preset, non-interactive
shells doing env checks only, the palette-migration once-guard, and
`init-affix` idempotency. `unit/colorfgbg-test.zsh` covers the zero-cost
`COLORFGBG` fast path.

## Layer 2 — integration on a real PTY (`task test:pty`, `task test:integration`)

`integration/osc-pty-test.py` drives the synchronous query primitive
(`@jov.query-terminal-background`) on a PTY whose master answers like a
terminal emulator: light/dark, both reply terminators (ST / BEL), an
OSC-11-less terminal (DA1 sentinel, no wait), a silent terminal (bounded by
the env-preset timeout), and laggy links — asserting the mode, zero input
leak, and the timing invariants.

`integration/session-test.py` goes one level up and drives **full interactive
sessions** (`zsh -i` + the theme loaded from ZDOTDIR), one scenario per
behavior around the core contract — *the first paint budget is a hard cap,
and everything slow races in parallel inside it*: stderr stays visible,
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
python3 dev/integration/osc-pty-test.py jovial.zsh-theme                  # whole matrix
python3 dev/integration/session-test.py jovial.zsh-theme late-reply-guard # one scenario
```

## Layer 3 — e2e isolation (`task e2e`)

`e2e/compose.yaml` + `e2e/Dockerfile` run the whole `task test` pipeline in a
slim container (zsh + python3 + go-task), fully isolated from the host:

- the repo is mounted **read-only**: tests can't touch the working tree
- `network_mode: none`: nothing can leave the container at run time
- fresh container HOME / tmp: no interference from — or with — the host shell

## Preview rendering (`task preview`)

`preview/render.sh` runs a **real interactive zsh** inside ttyd's xterm.js
(driven by [vhs](https://github.com/charmbracelet/vhs)) within Docker, so
`precmd` fires and the dev-env / git / venv / exit-code segments render
exactly as a user sees them. Outputs land in `dev/preview/output/`
(git-ignored) at 2x resolution as `{light,dark,detect}.{gif,png}`; on CI they
are uploaded as the `vhs-previews` artifact so reviewers can eyeball them.

- `light.tape` / `dark.tape` — palette previews; both `Source` the shared
  demo flow in `preview-steps.tape` and differ only in `Output` /
  `Set Theme` / `Env JOVIAL_THEME_MODE`
- `detect.tape` — launches WITHOUT a preset mode on a light background: its
  `Wait+Screen` assertions only pass when the real OSC 11 round-trip resolved
  `mode=light` (dark is the fallback), stderr still prints, and input typed
  before the first prompt was replayed — a true end-to-end check
- the preview image (`preview/Dockerfile`) bakes only the toolchain (zsh, vhs,
  runtimes, zinit, Hack Nerd Font); the shell config and example projects are
  bind-mounted from `dev/cases/`, so editing a case needs **no rebuild**

## Shared fixtures — `dev/cases/`

Everything docker mounts as configuration lives here, reused by the preview
tapes (and open to other harnesses): `.zshrc` (zinit + jovial only, loading
the live-mounted theme from `/work`), `gitconfig` (mounted via
`GIT_CONFIG_GLOBAL`), `projects/` (dev-env detection samples), and
`setup.zsh` (runtime-only prep: git repos, python venv).
