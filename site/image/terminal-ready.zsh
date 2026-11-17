# Zsh 5.9 refreshes the first prompt before calling zle-line-init:
# https://github.com/zsh-users/zsh/blob/zsh-5.9/Src/Zle/zle_main.c#L1342
# The browser keeps its loading screen until this signal is parsed by xterm.
autoload -Uz add-zle-hook-widget
_jovial_preview_ready() {
    printf '\033]777;jovial-ready\007'
    add-zle-hook-widget -d line-init _jovial_preview_ready
    unfunction _jovial_preview_ready
}
add-zle-hook-widget line-init _jovial_preview_ready
