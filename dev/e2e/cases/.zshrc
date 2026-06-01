# zsh config for the preview shell (mounted via ZDOTDIR, not baked into the image,
# so edits take effect on the next render with no rebuild).
autoload -Uz colors && colors

# source the live-mounted theme; the theme mode is taken from the environment,
# so one image renders both palettes (launched as `JOVIAL_THEME_MODE=light zsh`).
source ${JOVIAL_THEME_FILE:-/work/jovial.zsh-theme}
