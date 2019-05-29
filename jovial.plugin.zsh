#
# Locale
# utf-8 to display emoji
#

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


#
# Aliases
#

alias pxy='proxychains4'

alias py='python'
alias py3='python3'
alias ipy='ipython'
alias jpy='jupyter notebook'
alias act='source activate'
alias deact='source deactivate'

alias typora='open -a typora'
alias stree='/Applications/SourceTree.app/Contents/Resources/stree'


function gcmt {
    if [[ -z $2 ]]; then
        echo "gcmt - git commit with specified datetime"
        echo "Usage: gcmt <commit-message> <commit-time>"
        return
    fi

    GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" gcmsg "$1"
}


function gmct() {
    if [[ -z $2 ]]; then
        echo "gmct - git modify history commit date with specified datetime"
        echo "Usage: gmct <commit-id> <commit-time> [commit-time] [commit-time] ..."
        return
    fi

    local commit="$1"
    shift

    GIT_SEQUENCE_EDITOR='perl -i -pe "s/^pick /edit /"' git rebase -i ${commit}~1

    while [[ -e .git/rebase-merge ]]; do
        if [[ -n $1 ]]; then
            local datetime="$1"
            GIT_COMMITTER_DATE="${datetime}" git commit --amend --no-edit --date="${datetime}"
            shift
        else
            GIT_COMMITTER_DATE=`
                git log --pretty=fuller --date=iso -n 1 \
                | grep -oE '(?:AuthorDate)(.*)' \
                | cut -c 13-
                ` \
                git commit --amend --no-edit
        fi
        git rebase --continue
    done
}


# python3 venv
function venv {
    if [[ -n ${VIRTUAL_ENV} ]]; then
        deactivate;
        return
    fi

    if [[ -d venv ]]; then
        . venv/bin/activate;
    else
        python3 -m venv venv && venv;
    fi
}


# bgnotify setting
bgnotify_threshold=4

function bgnotify_formatted {
    # zsh plugin bgnotify
    # args: (exit_status, command, elapsed_seconds)
    elapsed="$(( $3 % 60 ))s"
    (( $3 >= 60 )) && elapsed="$((( $3 % 3600) / 60 ))m $elapsed"
    (( $3 >= 3600 )) && elapsed="$(( $3 / 3600 ))h $elapsed"
    [[ $1 == 0 ]] && bgnotify "🎉 Success ($elapsed)" "$2" || bgnotify "💥 Failed ($elapsed)" "$2"
}

# ssh util `to`
function to {
    local comment="
      command: to - ssh with agent forward to login and su to root
      usage: to <ip> [port]

      options:
        set those local env below in .bashrc or .zshrc or other

        local TO_SSH_AGENT
        local TO_SSH_USERNAME
        local TO_SSH_PASSWORD

      config TO_SSH_AGENT name in ~/.ssh/config
      also make sure username and password without space/quote
    "
    local agent="${TO_SSH_AGENT}"
    local target_user="${TO_SSH_USERNAME}"
    local password="${TO_SSH_PASSWORD}"

    local target_host="${1}"
    local target_port="${2}"

    if [[ -z ${target_host} ]]; then
        echo "${comment}";
        return
    fi

    if [[ -n ${target_user} ]]; then
        target_host="${target_user}@${target_host}"
    fi

    if [[ -n ${target_port} ]]; then
        target_port="-p ${target_port}"
    fi

    # cannot use quote, space or '$' in expect tcl command, so its need escape
    if [[ -n ${agent} ]]; then
        agent="-o ProxyCommand=ssh\ -W\ %h:%p\ ${agent}"
    fi

    expect -c "
        trap {
          set rows [stty rows]
          set cols [stty columns]
          stty rows \$rows columns \$cols < \$spawn_out(slave,name)
        } WINCH

        spawn ssh -A ${agent} ${target_host} ${target_port}
        expect {
            "yes/no"    {send yes; send \n; exp_continue}
            "password"  {send "${password}"; send \n; exp_continue}
            "${target_user}"    {send \"exec sudo su -\"; send \n}
        }
        expect "password" {send "${password}"; send \n}
        interact
    "
}


# https://superuser.com/questions/71588/how-to-syntax-highlight-via-less
LESSPIPE=`((which src-hilite-lesspipe.sh > /dev/null && which src-hilite-lesspipe.sh) || (dpkg -L libsource-highlight-common | grep lesspipe)) 2> /dev/null`
if [[ -n ${LESSPIPE} && -e ${LESSPIPE} ]]; then
    export LESSOPEN="| ${LESSPIPE} %s"
    export LESS=' -R -X -F '
fi
