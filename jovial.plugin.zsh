#
# Locale
# utf-8 to display emoji
#

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


#
# ########## Aliases ##########
#

alias pxy='proxychains4'

alias py='python'
alias py3='python3'
alias ipy='ipython'
alias jpy='jupyter notebook'
alias act='source activate'
alias deact='source deactivate'

# node es module
# enable import esm in node REPL
# need nodejs and `npm i -g esm` 
alias node='NODE_PATH=`npm root -g` \node -r esm'
alias tnode='NODE_PATH=`npm root -g` \node -r ts-node/register'
alias tsnode='ts-node'

# app shortcut macOS
alias typora='open -a typora'
alias stree='/Applications/SourceTree.app/Contents/Resources/stree'

# git log time iso
alias glti='git log --pretty=fuller --date=iso'
alias glt1='glti -n 1'

# git log message raw
alias glraw='git log --format=%B -n 1'
# git log commit time raw
alias gltraw='glt1 | grep -oE "(?:AuthorDate)(.*)" | cut -c 13-'

# https://stackoverflow.com/questions/89332/how-to-recover-a-dropped-stash-in-git/
alias git-find-lost="git log --oneline  \$(git fsck --no-reflogs | awk '/dangling commit/ {print \$3}')"


# 
# ########## Utils ##########
#

# git fetch and checkout to target branch
function gfco {
    local branch="$1"
    gfo --no-tags +${branch}:${branch} && gco ${branch}
}

# git fetch and rebase to target branch
function gfbi {
    local branch="$1"
    gfo --no-tags +${branch}:${branch} && grbi ${branch}
}

# git delete and checkout -b to target branch
# ensure that overwrite current ref to target branch name
function gDcb {
    local branch="$1"
    gbD ${branch} 2>/dev/null
    gco -b ${branch}
}

# git commit modify time
function gcmt {
    if [[ -z $2 ]]; then
        echo "gcmt - git commit with specified datetime"
        echo "Usage: gcmt <commit-message> <commit-time>"
        return
    fi

    GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" gcmsg "$1"
}

# git modify commits time
function gmct {
    if [[ -z $2 ]]; then
        echo "gmct - git modify history commit date with specified datetime"
        echo "Usage: gmct <commit-id> <commit-time> [commit-time] [commit-time] ..."
        return
    fi

    local commit="$1"
    shift

    GIT_SEQUENCE_EDITOR='perl -i -pe "s/^pick /edit /"' git rebase -i "${commit}~1"

    while [[ -e .git/rebase-merge ]]; do
        if [[ -n $1 ]]; then
            local commit_time="$1"
            GIT_COMMITTER_DATE="${commit_time}" git commit --amend --no-edit --date="${commit_time}"
            shift
        else
            GIT_COMMITTER_DATE=`gltraw` git commit --amend --no-edit
        fi
        git rebase --continue
    done
}


# git re-commit
# reset & commit last-commit
function grclast {
    local last_log=`glraw`
    local last_time=`gltraw`
    if [[ -n $1 ]]; then
        last_time="$1"
    fi

    git reset HEAD~1
    gaa
    gcmt "${last_log}" "${last_time}"
}


# create or enable python venv
# $ venv  # -> python3 venv
# $ venv --py2 # -> python2 virtualenv
function venv {
    if [[ -n ${VIRTUAL_ENV} ]]; then
        deactivate
        return
    fi

    if [[ -d venv ]]; then
        . venv/bin/activate
        return
    fi

    # if not exist venv dir, create a new one before enable it
    if [[ $1 == --py2 ]]; then
        python2 -m virtualenv venv
    else
        python3 -m venv venv
    fi

    [[ $? == 0 ]] && venv
}

function py2venv {
    if [[ -n ${VIRTUAL_ENV} ]]; then
        deactivate
        return
    fi

    if [[ -d venv ]]; then
        . venv/bin/activate
    else
        python2 -m virtualenv venv && py2venv
    fi
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
        echo "${comment}"
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


# 
# ########## App Config ##########
#

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

# https://superuser.com/questions/71588/how-to-syntax-highlight-via-less
LESSPIPE=`((which src-hilite-lesspipe.sh > /dev/null && which src-hilite-lesspipe.sh) || (dpkg -L libsource-highlight-common | grep lesspipe)) 2> /dev/null`
if [[ -n ${LESSPIPE} && -e ${LESSPIPE} ]]; then
    export LESSOPEN="| ${LESSPIPE} %s"
    export LESS=' -R -X -F '
fi

# print 256-color pattern
function colorsheet {
    local block row col fg_color bg_color
    local i

    print -P "$(
        echo -n '\n'

        # the 16 base colors
        for i in {0..15}; do
            # use shell substitution for pad zero or space to variable
            bg_color="${${:-000${i}}:(-3)}"
            i="${${:-   ${i}}:(-3)}"

            if (( bg_color > 0 )); then
                fg_color=000
            else
                fg_color=015
            fi

            if (( i % 6 == 0 )); then
                echo -n "${reset_color}  "
            fi

            echo -n "${reset_color} ${FG[${fg_color}]}${BG[${bg_color}]} $i"
        done

        echo -n "${reset_color}\n\n  "

        # 6 colors blocks (per 6 x 6)
        for row in {0..11}; do
            if (( row % 6 == 0 )); then
                echo -n "${reset_color}\n  "
            fi

            if (( (row % 6) > 2 )); then
                fg_color=000
            else
                fg_color=015
            fi

            for block in {0..2}; do
                for col in {0..5}; do
                    i=$(( 16 + (row / 6) * 36 * 3 + (row % 6) * 6 + block * 36 + col ))

                    # use shell substitution for pad zero or space to variable
                    bg_color="${${:-000${i}}:(-3)}"
                    i="${${:-   ${i}}:(-3)}"

                    echo -n "${reset_color} ${FG[${fg_color}]}${BG[${bg_color}]} $i"
                done

                echo -n "${reset_color}  "
            done

            echo -n "${reset_color}\n  "
        done

        echo -n "\n"

        # the two lines gray level colors
        for i in {232..255}; do
            if (( (i - 16) % 12 == 0 )); then
                echo -n "\n"
            fi
            if (( (i - 16) % 6 == 0 )); then
                echo -n "${reset_color}  "
            fi

            if (( i > 243 )); then
                fg_color=000
            else
                fg_color=015
            fi

            echo -n "${reset_color} ${FG[${fg_color}]}${BG[$i]} $i"
        done
    )"
}
