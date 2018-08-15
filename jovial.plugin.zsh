#
# Aliases
#
alias py='python'
alias ipy='ipython'
alias jpy='jupyter notebook'
alias venv='. venv/bin/activate'
alias pxy='proxychains4'
alias typora='open -a typora'


# bgnotify setting
bgnotify_threshold=4

function bgnotify_formatted {
    # zsh plugin bgnotify
    # args: (exit_status, command, elapsed_seconds)
    elapsed="$(( $3 % 60 ))s"
    (( $3 >= 60 )) && elapsed="$((( $3 % 3600) / 60 ))m $elapsed"
    (( $3 >= 3600 )) && elapsed="$(( $3 / 3600 ))h $elapsed"
    [ $1 -eq 0 ] && bgnotify "🎉 success - elapse $elapsed" "$2" || bgnotify "💥 failed - elapse $elapsed" "$2"
}
