# Changelog

> Note: you can run `echo ${JOVIAL_VERSION}` in terminal to see what version you used now.


<br />

## `jovial.zsh-theme@v2.6.0`

### Feat

- **automatic light / dark theme** based on the terminal background color. On the first prompt, jovial queries the terminal background (OSC 11) and switches between two palettes, falling back to dark when it can't be detected. Detection is performance-first (one terminal round-trip, paid once at startup; briefly toggles the tty to raw/no-echo via `stty` so the reply never leaks into the command line) and works over **SSH** and inside **Docker** (tested with iTerm2 / VSCode / Ghostty / Kitty).
  - new `JOVIAL_PALETTE_DARK` and `JOVIAL_PALETTE_LIGHT` palettes; the legacy `JOVIAL_PALETTE` is kept as a backward-compatible override slot and is migrated into both palettes.
  - set `JOVIAL_THEME_MODE=light|dark` to force a mode and skip detection entirely; tune the detect timeout with `JOVIAL_THEME_DETECT_TIMEOUT` (default `0.1`s).
  - the reply is captured with a single `sysread` (one `read(2)`), resolving a responding terminal in ~6ms; a per-byte `read` loop took ~300ms.
  - prefer the `COLORFGBG` env var when the terminal exports it (iTerm2, rxvt, Konsole): a zero-cost hint that skips the OSC query entirely — important for iTerm2, which is slow (>500ms) to answer OSC 11.
  - dev-env version tag colors moved into palette keys: `dev-env.node`, `dev-env.golang`, `dev-env.python`, `dev-env.php`.
  - added a Docker + [vhs](https://github.com/charmbracelet/vhs) visual preview harness under `dev/e2e/`.


<br />

## `jovial.zsh-theme@v2.5.5`

### Fix

- override to `TERM=xterm-256color` when original is 'TERM=xterm' for default colorful compatibility


### `jovial.plugin@v1.2.1`

- fix: resolve **Locale** issue where the host lacks `en_US.UTF-8` but use another UTF-8 locale. `jovial.plugin` will no longer change the locale in such cases.


<br />

## `jovial.zsh-theme@v2.5.4`

### Fix

- fix git status hint for `git am` (apply a series of patches)

### `jovial.plugin@v1.2.0`

- feat: exchange position of args for `gcmt` function (git commit with modified time) for more **intuitively**
- fix: keep committer date when `gfbi`, show signature when `glti`


<br />

## `jovial.zsh-theme@v2.5.3`

### Feat

- git status in prompt work with submodules now

### `jovial.plugin@v1.1.9`

- support update submodules in git fetch and checkout function `gfco`
- adjust comments of functions, design to show comments in `where xxx` or `which xxx`
- remove functions `stree` (support by official), and `py2venv` (migrated to `venv --py2`)

<br />

## `jovial.zsh-theme@v2.5.2`

### Feat

- support show python3 version in prompt

### `jovial.plugin@v1.1.8`

- add variable `GIT_REMOTE` to support in git fetch function `gfco` and `gfbi`


<br />

## v2.5.1

### Fix

- migrate `path` part in `JOVIAL_AFFIXES` config named to `current-dir`,
  
  to fix the bug that causes responsive style error due to `path` part.

example in `.zshrc`:
```diff
- JOVIAL_AFFIXES[path]='%1~'
+ JOVIAL_AFFIXES[current-dir]='%1~'
```

<br />

## v2.5.0 [_@deprecated_]

### Feat

- support the ability to override the prompt for `path` part in `.zshrc`.

example in `.zshrc`:
```zsh
# @deprecated use `JOVIAL_AFFIXES[current-dir]` in v2.5.1
JOVIAL_AFFIXES[path]='%1~'
```

<br />

## v2.4.0

### Feat

- support the ability to override the prompt parts for `hostname` and `username` in `.zshrc`.

example:
```zsh
JOVIAL_AFFIXES[hostname]='MacbookPro'
JOVIAL_AFFIXES[username]='zthxxx'
```


<br />

## v2.3.1

### Chore

- will no longer override var `TERM=xterm-256color` except in default `screen` command. [#23](https://github.com/zthxxx/jovial/issues/23)


<br />


## v2.3.0

### Feat & Docs

- add docs for support use with [`antigen`](https://github.com/zsh-users/antigen)
- no need setopt in .zshrc anymore for manually install like antigen


<br />


## v2.2.1

### Fix

- fix reset style (`sgr_reset`) in manually used without `oh-my-zsh` or `zmodload zsh/colors`

<br />


## v2.2.0

### Style

- add default color for typing-pointer and customization, darken the normal color

<br />


## v2.1.4

### Fix

- fix progress display miss in git rebase interactive

<br />


## v2.1.3

### Fix

- fix async job rerun with wrong edge case

<br />


## v2.1.2

### Chore

- set xterm 256 color mode by default, for out-of-the-box effect in [gnu/screen](https://www.gnu.org/software/screen/) or [tmux](https://github.com/tmux/tmux)

<br />


## v2.1.1

### Fix

- remove read stdin for block subprocess,

  we found this cause zpty callback blocked in zsh v5.3

<br />


## v2.1.0

### Perf

- refactor to asynchronous update git status, now it's so fast in render and interaction. (4ms pre render)

### Feat

- pin last command execute elapsed time (same as exit code).
- support custom order and affixes of each prompt parts.
- remove dependencies on `autoload -U colors` or `FG[$color]` / `BG[$color]` settings anymore, in manually load theme.

### Fix

- fix bug that rerender will eat previous line

<br />


## v2.0.3

### Fix

- force declare theme variables to global scope, compatible with use `source <jovial-theme>` in function
- support `.zshrc` as symlink in install script
- fix `rev-parse-find` function when cwd at ~/xxx/

### Chore

- remove useless git cli params in theme, and remove plugin macos in installer
- always reinstall `zsh-history-enquirer` by npm

<br />


## v2.0.0

### Feat

- support easy to custom jovial's colors and symbols

### Refactor

- refactor installer, more readable logs and support proxy env
- adjust code style, reduce subprocess call for performance
- rename osx plugin to macos, follows oh-my-zsh updated

### BREAKING CHANGE

There are some breaking changes for customization,

some customized variables and functions renamed:

- variable `JOVIAL_ARROW` => `JOVIAL_SYMBOL[arrow]`
- function `_jov_type_tip_pointer` => `@jov.typing-pointer`,
- and now, arrows could replace with variables `JOVIAL_SYMBOL[arrow.git-clean]` and `JOVIAL_SYMBOL[arrow.git-dirty]`
- some keys in ` JOVIAL_PROMPT_PRIORITY` renamed, `git_info` => `git-info`, `dev_env` => `dev-env`
