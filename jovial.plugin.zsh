#
# Locale
# utf-8 to display emoji
#

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export JOVIAL_PLUGIN_VERSION='1.1.8'

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

# node for es module - enable import esm in node REPL
#   use `\node` for pure node
# (need nodejs and `npm i -g esm` )
# alias node='NODE_PATH=`npm root -g` \node -r esm'
alias tsnode='ts-node -T -O "{ \"module\": \"commonjs\" }"'

# app shortcut macOS
alias typora='open -a typora'
alias stree='/Applications/SourceTree.app/Contents/Resources/stree'

# lazygit - https://github.com/jesseduffield/lazygit
alias lg='lazygit'

# git clone but we always commonly need only one depth
alias gcl1='gcl --depth=1'

# git log time iso
alias glti='git log --pretty=fuller --date=iso'
alias glt1='glti -n 1'

# git log message raw
alias glraw='git log --format=%B -n 1'
# git log commit time raw
alias gltraw='glt1 | grep -oE "^AuthorDate:(.*)$" | cut -c 13-'

# https://stackoverflow.com/questions/89332/how-to-recover-a-dropped-stash-in-git/
alias git-find-lost="git log --oneline  \$(git fsck --no-reflogs | awk '/dangling commit/ {print \$3}')"

# similar to 'ps aux', list all processes but log custom metrics
alias psx="ps -A -o user,pid,ppid,pcpu,pmem,vsz,rss,time,etime,command"
alias psxg="psx | grep"

# 
# ########## Utils ##########
#

# git fetch and checkout to target branch
function gfco {
    local branch="$1"
    git fetch ${GIT_REMOTE:-origin} --no-tags --update-head-ok +${branch}:${branch} && gco ${branch}
}

# git fetch and rebase to target branch
function gfbi {
    local branch="$1"
    git fetch ${GIT_REMOTE:-origin} --no-tags +${branch}:${branch} && grbi ${branch}
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

    # https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables
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

    git reset HEAD~1 \
      && gaa \
      && gcmt "${last_log}" "${last_time}"
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


function zsh-theme-benchmark() {
    time (
        for i in {1..10}; do
            print -P "${PROMPT}"
        done
    )
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


# 
# ########## cheat sheet ##########
#

function sheet:shortcuts {
    # show bash/zsh shell commonly shortcuts
    echo '
    shortcuts for xterm:

      ctrl+A          ctrl+E    ─┐
      ┌─────────┬──────────┐     │
      │  alt+B  │ alt+F    │     ├─► Moving
      │  ┌──────┼────┐     │     │
      ▼  ▼      │    ▼     ▼    ─┘
    $ cp assets-|files dist/
         ◄────── ────►          ─┐
          ctrl+W alt+D           │
                                 ├─► Erasing
      ◄───────── ──────────►     │
        ctrl+U     ctrl+K       ─┘

        ctrl+/ ──► Undo
    '
}


function sheet:color {
    # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Visual-effects
    # show 256-color pattern
    local block row col fg_color bg_color
    local i
    local sgr_reset="%{${reset_color}%}"

    print -P "$(
        echo ""
        # the 16 base colors
        for i in {0..15}; do
            # use shell substitution for pad zero or space to variable
            bg_color="${${:-000${i}}:(-3)}"
            i="${${:-   ${i}}:(-3)}"
            if (( bg_color > 0 )); then
                fg_color=236
            else
                fg_color=254
            fi
            if (( i % 6 == 0 )); then
                echo -n "${sgr_reset}  "
            fi
            echo -n "${sgr_reset} %F{${fg_color}}%K{${bg_color}} $i"
        done
        echo -n "${sgr_reset}\n\n  "
        # 6 colors blocks (per 6 x 6)
        for row in {0..11}; do
            if (( row % 6 == 0 )); then
                echo -n "${sgr_reset}\n  "
            fi
            if (( (row % 6) > 2 )); then
                fg_color=236
            else
                fg_color=254
            fi
            for block in {0..2}; do
                for col in {0..5}; do
                    i=$(( 16 + (row / 6) * 36 * 3 + (row % 6) * 6 + block * 36 + col ))
                    # use shell substitution for pad zero or space to variable
                    bg_color="${${:-000${i}}:(-3)}"
                    i="${${:-   ${i}}:(-3)}"
                    echo -n "${sgr_reset} %F{${fg_color}}%K{${bg_color}} $i"
                done
                echo -n "${sgr_reset}  "
            done
            echo -n "${sgr_reset}\n  "
        done
        echo "${sgr_reset}"
        # the two lines gray level colors
        for i in {232..255}; do
            if (( (i - 16) % 12 == 0 )); then
                echo "${sgr_reset}"
            fi
            if (( (i - 16) % 6 == 0 )); then
                echo -n "${sgr_reset}  "
            fi
            if (( i > 243 )); then
                fg_color=000
            else
                fg_color=015
            fi
            echo -n "${sgr_reset} %F{${fg_color}}%K{${i}} $i"
        done
        echo "%f%k${sgr_reset}"
    )"
}
