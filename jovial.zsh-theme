# jovial.zsh-theme
# https://github.com/zthxxx/jovial

# Development code style:
#
# use "@jov."" prefix for jovial internal functions, and use "kebab-case" style for function names
# use "snake_case" for function's internal variables, and declare it with "local" mark
# use "SNAKE_CASE" for global variables
# use indent spaces 4

# References:
#
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
# https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
# https://donsnotes.com/tech/charsets/ascii.html
#
# Cursor Up        <ESC>[{COUNT}A
# Cursor Down      <ESC>[{COUNT}B
# Cursor Right     <ESC>[{COUNT}C
# Cursor Left      <ESC>[{COUNT}D
# Cursor Horizontal Absolute      <ESC>[{COUNT}G

export JOVIAL_VERSION='1.1.8'

# JOVIAL_ARROW='─>'
# JOVIAL_ARROW='─▶'
local JOVIAL_ARROW='─➤'
local JOVIAL_ARROW_ON_GIT_CLEAN='(๑˃̵ᴗ˂̵)و'
local JOVIAL_ARROW_ON_GIT_DIRTY='(ﾉ˚Д˚)ﾉ'

local   JOVIAL_PROMPT_UP_CORNER='╭─'
local JOVIAL_PROMPT_DOWN_CORNER='╰─'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[102]%}on%{$reset_color%} (%{$FG[159]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
GIT_PROMPT_DIRTY_STYLE="%{$FG[202]%}✘✘✘"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[040]%}✔"


# set this flag for hidden python venv default prompt
export VIRTUAL_ENV_DISABLE_PROMPT=true

# git prompt
local JOVIAL_REV_GIT_DIR=""
local JOVIAL_IS_GIT_DIRTY=false
local JOVIAL_GIT_STATUS_PROMPT=""

@jov.iscommand() { [[ -e $commands[$1] ]] }

@jov.chpwd-git-dir-hook() { JOVIAL_REV_GIT_DIR=`\git rev-parse --git-dir 2>/dev/null` }
add-zsh-hook chpwd @jov.chpwd-git-dir-hook
@jov.chpwd-git-dir-hook

# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
# https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
@jov.unstyle-len() {
    local str="$1"
    ## regexp with PCRE mode
    ## used with `setopt RE_MATCH_PCRE`
    ## but it is not compatible with macOS Catalina default zsh version
    ## so need "brew install zsh && sudo chsh -s `command -v zsh` $USER"
    #
    # setopt RE_MATCH_PCRE
    # regexp-replace str '\e\[[0-9;]*[a-zA-Z]' ''

    ## regexp with POSIX mode
    ## compatible with macOS Catalina default zsh
    #
    ## !!! NOTE: note that the "empty space" in this regexp at the beginning is not a common "space",
    ## it is the ANSI escape ESC char ("\e") which is cannot wirte as literal in there
    regexp-replace str "\[[0-9;]*[a-zA-Z]" ''

    echo ${#str}
}

# @jov.rev-parse-find(filename:string, path:string, output:boolean)
# reverse from path to root wanna find the targe file
# output: whether show the file path
@jov.rev-parse-find() {
    local target="$1"
    local current_path="${2:-`pwd`}"
    local whether_output=${3:-false}
    local parent_path=`\dirname $current_path`
    while [[ ${parent_path} != "/" ]]; do
        if [[ -e ${current_path}/${target} ]]; then
            if $whether_output; then echo "$current_path"; fi
            return 0
        fi
        current_path="$parent_path"
        parent_path=`\dirname $parent_path`
    done
    return 1
}

@jov.venv-info-prompt() {
    [[ -n ${VIRTUAL_ENV} ]] && echo "$FG[242](%{$FG[159]%}$(basename $VIRTUAL_ENV)$FG[242])%{$reset_color%} "
}

@jov.get-host-name() { echo "[%{$FG[157]%}%m%{$reset_color%}]"; }

@jov.get-user-name() {
    local name_prefix="%{$reset_color%}"
    if [[ $USER == 'root' || $UID == 0 ]]; then
        name_prefix="%{$FG[203]%}"
    fi
    echo "${name_prefix}%n%{$reset_color%}"
}


@jov.git-prompt-info() {
    if [[ -z ${JOVIAL_REV_GIT_DIR} ]]; then return 1; fi
    local ref
    ref=$(\git symbolic-ref HEAD 2> /dev/null) \
      || ref=$(\git describe --tags --exact-match 2> /dev/null) \
      || ref=$(\git rev-parse --short HEAD 2> /dev/null) \
      || return 0
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}${JOVIAL_GIT_STATUS_PROMPT}$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

@jov.judge-git-dirty() {
    local git_status
    local -a flags
    flags=('--porcelain' '--ignore-submodules=dirty')
    if [[ "${DISABLE_UNTRACKED_FILES_DIRTY}" == "true" ]]; then
        flags+='--untracked-files=no'
    fi
    git_status=$(\git status ${flags} 2> /dev/null | tail -n1)
    if [[ -n ${git_status} ]]; then
        return 0
    else
        return 1
    fi
}

@jov.type-tip-pointer() {
    if [[ -n ${JOVIAL_REV_GIT_DIR} ]]; then
        if [[ ${JOVIAL_IS_GIT_DIRTY} == false ]]; then
            echo "${JOVIAL_ARROW_ON_GIT_CLEAN}"
        else
            echo "${JOVIAL_ARROW_ON_GIT_DIRTY}"
        fi
    else
        echo "${JOVIAL_ARROW}"
    fi
}

@jov.current-dir() {
    echo "%{$terminfo[bold]$FG[228]%}%~%{$reset_color%}"
}

@jov.get-date-time() {
    # echo "%{$reset_color%}%D %*"
    \date "+%H:%M:%S"
}

@jov.get-space-size() {
    # ref: http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    local str="$1"
    local zero_pattern='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero_pattern/}}
    local size=$(( $COLUMNS - $len + 1 ))
    echo "$size"
}

@jov.previous-align-right() {
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    local new_line_space='\n '
    local str="$1"
    local align_site=`@jov.get-space-size "$str"`
    local previous_line="\e[1A"
    local cursor_cols="\e[${align_site}G"
    echo "${previous_line}${cursor_cols}${str}${new_line_space}"
}

@jov.align-right() {
    local str="$1"
    local align_site=`@jov.get-space-size "$str"`
    local cursor_cols="\e[${align_site}G"
    echo "${cursor_cols}${str}"
}

# pin the last commad exit code at previous line end
@jov.get-pin-exit-code() {
    # because $? must be read in the first function of PROMPT, so we need it be params
    local exit_code=${1:-0}
    if [[ $exit_code != 0 ]]; then
        local exit_code_warn=" %{$FG[246]%}exit:%{$fg_bold[red]%}${exit_code}%{$reset_color%}"
        @jov.previous-align-right "$exit_code_warn"
    fi
}

@jov.prompt-node-version() {
    if @jov.rev-parse-find "package.json"; then
        if @jov.iscommand node; then
            local node_prompt_prefix="%{$FG[102]%}using%{$FG[120]%} "
            local node_prompt="node `\node -v`"
        else
            local node_prompt_prefix="%{$FG[242]%}[%{$FG[009]%}need "
            local node_prompt="Nodejs%{$FG[242]%}]"
        fi
        echo "${node_prompt_prefix}${node_prompt}%{$reset_color%}"
    fi
}

# http://php.net/manual/en/reserved.constants.php
@jov.prompt-php-version() {
    if @jov.rev-parse-find "composer.json"; then
        if @jov.iscommand php; then
            local php_prompt_prefix="%{$FG[102]%}using%{$FG[105]%} "
            local php_prompt="php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
        else
            local php_prompt_prefix="%{$FG[242]%}[%{$FG[009]%}need "
            local php_prompt="php%{$FG[242]%}]"
        fi
        echo "${php_prompt_prefix}${php_prompt}%{$reset_color%}"
    fi
}

@jov.prompt-python-version() {
    local python_prompt_prefix="%{$FG[102]%}using%{$FG[123]%} "

    if @jov.rev-parse-find "venv"; then
        local PYTHON_PROMPT=`$(@jov.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`
        echo "${python_prompt_prefix}${PYTHON_PROMPT}%{$reset_color%}"
    elif @jov.rev-parse-find "requirements.txt"; then
        if @jov.iscommand python; then
            local PYTHON_PROMPT=`\python --version 2>&1`
        else
            python_prompt_prefix="%{$FG[242]%}[%{$FG[009]%}need "
            local PYTHON_PROMPT="Python%{$FG[242]%}]"
        fi
        echo "${python_prompt_prefix}${PYTHON_PROMPT}%{$reset_color%}"
    fi
}

@jov.dev-env-segment() {
    local segment_funcs=(
        @jov.prompt-node-version
        @jov.prompt-php-version
        @jov.prompt-python-version
    )
    for segment_func in "${segment_funcs[@]}"; do
        local segment=`${segment_func}`
        if [[ -n $segment ]]; then 
            echo " $segment"
            break
        fi
    done
}

@jov.git-action-prompt() {
    # always depend on ${JOVIAL_REV_GIT_DIR} path is existed

    local action=""
    local rebase_merge="${JOVIAL_REV_GIT_DIR}/rebase-merge"
    local rebase_apply="${JOVIAL_REV_GIT_DIR}/rebase-apply"
    if [[ -d ${rebase_merge} ]]; then
        local rebase_step=`\cat "${rebase_merge}/msgnum"`
        local rebase_total=`\cat "${rebase_merge}/end"`
        local rebase_process="${rebase_step}/${rebase_total}"
        if [[ -f ${rebase_merge}/interactive ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi
    elif [[ -d ${rebase_apply} ]]; then
        local rebase_step=`\cat "${rebase_apply}/next"`
        local rebase_total=`\cat "${rebase_apply}/last"`
        local rebase_process="${rebase_step}/${rebase_total}"
        if [[ -f ${rebase_apply}/rebasing ]]; then
            action="REBASE"
        elif [[ -f ${rebase_apply}/applying ]]; then
            action="AM"
        else
            action="AM/REBASE"
        fi
    elif [[ -f ${JOVIAL_REV_GIT_DIR}/MERGE_HEAD ]]; then
        action="MERGING"
    elif [[ -f ${JOVIAL_REV_GIT_DIR}/CHERRY_PICK_HEAD ]]; then
        action="CHERRY-PICKING"
    elif [[ -f ${JOVIAL_REV_GIT_DIR}/REVERT_HEAD ]]; then
        action="REVERTING"
    elif [[ -f ${JOVIAL_REV_GIT_DIR}/BISECT_LOG ]]; then
        action="BISECTING"
    fi

    if [[ -n ${rebase_process} ]]; then
        action="$action $rebase_process"
    fi
    if [[ -n $action ]]; then
        action="|$action"
    fi

    echo "$action%{$reset_color%})"
}


@jov.git-action-prompt-hook() {
    if [[ -z ${JOVIAL_REV_GIT_DIR} ]]; then return 1; fi

    if @jov.judge-git-dirty; then
        JOVIAL_IS_GIT_DIRTY=true
    else
        JOVIAL_IS_GIT_DIRTY=false
    fi

    if [[ ${JOVIAL_IS_GIT_DIRTY} == true ]]; then
        JOVIAL_GIT_STATUS_PROMPT="$(@jov.git-action-prompt)${GIT_PROMPT_DIRTY_STYLE}"
    else
        JOVIAL_GIT_STATUS_PROMPT="$(@jov.git-action-prompt)${ZSH_THEME_GIT_PROMPT_CLEAN}"
    fi
}

local -A JOVIAL_PROMPT_FORMATS=(
    host '$(@jov.get-host-name)%{$FG[102]%} as'
    user ' $(@jov.get-user-name)%{$FG[102]%} in'
    path ' $(@jov.current-dir)'
    dev_env '$(@jov.dev-env-segment)'
    git_info ' $(@jov.git-prompt-info)'
    current_time '$(@jov.align-right " $(@jov.get-date-time)")'
)

local JOVIAL_PROMPT_PRIORITY=(
    # path
    git_info
    user
    host
    dev_env
    # current_time
)

@jovial-prompt() {
    local exit_code=$?
    local -i total_length=${#JOVIAL_PROMPT_UP_CORNER}
    local -A prompts=(
        host ''
        user ''
        path ''
        dev_env ''
        git_info ''
        current_time ''
    )

    # datetime length is fixed numbers of `${JOVIAL_PROMPT_FORMATS[current_time]}` -> ` hh:mm:ss`
    local -i len_datetime=9

    # always display current path
    prompts[path]=$(print -P "${JOVIAL_PROMPT_FORMATS[path]}")
    total_length+=$(@jov.unstyle-len "${prompts[path]}")

    for key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        local item=$(print -P "${JOVIAL_PROMPT_FORMATS[${key}]}")
        local -i item_length=$(@jov.unstyle-len "${item}")

        if (( total_length + item_length > COLUMNS )); then
            break
        fi

        total_length+=${item_length}
        prompts[${key}]="${item}"
    done

    if (( total_length + len_datetime <= COLUMNS )); then
        prompts[current_time]=$(print -P "${JOVIAL_PROMPT_FORMATS[current_time]}")
    fi

    echo "$(@jov.get-pin-exit-code ${exit_code})"
    echo   "${JOVIAL_PROMPT_UP_CORNER}${prompts[host]}${prompts[user]}${prompts[path]}${prompts[dev_env]}${prompts[git_info]}${prompts[current_time]}"
    echo "${JOVIAL_PROMPT_DOWN_CORNER}$(@jov.type-tip-pointer) $(@jov.venv-info-prompt) "
}


autoload -Uz add-zsh-hook
autoload -Uz regexp-replace

add-zsh-hook precmd @jov.git-action-prompt-hook
@jov.git-action-prompt-hook

PROMPT='$(@jovial-prompt)'
