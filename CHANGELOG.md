# Changelog


## 2.1.4

### Fix

- fix progress display miss in git rebase interactive

## 2.1.3

### Fix

- fix async job rerun with wrong edge case

## 2.1.2

### Chore

- set xterm 256 color mode by default, for out-of-the-box effect in [gnu/screen](https://www.gnu.org/software/screen/) or [tmux](https://github.com/tmux/tmux)

## 2.1.1

### Fix

- remove read stdin for block subprocess,

  we found this cause zpty callback blocked in zsh v5.3

## 2.1.0

### Feat

- refactor to asynchronous update git status, now it's so fast in render and interaction. (4ms pre render)
- pin last command execute elapsed time (same as exit code).
- support custom order and affixes of each prompt parts.
- remove dependencies on `autoload -U colors` or `FG[$color]` / `BG[$color]` settings anymore, in manually load theme.

### Fix

- fix bug that rerender will eat previous line


## 2.0.3

### Fix

- force declare theme variables to global scope, compatible with use `source <jovial-theme>` in function
- support `.zshrc` as symlink in install script
- fix `rev-parse-find` function when cwd at ~/xxx/

### Chore

- remove useless git cli params in theme, and remove plugin macos in installer
- always reinstall `zsh-history-enquirer` by npm


## 2.0.0

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
