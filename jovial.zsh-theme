# jovial.zsh-theme
# https://github.com/zthxxx/jovial


export JOVIAL_VERSION='2.0.3'


# Development code style:
#
# use "@jov."" prefix for jovial internal functions
# use "kebab-case" style for function names and mapping key
# use "snake_case" for function's internal variables, and also declare it with "local" mark
# use "CAPITAL_SNAKE_CASE" for global variables that design for user customization
# use "snake_case" for global but only used for jovial theme
# use indent spaces 4

# https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions
autoload -Uz add-zsh-hook

# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module
zmodload zsh/datetime

# setup this flag for hidden python `venv` default prompt
# https://github.com/python/cpython/blob/3.10/Lib/venv/scripts/common/activate#L56
export VIRTUAL_ENV_DISABLE_PROMPT=true


# jovial theme element symbol mapping
#
# (the syntax `typeset -A xxx` is means to declare a `associative-array` in zsh, it's like `dictionary`)
# more `typeset` syntax see https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html
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

# partial prompt priority from high to low, for `responsive design`.
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

# prefixes and suffixes of jovial prompt part
typeset -gA JOVIAL_AFFIXES=(
    host.prefix            '${JOVIAL_PALETTE[normal]}['
    host.suffix            '${JOVIAL_PALETTE[normal]}] ${JOVIAL_PALETTE[conj.]}as'

    user.prefix            ' '
    user.suffix            ' ${JOVIAL_PALETTE[conj.]}in'

    path.prefix            ' '
    path.suffix            ''

    dev-env.prefix         ' '
    dev-env.suffix         ''

    git-info.prefix        ' ${JOVIAL_PALETTE[conj.]}on ${JOVIAL_PALETTE[normal]}('
    git-info.suffix        '${JOVIAL_PALETTE[normal]})'

    venv.prefix            '${JOVIAL_PALETTE[normal]}('
    venv.suffix            '${JOVIAL_PALETTE[normal]}) '
)



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
    local current_path="${2:-${PWD}}"
    local whether_output=${3:-false}

    local root_regex='^(/)[^/]*$'
    local dirname_regex='^((/[^/]+)+)/[^/]+/?$'

    # [hacking] it's same as  parent_path=`\dirname ${current_path}`,
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
            if ${whether_output}; then
                echo "${current_path}";
            fi
            return 0
        fi
        current_path="${parent_path}"

        # [hacking] it's same as  parent_path=`\dirname ${parent_path}`,
        # but better performance due to reduce subprocess call
        if [[ ${parent_path} =~ ${root_regex} || ${parent_path} =~ ${dirname_regex} ]]; then
            parent_path="${match[1]}"
        else
            return 1
        fi
    done
    return 1
}


@jov.iscommand() { [[ -e ${commands[$1]} ]] }

# SGR (Select Graphic Rendition) parameters
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# "%{ %}" use for print command (vcs_info style)
typeset -g sgr_reset="%{${reset_color}%}"

# variables for git prompt
typeset -g jovial_rev_git_dir=""
typeset -g jovial_is_git_dirty=false

@jov.chpwd-git-dir-hook() {
    # it's the same as  jovial_rev_git_dir=`\git rev-parse --git-dir 2>/dev/null`
    # but better performance due to reduce subprocess call

    local project_root_dir="$(@jov.rev-parse-find .git '' true)"

    if [[ -n ${project_root_dir} ]]; then
        jovial_rev_git_dir="${project_root_dir}/.git"
    else
        jovial_rev_git_dir=""
    fi
}

add-zsh-hook chpwd @jov.chpwd-git-dir-hook
@jov.chpwd-git-dir-hook


# jovial prompt element value
typeset -gA jovial_parts=() jovial_part_lengths=()

@jov.reset-prompt-parts() {
    typeset -gA jovial_parts=(
        exit-code       ''
        host            ''
        user            ''
        path            ''
        dev-env         ''
        git-info        ''
        current-time    ''
        typing          ''
        venv            ''
    )

    typeset -gA jovial_part_lengths=(
        host            0
        user            0
        path            0
        dev-env         0
        git-info        0
        # datetime is fixed lenght of ` hh:mm:ss `
        current-time    10
    )
}

# store calculated lengths of `JOVIAL_AFFIXES` part
typeset -gA jovial_affix_lengths=()

@jov.init-affix() {
    local key result
    for key in ${(k)JOVIAL_AFFIXES}; do
        eval "JOVIAL_AFFIXES[${key}]"=\""${JOVIAL_AFFIXES[${key}]}"\"
        # remove `.prefix`, `.suffix`
        # `xxx.prefix`` -> `xxx`
        local part="${key/%.(prefix|suffix)/}"
        jovial_affix_lengths[${part}]=$((
            ${jovial_affix_lengths[${part}]:-0}
            + $(@jov.unstyle-len "${JOVIAL_AFFIXES[${key}]}")
        ))
    done
}

@jov.set-typing-pointer() {
    if [[ -n ${jovial_rev_git_dir} ]]; then
        if [[ ${jovial_is_git_dirty} == false ]]; then
            jovial_parts[typing]="${JOVIAL_SYMBOL[arrow.git-clean]}"
        else
            jovial_parts[typing]="${JOVIAL_SYMBOL[arrow.git-dirty]}"
        fi
    else
        jovial_parts[typing]="${JOVIAL_SYMBOL[arrow]}"
    fi
}

@jov.set-venv-info() {
    if [[ -z ${VIRTUAL_ENV} ]]; then
        jovial_parts[venv]=''
    else
        jovial_parts[venv]="${JOVIAL_AFFIXES[venv.prefix]}${JOVIAL_PALETTE[venv]}$(basename ${VIRTUAL_ENV})${JOVIAL_AFFIXES[venv.suffix]}"
    fi
}

# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
@jov.set-host-name() {
    jovial_parts[host]="${(%):-%m}"
    jovial_part_lengths[host]=$((
        ${#jovial_parts[host]}
        + ${jovial_affix_lengths[host]}
    ))

    jovial_parts[host]="${JOVIAL_AFFIXES[host.prefix]}${JOVIAL_PALETTE[host]}${jovial_parts[host]}${JOVIAL_AFFIXES[host.suffix]}"
}

@jov.set-user-name() {
    jovial_parts[user]="${(%):-%n}"

    jovial_part_lengths[user]=$((
        ${#jovial_parts[user]}
        + ${jovial_affix_lengths[user]}
    ))

    local name_color="${JOVIAL_PALETTE[user]}"
    if [[ ${UID} == 0 || ${USER} == 'root' ]]; then
        name_color="${JOVIAL_PALETTE[root]}"
    fi

    jovial_parts[user]="${JOVIAL_AFFIXES[user.prefix]}${name_color}${jovial_parts[user]}${JOVIAL_AFFIXES[user.suffix]}"
}

@jov.set-current-dir() {
    jovial_parts[path]="${(%):-%~}"

    jovial_part_lengths[path]=$((
        ${#jovial_parts[path]}
        + ${jovial_affix_lengths[path]}
    ))

    jovial_parts[path]="${JOVIAL_AFFIXES[path.prefix]}${JOVIAL_PALETTE[path]}${jovial_parts[path]}${JOVIAL_AFFIXES[path.suffix]}"
}

@jov.set-date-time() {
    local current_time="${JOVIAL_PALETTE[time]} ${(%):-%D{%H:%M:%S\}} "
    @jov.align-right "${current_time}" ${jovial_part_lengths[current-time]} 'jovial_parts[current-time]'
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

    local str="$1"
    local len=$2
    local store_var="$3"

    local new_line_space='\n\n'
    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local previous_line="\e[1A"
    local cursor_cols="\e[${align_site}G"
    local result="${previous_line}${cursor_cols}${str}${new_line_space}"

    eval ${store_var}=${(q)result}
}

@jov.align-right() {
    local str="$1"
    local len=$2
    local store_var="$3"

    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local cursor_cols="\e[${align_site}G"
    local result="${cursor_cols}${str}"

    eval ${store_var}=${(q)result}
}


# pin the last commad exit code at previous line end
@jov.set-exit-code() {
    local exit_code="${1:-0}"

    # donot print empty line when prompt initial load, if terminal height less than 10 lines
    if (( jovial_prompt_run_count == 1 )) && (( LINES <= 12 )); then
        jovial_parts[exit-code]=''
        return
    fi

    if [[ ${exit_code} == 0 ]]; then
        jovial_parts[exit-code]='\n'
    else
        local exit_mark='exit:'
        local exit_code_warn="${sgr_reset} ${JOVIAL_PALETTE[exit.mark]}${exit_mark}${JOVIAL_PALETTE[exit.code]}${exit_code} "
        # also affix 2 spaces
        local -i warn_len=$(( 2 + ${#exit_mark} + ${#exit_code} ))

        @jov.previous-align-right "${exit_code_warn}" ${warn_len} 'jovial_parts[exit-code]'
    fi
}




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

@jov.dev-env-detect() {
    local store_var="$1"
    for segment_func in ${JOVIAL_DEV_ENV_DETECT_FUNCS[@]}; do
        local segment=`${segment_func}`
        if [[ -n ${segment} ]]; then 
            eval ${store_var}=${(q)segment}
            break
        fi
    done
}


@jov.set-dev-env-info() {
    local result=''
    @jov.dev-env-detect result

    if [[ -z ${result} ]]; then
        return
    fi

    jovial_parts[dev-env]="${JOVIAL_AFFIXES[dev-env.prefix]}${result}${JOVIAL_AFFIXES[dev-env.suffix]}"

    jovial_part_lengths[dev-env]=$((
        $(@jov.unstyle-len "${result}")
        + ${jovial_affix_lengths[dev-env]}
    ))
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
    git_status="$(\git status ${flags} 2> /dev/null)"
    if [[ -n ${git_status} ]]; then
        return 0
    else
        return 1
    fi
}

@jov.git-action-prompt() {
    # always depend on ${jovial_rev_git_dir} path is existed

    local action=''
    local rebase_process=''
    local rebase_merge="${jovial_rev_git_dir}/rebase-merge"
    local rebase_apply="${jovial_rev_git_dir}/rebase-apply"

    if [[ -d ${rebase_merge} ]]; then
        if [[ -f ${rebase_merge}/interactive ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi

        # while edit rebase interactive message,
        # `msgnum` `end` are not exist yet
        if [[ -d ${rebase_merge}/msgnum ]]; then
            local rebase_step="$(< ${rebase_merge}/msgnum)"
            local rebase_total="$(< ${rebase_merge}/end)"
            rebase_process="${rebase_step}/${rebase_total}"
        fi
    elif [[ -d ${rebase_apply} ]]; then
        if [[ -f ${rebase_apply}/rebasing ]]; then
            action="REBASE"
        elif [[ -f ${rebase_apply}/applying ]]; then
            action="AM"
        else
            action="AM/REBASE"
        fi

        local rebase_step="$(< ${rebase_merge}/next)"
        local rebase_total="$(< ${rebase_merge}/last)"
        rebase_process="${rebase_step}/${rebase_total}"
    elif [[ -f ${jovial_rev_git_dir}/MERGE_HEAD ]]; then
        action="MERGING"
    elif [[ -f ${jovial_rev_git_dir}/CHERRY_PICK_HEAD ]]; then
        action="CHERRY-PICKING"
    elif [[ -f ${jovial_rev_git_dir}/REVERT_HEAD ]]; then
        action="REVERTING"
    elif [[ -f ${jovial_rev_git_dir}/BISECT_LOG ]]; then
        action="BISECTING"
    fi

    if [[ -n ${rebase_process} ]]; then
        action="${action} ${rebase_process}"
    fi
    if [[ -n ${action} ]]; then
        action="|${action}"
    fi

    echo "${action}"
}

@jov.git-check-dirty() {
    if [[ -z ${jovial_rev_git_dir} ]]; then return; fi

    if @jov.judge-git-dirty; then
        jovial_is_git_dirty=true
    else
        jovial_is_git_dirty=false
    fi
}

add-zsh-hook precmd @jov.git-check-dirty

@jov.git-branch() {
    # always depend on ${jovial_rev_git_dir} path is existed

    local ref
    ref="$(\git symbolic-ref HEAD 2> /dev/null)" \
      || ref="$(\git describe --tags --exact-match 2> /dev/null)" \
      || ref="$(\git rev-parse --short HEAD 2> /dev/null)" \
      || return 0
    ref="${ref#refs/heads/}"

    echo "${ref}"
}


# use `exec` to parallel run commands and capture stdout into file descriptor
# (file descriptors are define in `jovial_output_fds`)
@jov.set-git-info() {
    if [[ -z ${jovial_rev_git_dir} ]]; then return; fi

    exec 4<> <(@jov.git-branch)
    exec 5<> <(@jov.git-action-prompt)

    local git_branch="$(<& 4)"
    local git_action="$(<& 5)"

    local git_state='' state_color='' git_dirty_status=''

    jovial_part_lengths[git-info]=0

    if [[ ${jovial_is_git_dirty} == true ]]; then
        git_state='dirty'
        state_color='error'
    else
        git_state='clean'
        state_color='success'
    fi

    git_dirty_status="${JOVIAL_PALETTE[${state_color}]}${JOVIAL_SYMBOL[git.${git_state}]}"

    jovial_parts[git-info]="${JOVIAL_AFFIXES[git-info.prefix]}${JOVIAL_PALETTE[git]}${git_branch}${git_action}${JOVIAL_AFFIXES[git-info.suffix]}${git_dirty_status}"

    jovial_part_lengths[git-info]=$((
        ${#JOVIAL_SYMBOL[git.${git_state}]}
        + ${jovial_affix_lengths[git-info]}
        + ${#git_branch}
        + ${#git_action}
    ))
}


typeset -gi jovial_prompt_run_count=0

@jov.prompt-prepare() {
    local exit_code=$?

    jovial_prompt_run_count+=1

    if (( jovial_prompt_run_count == 1 )); then
        @jov.init-affix
    fi

    @jov.reset-prompt-parts

    @jov.set-exit-code ${exit_code}
    @jov.set-host-name
    @jov.set-user-name
    @jov.set-current-dir
    @jov.set-git-info
    @jov.set-dev-env-info
    @jov.set-typing-pointer
    @jov.set-venv-info
}

add-zsh-hook precmd @jov.prompt-prepare



# file descriptors map for prompt output
typeset -gA jovial_output_fds=(
    dev-env 3
    git.branch 4
    git.action 5
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

    local prompt_is_emtpy=true
    local key

    for key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        local -i part_length=${jovial_part_lengths[${key}]}

        if (( total_length + part_length > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi
        
        prompt_is_emtpy=false

        total_length+=${part_length}
        prompts[${key}]="${sgr_reset}${jovial_parts[${key}]}"
    done

    # always auto detect rest spaces to float current time
    if (( total_length + ${jovial_part_lengths[current-time]} <= COLUMNS )); then
        @jov.set-date-time
        prompts[current-time]="${jovial_parts[current-time]}"
    fi

    local corner_top="${jovial_parts[exit-code]}${sgr_reset}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.top]}"
    local corner_bottom="${sgr_reset}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.bottom]}"

    echo "${corner_top}${prompts[host]}${prompts[user]}${prompts[path]}${prompts[dev-env]}${prompts[git-info]}${prompts[current-time]}"
    echo "${corner_bottom}${jovial_parts[typing]} ${jovial_parts[venv]} ${sgr_reset}"
}


PROMPT='$(@jovial-prompt)'
