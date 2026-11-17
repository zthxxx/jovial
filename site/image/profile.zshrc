autoload -Uz add-zsh-hook add-zle-hook-widget
add-zsh-hook precmd _jovial_profile_precmd_start
source "$ZDOTDIR/${JOVIAL_PROFILE_MODE}.zsh"
source "$HOME/.config/jovial-preview.zsh"
add-zsh-hook precmd _jovial_profile_precmd_end
add-zle-hook-widget line-init _jovial_profile_finished
cd "$HOME/Project"
