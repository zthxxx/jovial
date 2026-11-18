# FSH 4672ad5 falls back to ~/.cache if FAST_WORK_DIR is not writable and downloads a missing secondary theme.
# https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/4672ad5dd9ad68a7effc1476d65afb7c584ce2b3/fast-syntax-highlighting.plugin.zsh#L366-L377
if [[ $FAST_WORK_DIR != "$HOME/.config/fsh" || ! -w $FAST_WORK_DIR || ! -r $FAST_WORK_DIR/secondary_theme.zsh ]] ||
    (( ! ${+functions[_zsh_highlight]} )); then
    print -ru2 -- "Fast Syntax Highlighting must load with its secondary theme in $HOME/.config/fsh (work dir: $FAST_WORK_DIR)"
    exit 1
fi

# Nested command highlighting tests this key before sourcing the secondary theme.
# https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/4672ad5dd9ad68a7effc1476d65afb7c584ce2b3/fast-highlight#L896
unset 'FAST_HIGHLIGHT_STYLES[freedefault]'
if ! source "$FAST_WORK_DIR/secondary_theme.zsh" || (( ! ${+FAST_HIGHLIGHT_STYLES[freedefault]} )); then
    print -ru2 -- "$FAST_WORK_DIR/secondary_theme.zsh did not load the bundled free styles"
    exit 1
fi
