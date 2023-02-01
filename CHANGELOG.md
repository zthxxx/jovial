# Changelog

> Note: you can run `echo ${JOVIAL_VERSION}` in terminal to see what version you used now.



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
