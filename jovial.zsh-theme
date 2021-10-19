# jovial.zsh-theme
# https://github.com/zthxxx/jovial

autoload -Uz add-zsh-hook

# Development code style:
#
# use "@jov."" prefix for jovial internal functions
# use "kebab-case" style for function names and mapping key
# use "snake_case" for function's internal variables, and declare it with "local" mark
# use "SNAKE_CASE" for global variables
# use indent spaces 4


export JOVIAL_VERSION='2.0.3'

# jovial theme element symbol mapping
#
# (the syntax `typeset -A xxx` is means to declare a `associative-array` in zsh, it's like `dictionary`)
typeset -gA JOVIAL_SYMBOL=(
    corner.top    '╭─'
    corner.bottom '╰─'

    git.dirty '✘✘✘'
    git.clean '✔'

    ## preset arrows
    # arrow '─>'
    # arrow '─▶'
    arrow '─➤'
    arrow.git-clean '(๑˃̵ᴗ˂̵)و'
    arrow.git-dirty '(ﾉ˚Д˚)ﾉ'
)

# jovial theme colors mapping
# use `sheet:color` plugin function to see color table
typeset -gA JOVIAL_PALETTE=(
    # hostname
    host "${FG[157]}"

    # common user name
    user "${FG[255]}"

    # only root user
    root "${terminfo[bold]}${FG[203]}"

    # current work dir path
    path "${terminfo[bold]}${FG[228]}"

    # git status info (dirty or clean / rebase / merge / cherry-pick)
    git "${FG[159]}"

    # virtual env activate prompt for python
    venv "${FG[159]}"
 
    # time tip at end-of-line
    time "${FG[254]}"

    # exit code of last command
    exit.mark "${FG[246]}"
    exit.code "${terminfo[bold]}${FG[203]}"

    # "conj.": short for "conjunction", like as, at, in, on, using
    conj. "${FG[102]}"

    # for other common case text color
    normal "${FG[253]}"

    success "${FG[040]}"
    error "${FG[203]}"
)


# set this flag for hidden python venv default prompt
export VIRTUAL_ENV_DISABLE_PROMPT=true

# variables for git prompt
typeset -g JOVIAL_REV_GIT_DIR=""
typeset -g JOVIAL_IS_GIT_DIRTY=false


# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
# https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
@jov.unstyle-len() {
    # remove vcs_info mark like "%{", "%}", it is used in `print -P``
    local str="${1//\%[\{\}]/}"

    ## regexp with POSIX mode
    ## compatible with macOS Catalina default zsh
    #
    ## !!! NOTE: note that the "empty space" in this regexp at the beginning is not a common "space",
    ## it is the ANSI escape ESC char ("\e") which is cannot wirte as literal in there
    local unstyle_regex="\[[0-9;]*[a-zA-Z]"

    # inspired by zsh builtin regexp-replace
    # https://github.com/zsh-users/zsh/blob/zsh-5.8/Functions/Misc/regexp-replace
    # it same as next line
    # regexp-replace str "${unstyle_regex}" ''

    local unstyled
    # `MBEGIN` `MEND` are zsh builtin variables
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html

    while [[ -n ${str} ]]; do
        if [[ ${str} =~ ${unstyle_regex} ]]; then
            # append initial part and subsituted match
            unstyled+=${str[1,MBEGIN-1]}
            # truncate remaining string
            str=${str[MEND+1,-1]}
        else
            break
        fi
    done
    unstyled+=${str}

    echo ${#unstyled}
}


# @jov.rev-parse-find(filename:string, path:string, output:boolean)
# reverse from path to root wanna find the targe file
# output: whether show the file path
@jov.rev-parse-find() {
    local target="$1"
    local current_path="${2:-$PWD}"
    local whether_output=${3:-false}

    local root_regex='^(/)[^/]*$'
    local dirname_regex='^((/[^/]+)+)/[^/]+/?$'

    # [hacking] it's same as  parent_path=`\dirname $current_path`,
    # but better performance due to reduce subprocess call
    # `match` is zsh builtin variable
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html
    if [[ ${current_path} =~ ${root_regex} || ${current_path} =~ ${dirname_regex} ]]; then
        local parent_path="${match[1]}"
    else
        return 1
    fi

    while [[ ${parent_path} != "/" && ${current_path} != "${HOME}" ]]; do
        if [[ -e ${current_path}/${target} ]]; then
            if ${whether_output}; then echo "$current_path"; fi
            return 0
        fi
        current_path="$parent_path"

        # [hacking] it's same as  parent_path=`\dirname $parent_path`,
        # but better performance due to reduce subprocess call
        if [[ ${parent_path} =~ ${root_regex} || ${parent_path} =~ ${dirname_regex} ]]; then
            parent_path="${match[1]}"
        else
            return 1
        fi
    done
    return 1
}


@jov.iscommand() { [[ -e $commands[$1] ]] }

@jov.chpwd-git-dir-hook() {
    # it's the same as  JOVIAL_REV_GIT_DIR=`\git rev-parse --git-dir 2>/dev/null`
    # but better performance due to reduce subprocess call

    local project_root_dir="$(@jov.rev-parse-find .git '' true)"

    if [[ -n ${project_root_dir} ]]; then
        JOVIAL_REV_GIT_DIR="${project_root_dir}/.git"
    else
        JOVIAL_REV_GIT_DIR=""
    fi
}

add-zsh-hook chpwd @jov.chpwd-git-dir-hook
@jov.chpwd-git-dir-hook


@jov.typing-pointer() {
    if [[ -n ${JOVIAL_REV_GIT_DIR} ]]; then
        if [[ ${JOVIAL_IS_GIT_DIRTY} == false ]]; then
            echo -n "${JOVIAL_SYMBOL[arrow.git-clean]}"
        else
            echo -n "${JOVIAL_SYMBOL[arrow.git-dirty]}"
        fi
    else
        echo -n "${JOVIAL_SYMBOL[arrow]}"
    fi
}

@jov.venv-info-prompt() {
    [[ -z ${VIRTUAL_ENV} ]] && return 0
    echo "${JOVIAL_PALETTE[normal]}(${JOVIAL_PALETTE[venv]}$(basename $VIRTUAL_ENV)${JOVIAL_PALETTE[normal]}) "
}

@jov.get-host-name() {
    echo "${JOVIAL_PALETTE[host]}%m"
}

@jov.get-user-name() {
    local name_prefix="${JOVIAL_PALETTE[user]}"
    if [[ $USER == 'root' || $UID == 0 ]]; then
        name_prefix="${JOVIAL_PALETTE[root]}"
    fi
    echo "${name_prefix}%n"
}

@jov.current-dir() {
    echo "${JOVIAL_PALETTE[path]}%~"
}

@jov.get-date-time() {
    echo -n "${JOVIAL_PALETTE[time]}"
    \date "+%H:%M:%S"
}

@jov.get-space-size() {
    local str="$1"
    local len=$(@jov.unstyle-len "$str")
    local size=$(( $COLUMNS - $len + 1 ))
    echo "$size"
}

@jov.previous-align-right() {
    # References:
    #
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
    # https://donsnotes.com/tech/charsets/ascii.html
    #
    # Cursor Up        <ESC>[{COUNT}A
    # Cursor Down      <ESC>[{COUNT}B
    # Cursor Right     <ESC>[{COUNT}C
    # Cursor Left      <ESC>[{COUNT}D
    # Cursor Horizontal Absolute      <ESC>[{COUNT}G

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
        local exit_code_warn="${JOVIAL_PALETTE[exit.mark]}exit:${JOVIAL_PALETTE[exit.code]}${exit_code}"
        @jov.previous-align-right " ${exit_code_warn} "
    fi
}

typeset -gi JOVIAL_PROMPT_RUN_COUNT=0
@jov.pin-exit-code() {
    local exit_code=$?

    JOVIAL_PROMPT_RUN_COUNT+=1

    # donot print empty line when prompt initial load, if terminal height less than 10 lines
    if (( JOVIAL_PROMPT_RUN_COUNT == 1 )) && (( LINES <= 10 )); then
        return 0
    fi

    print -P "${SGR_RESET}$(@jov.get-pin-exit-code ${exit_code})"
}

add-zsh-hook precmd @jov.pin-exit-code


@jov.prompt-node-version() {
    if @jov.rev-parse-find "package.json"; then
        if @jov.iscommand node; then
            local node_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "
            local node_prompt="${FG[120]}node `\node -v`"
        else
            local node_prompt_prefix="${JOVIAL_PALETTE[normal]}[${JOVIAL_PALETTE[error]}need "
            local node_prompt="Nodejs${JOVIAL_PALETTE[normal]}]"
        fi
        echo "${node_prompt_prefix}${node_prompt}"
    fi
}

@jov.prompt-golang-version() {
    if @jov.rev-parse-find "go.mod"; then
        if @jov.iscommand go; then
            local go_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "
            # go version go1.7.4 linux/amd64
            local go_version=`go version`
            if [[ ${go_version} =~ ' go([0-9]+\.[0-9]+\.[0-9]+) ' ]]; then
                go_version="${match[1]}"
            else
                return 1
            fi
            local go_prompt="${FG[086]}Golang ${go_version}"
        else
            local go_prompt_prefix="${JOVIAL_PALETTE[normal]}[${JOVIAL_PALETTE[error]}need "
            local go_prompt="Golang${JOVIAL_PALETTE[normal]}]"
        fi
        echo "${go_prompt_prefix}${go_prompt}"
    fi
}

# http://php.net/manual/en/reserved.constants.php
@jov.prompt-php-version() {
    if @jov.rev-parse-find "composer.json"; then
        if @jov.iscommand php; then
            local php_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "
            local php_prompt="${FG[105]}php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
        else
            local php_prompt_prefix="${JOVIAL_PALETTE[normal]}[${JOVIAL_PALETTE[error]}need "
            local php_prompt="php${JOVIAL_PALETTE[normal]}]"
        fi
        echo "${php_prompt_prefix}${php_prompt}"
    fi
}

@jov.prompt-python-version() {
    local python_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "

    if [[ -n ${VIRTUAL_ENV} ]] && @jov.rev-parse-find "venv"; then
        local python_prompt="${FG[123]}`$(@jov.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${python_prompt_prefix}${python_prompt}"
        return 0
    fi

    if @jov.rev-parse-find "requirements.txt"; then
        if @jov.iscommand python; then
            local python_prompt="${FG[123]}`\python --version 2>&1`"
        else
            python_prompt_prefix="${JOVIAL_PALETTE[normal]}[${JOVIAL_PALETTE[error]}need "
            local python_prompt="Python${JOVIAL_PALETTE[normal]}]"
        fi
        echo "${python_prompt_prefix}${python_prompt}"
    fi
}

typeset -ga JOVIAL_DEV_ENV_DETECT_FUNCS=(
    @jov.prompt-node-version
    @jov.prompt-golang-version
    @jov.prompt-python-version
    @jov.prompt-php-version
)

@jov.dev-env-segment() {
    for segment_func in "${JOVIAL_DEV_ENV_DETECT_FUNCS[@]}"; do
        local segment=`${segment_func}`
        if [[ -n ${segment} ]]; then 
            echo " ${segment}"
            break
        fi
    done
}


# return 0 for dirty
# return 1 for clean
@jov.judge-git-dirty() {
    local git_status
    local -a flags
    flags=('--porcelain' '--ignore-submodules')
    if [[ ${DISABLE_UNTRACKED_FILES_DIRTY} == true ]]; then
        flags+='--untracked-files=no'
    fi
    git_status=$(\git status ${flags} 2> /dev/null)
    if [[ -n ${git_status} ]]; then
        return 0
    else
        return 1
    fi
}

@jov.git-action-prompt() {
    # always depend on ${JOVIAL_REV_GIT_DIR} path is existed

    local action=""
    local rebase_merge="${JOVIAL_REV_GIT_DIR}/rebase-merge"
    local rebase_apply="${JOVIAL_REV_GIT_DIR}/rebase-apply"
    if [[ -d ${rebase_merge} ]]; then
        local rebase_step="$(< ${rebase_merge}/msgnum)"
        local rebase_total="$(< ${rebase_merge}/end)"
        local rebase_process="${rebase_step}/${rebase_total}"
        if [[ -f ${rebase_merge}/interactive ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi
    elif [[ -d ${rebase_apply} ]]; then
        local rebase_step="$(< ${rebase_merge}/next)"
        local rebase_total="$(< ${rebase_merge}/last)"
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

    echo "${action}"
}

@jov.git-action-prompt-hook() {
    if [[ -z ${JOVIAL_REV_GIT_DIR} ]]; then return; fi

    if @jov.judge-git-dirty; then
        JOVIAL_IS_GIT_DIRTY=true
    else
        JOVIAL_IS_GIT_DIRTY=false
    fi
}

add-zsh-hook precmd @jov.git-action-prompt-hook

@jov.git-branch() {
    # always depend on ${JOVIAL_REV_GIT_DIR} path is existed

    local ref
    ref=$(\git symbolic-ref HEAD 2> /dev/null) \
      || ref=$(\git describe --tags --exact-match 2> /dev/null) \
      || ref=$(\git rev-parse --short HEAD 2> /dev/null) \
      || return 0
    ref="${JOVIAL_PALETTE[git]}${ref#refs/heads/}"

    echo "${ref}"
}


# use `exec` to parallel run commands and capture stdout into file descriptor
# so need run this function in subprocess like `print -P`
# file descriptors:
#   fd 4 -> git branch
#   fd 5 -> git action
@jov.git-info-prompt() {
    if [[ -z ${JOVIAL_REV_GIT_DIR} ]]; then return; fi

    exec 4<> <(@jov.git-branch)
    exec 5<> <(@jov.git-action-prompt)

    local git_branch="$(<& 4)"
    local git_action="$(<& 5)"

    local git_dirty_status

    if [[ ${JOVIAL_IS_GIT_DIRTY} == true ]]; then
        git_dirty_status="${JOVIAL_PALETTE[error]}${JOVIAL_SYMBOL[git.dirty]}"
    else
        git_dirty_status="${JOVIAL_PALETTE[success]}${JOVIAL_SYMBOL[git.clean]}"
    fi

    echo "${JOVIAL_PREFIXES[git-info]}${git_branch}${git_action}${JOVIAL_SUFFIXES[git-info]}${git_dirty_status}"
}


# SGR (Select Graphic Rendition) parameters
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# "%{ %}" use for print command (vcs_info style)
typeset -g SGR_RESET="%{${reset_color}%}"


# partial prompt priority from high to low,
# decide whether to still keep dispaly while terminal width is no enough;
#
# the highest priority element will always keep dispaly;
# `current-time` will always auto detect rest spaces, it's lowest priority
typeset -ga JOVIAL_PROMPT_PRIORITY=(
    path
    git-info
    user
    host
    dev-env
)

typeset -gA JOVIAL_PREFIXES=(
    host            "${JOVIAL_PALETTE[normal]}["
    user            " "
    path            " "
    dev-env         ""
    git-info        " ${JOVIAL_PALETTE[conj.]}on ${JOVIAL_PALETTE[normal]}("
)

typeset -gA JOVIAL_SUFFIXES=(
    host            "${JOVIAL_PALETTE[normal]}] ${JOVIAL_PALETTE[conj.]}as"
    user            " ${JOVIAL_PALETTE[conj.]}in"
    path            ""
    dev-env         ""
    git-info        "${JOVIAL_PALETTE[normal]})"
)

typeset -gA JOVIAL_PROMPT_FORMATS=(
    host            '${JOVIAL_PREFIXES[host]}$(@jov.get-host-name)${JOVIAL_SUFFIXES[host]}'
    user            '${JOVIAL_PREFIXES[user]}$(@jov.get-user-name)${JOVIAL_SUFFIXES[user]}'
    path            '${JOVIAL_PREFIXES[path]}$(@jov.current-dir)${JOVIAL_SUFFIXES[path]}'
    dev-env         '${JOVIAL_PREFIXES[dev-env]}$(@jov.dev-env-segment)${JOVIAL_SUFFIXES[dev-env]}'
    git-info        '$(@jov.git-info-prompt)'
    current-time    '$(@jov.align-right " $(@jov.get-date-time) ")'
)

# file descriptors for prompt output
typeset -gA JOVIAL_OUTPUT_FDS=(
    host 3
    user 4
    path 5
    dev-env 6
    git-info 7
    current-time 8
)

@jovial-prompt() {
    local -i total_length=${#JOVIAL_SYMBOL[corner.top]}
    local -A prompts=(
        host ''
        user ''
        path ''
        dev-env ''
        git-info ''
        current-time ''
    )

    # use `exec` to parallel run commands and capture stdout into file descriptor
    #   (file descriptors are define in `JOVIAL_OUTPUT_FDS`)
    # but due to `exec 6<>` syntax cannot replace by variables like `exec ${fd_number}<>`,
    # so expand the for-loop iteration
    exec 7<> <(print -P "${JOVIAL_PROMPT_FORMATS[git-info]}")
    exec 6<> <(print -P "${JOVIAL_PROMPT_FORMATS[dev-env]}")
    exec 8<> <(print -P "${JOVIAL_PROMPT_FORMATS[current-time]}")

    exec 3<> <(print -P "${JOVIAL_PROMPT_FORMATS[host]}")
    exec 4<> <(print -P "${JOVIAL_PROMPT_FORMATS[user]}")
    exec 5<> <(print -P "${JOVIAL_PROMPT_FORMATS[path]}")

    local prompt_is_emtpy=true
    local prompt_key

    for prompt_key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        # read output from file descriptor
        local output="$(<& ${JOVIAL_OUTPUT_FDS[${prompt_key}]})"

        local -i output_length=$(@jov.unstyle-len "${output}")

        if (( total_length + output_length > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi
        
        prompt_is_emtpy=false

        total_length+=${output_length}
        prompts[${prompt_key}]="${SGR_RESET}${output}"
    done


    # datetime length is fixed numbers of `${JOVIAL_PROMPT_FORMATS[current-time]}` -> ` hh:mm:ss `
    local -i len_datetime=10

    # always auto detect rest spaces to float current time
    if (( total_length + len_datetime <= COLUMNS )); then
        prompts[current-time]="$(<& ${JOVIAL_OUTPUT_FDS[current-time]})"
    fi

    local corner_top="${SGR_RESET}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.top]}"
    local corner_bottom="${SGR_RESET}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.bottom]}"

    echo "${corner_top}${prompts[host]}${prompts[user]}${prompts[path]}${prompts[dev-env]}${prompts[git-info]}${prompts[current-time]}"
    echo "${corner_bottom}$(@jov.typing-pointer) $(@jov.venv-info-prompt) ${SGR_RESET}"
}


PROMPT='$(@jovial-prompt)'
