# jovial.zsh-theme
# https://github.com/zthxxx/jovial


export JOVIAL_VERSION='2.5.2'


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
zmodload zsh/zpty
zmodload zsh/zle

# expand and execute the PROMPT variable 
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
setopt prompt_subst

# setup this flag for hidden python `venv` default prompt
# https://github.com/python/cpython/blob/3.10/Lib/venv/scripts/common/activate#L56
export VIRTUAL_ENV_DISABLE_PROMPT=true

# the default `TERM`` in `screen` command is 'linux' which will cause colorless in terminal,
# so set it with a compatible colorful value,
# otherwise shouldn't override TERM because it maybe a specific user setting.
if [[ ${TERM} == 'linux' ]]; then
  export TERM=xterm-256color
fi

# `\e[00m` is SGR (Select Graphic Rendition) parameters
# which to disable all visual effects.
# this literal as same as `reset_color` defined in [zsh/colors](https://github.com/zsh-users/zsh/blob/zsh-5.8/Functions/Misc/colors#L98)
#
# SGR link: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# "%{ %}" is escape values in Prompt-Expansion (vcs_info style) (for used in `print -P`)
typeset -g sgr_reset="%{\e[00m%}"


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
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Visual-effects
# format quickref:
#   
#   %F{xxx}         => foreground color (text color)
#   %K{xxx}         => background color (color-block)
#   %B              => blod
#   %U              => underline
#   ${sgr_reset}    => reset all effect (provide by jovial)
#
typeset -gA JOVIAL_PALETTE=(
    # hostname
    host '%F{157}'

    # common user name
    user '%F{253}'

    # only root user
    root '%B%F{203}'

    # current work dir path
    path '%B%F{228}%}'

    # git status info (dirty or clean / rebase / merge / cherry-pick)
    git '%F{159}'

    # virtual env activate prompt for python
    venv '%F{159}'
 
    # current time when prompt render, pin at end-of-line
    time '%F{254}'

    # elapsed time of last command executed
    elapsed '%F{222}'

    # exit code of last command
    exit.mark '%F{246}'
    exit.code '%B%F{203}'

    # 'conj.': short for 'conjunction', like as, at, in, on, using
    conj. '%F{102}'

    # shell typing area pointer
    typing '%F{252}'

    # for other common case text color
    normal '%F{252}'

    success '%F{040}'
    error '%F{203}'
)

# parts dispaly order from left to right of jovial theme at the first line 
typeset -ga JOVIAL_PROMPT_ORDER=( host user path dev-env git-info )

# prompt parts priority from high to low, for `responsive design`.
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

# pin last command execute elapsed, if the threshold is reached
typeset -gi JOVIAL_EXEC_THRESHOLD_SECONDS=4

# prefixes and suffixes of jovial prompt part
# all values wrapped in `${...}` will be subject to `Prompt-Expansion` during initialization
typeset -gA JOVIAL_AFFIXES=(
    host.prefix            '${JOVIAL_PALETTE[normal]}['
    # hostname/username use `Prompt-Expansion` syntax in default
    #   https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
    # but you can override it with simple constant string
    hostname               '${(%):-%m}'
    host.suffix            '${JOVIAL_PALETTE[normal]}] ${JOVIAL_PALETTE[conj.]}as'

    user.prefix            ' '
    username               '${(%):-%n}'
    user.suffix            ' ${JOVIAL_PALETTE[conj.]}in'

    path.prefix            ' '
    current-dir            '%~'
    path.suffix            ''

    dev-env.prefix         ' '
    dev-env.suffix         ''

    git-info.prefix        ' ${JOVIAL_PALETTE[conj.]}on ${JOVIAL_PALETTE[normal]}('
    git-info.suffix        '${JOVIAL_PALETTE[normal]})'

    venv.prefix            ' ${JOVIAL_PALETTE[normal]}('
    venv.suffix            '${JOVIAL_PALETTE[normal]})'

    exec-elapsed.prefix    ' ${JOVIAL_PALETTE[elapsed]}~'
    exec-elapsed.suffix    ' '

    exit-code.prefix       ' ${JOVIAL_PALETTE[exit.mark]}exit:'
    exit-code.suffix       ' '

    current-time.prefix    ' '
    current-time.suffix    ' '
)



@jov.iscommand() { [[ -e ${commands[$1]} ]] }

# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
# https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
@jov.unstyle-len() {
    # use (%) for expand `prompt` format like color `%F{123}` or username `%n`
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
    local str="${(%)1}"
    local store_var="$2"

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

    eval ${store_var}=${#unstyled}
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


# map for { job-name -> file-descriptor }
typeset -gA jovial_async_jobs=()
# map for { file-descriptor -> job-name }
typeset -gA jovial_async_fds=()
# map for { job-name -> callback }
typeset -gA jovial_async_callbacks=()

# tiny util for run async job with callback via zpty and zle
# inspired by https://github.com/mafredri/zsh-async
#
# @jov.async <job-name> <handler-func> <callback-func>
#
# `handler-func`  cannot handle with not any param
# `callback-func` can only receive one param: <output-data>
# 
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
@jov.async() {
    local job_name=$1
    local handler=$2
    local callback=$3

    # if job is running, donot run again
    # by believe all zpty job will clear itself by trigger in callback
    # it's an alternative to`zpty -t ${job_name}`
    # because zpty test job done not means the job cleared, they cannot create again
    if [[ -n ${jovial_async_jobs[${job_name}]} ]]; then
        return
    fi

    # async run as non-blocking output subprocess in zpty
    zpty -b ${job_name} @jov.zpty-worker ${handler}
    # REPLY a file-descriptor which was opened by the lost zpty job 
    local -i fd=${REPLY}

    jovial_async_jobs[${job_name}]=${fd}
    jovial_async_fds[${fd}]=${job_name}
    jovial_async_callbacks[${job_name}]=${callback}

    zle -F ${fd} @jov.zle-callback-handler
}

@jov.zpty-worker() {
    local handler=$1

    ${handler}

    # always print new line to avoid handler has not any output that cannot trigger callback
    echo ''
}

# callback for zle, forward zpty output to really job callback
@jov.zle-callback-handler() {
    local -i fd=$1
    local data=''

    local job_name=${jovial_async_fds[${fd}]}
    local callback=${jovial_async_callbacks[${job_name}]}

    # assume the job only have one-line output
    # so if the handler called, we can read all message at this time,
    # then we can remove callback and kill subprocess safety
    zle -F ${fd}
    zpty -r ${job_name} data
    zpty -d ${job_name}

    unset "jovial_async_jobs[${job_name}]"
    unset "jovial_async_fds[${fd}]"
    unset "jovial_async_callbacks[${job_name}]"

    # forward callback, and trimming any leading/trailing whitespace same as command s  ubstitution
    # `[[:graph:]]` is glob for whitespace
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators
    # https://stackoverflow.com/questions/68259691/trimming-whitespace-from-the-ends-of-a-string-in-zsh/68288735#68288735
    ${callback} "${(MS)data##[[:graph:]]*[[:graph:]]}"
}


typeset -g jovial_prompt_part_changed=false

@jov.infer-prompt-rerender() {
    local has_changed="$1"

    if [[ ${has_changed} == true ]]; then
        jovial_prompt_part_changed=true
    fi

    # only rerender if changed and all async jobs done
    if [[ ${jovial_prompt_part_changed} == true ]] && (( ! ${(k)#jovial_async_jobs} )); then
        jovial_prompt_part_changed=false

        # only call zle rerender while prompt prepared
        if (( jovial_prompt_run_count > 1 )); then
            zle reset-prompt
        fi
    fi
}

zle -N @jov.infer-prompt-rerender



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


typeset -gi jovial_prompt_run_count=0

# jovial prompt element value
typeset -gA jovial_parts=() jovial_part_lengths=()
typeset -gA jovial_previous_parts=() jovial_previous_lengths=()

@jov.reset-prompt-parts() {
    for key in ${(k)jovial_parts}; do
        jovial_previous_parts[${key}]="${jovial_parts[${key}]}"
        jovial_previous_lengths[${key}]="${jovial_part_lengths[${key}]}"
    done

    jovial_parts=(
        exec-elapsed    ''
        exit-code       ''
        margin-line     ''
        host            ''
        user            ''
        path            ''
        dev-env         ''
        git-info        ''
        current-time    ''
        typing          ''
        venv            ''
    )

    jovial_part_lengths=(
        host            0
        user            0
        path            0
        dev-env         0
        git-info        0
        current-time    0
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

        local -i affix_len
        @jov.unstyle-len "${JOVIAL_AFFIXES[${key}]}" affix_len

        jovial_affix_lengths[${part}]=$((
            ${jovial_affix_lengths[${part}]:-0}
            + affix_len
        ))
    done
}

@jov.set-typing-pointer() {
    jovial_parts[typing]="${JOVIAL_PALETTE[typing]}"

    if [[ -n ${jovial_rev_git_dir} ]]; then
        if [[ ${jovial_is_git_dirty} == false ]]; then
            jovial_parts[typing]+="${JOVIAL_SYMBOL[arrow.git-clean]}"
        else
            jovial_parts[typing]+="${JOVIAL_SYMBOL[arrow.git-dirty]}"
        fi
    else
        jovial_parts[typing]+="${JOVIAL_SYMBOL[arrow]}"
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
    jovial_parts[host]="${JOVIAL_AFFIXES[hostname]}"
    jovial_part_lengths[host]=$((
        ${#jovial_parts[host]}
        + ${jovial_affix_lengths[host]}
    ))

    jovial_parts[host]="${JOVIAL_AFFIXES[host.prefix]}${JOVIAL_PALETTE[host]}${jovial_parts[host]}${JOVIAL_AFFIXES[host.suffix]}"
}

@jov.set-user-name() {
    jovial_parts[user]="${JOVIAL_AFFIXES[username]}"

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
    jovial_parts[path]="${(%):-${JOVIAL_AFFIXES[current-dir]}}"

    jovial_part_lengths[path]=$((
        ${#jovial_parts[path]}
        + ${jovial_affix_lengths[path]}
    ))

    jovial_parts[path]="${JOVIAL_AFFIXES[path.prefix]}${JOVIAL_PALETTE[path]}${jovial_parts[path]}${JOVIAL_AFFIXES[path.suffix]}"
}


@jov.align-previous-right() {
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

    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local previous_line="\e[1F"
    local next_line="\e[1E"
    local new_line="\n"
    # use `%{ %}` wrapper to aviod ANSI cause eat previous line after prompt rerender (zle reset-prompt)
    local cursor_col="%{\e[${align_site}G%}"
    local result="${previous_line}${cursor_col}${str}"

    eval ${store_var}=${(q)result}
}

@jov.align-right() {
    local str="$1"
    local len=$2
    local store_var="$3"

    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local cursor_col="%{\e[${align_site}G%}"
    local result="${cursor_col}${str}"

    eval ${store_var}=${(q)result}
}


# pin the last command execute elapsed and exit code at previous line end
@jov.pin-execute-info() {
    local -i exec_seconds="${1:-0}"
    local -i exit_code="${2:-0}"

    local -i pin_length=0

    if (( JOVIAL_EXEC_THRESHOLD_SECONDS >= 0)) && (( exec_seconds >= JOVIAL_EXEC_THRESHOLD_SECONDS )); then
        local -i seconds=$(( exec_seconds % 60 ))
        local -i minutes=$(( exec_seconds / 60 % 60 ))
        local -i hours=$(( exec_seconds / 3600 ))

        local -a humanize=()

        (( hours > 0 )) && humanize+="${hours}h"
        (( minutes > 0 )) && humanize+="${minutes}m"
        (( seconds > 0 )) && humanize+="${seconds}s"

        # join array with 1 space
        local elapsed="${(j.:.)humanize}"

        jovial_parts[exec-elapsed]="${sgr_reset}${JOVIAL_AFFIXES[exec-elapsed.prefix]}${JOVIAL_PALETTE[elapsed]}${elapsed}${JOVIAL_AFFIXES[exec-elapsed.suffix]}"
        pin_length+=$(( ${jovial_affix_lengths[exec-elapsed]} + ${#elapsed} ))
    fi

    if (( exit_code != 0 )); then
        jovial_parts[exit-code]="${sgr_reset}${JOVIAL_AFFIXES[exit-code.prefix]}${JOVIAL_PALETTE[exit.code]}${exit_code}${JOVIAL_AFFIXES[exit-code.suffix]}"
        pin_length+=$(( ${jovial_affix_lengths[exit-code]} + ${#exit_code} ))
    fi
    
    if (( pin_length > 0 )); then
        local pin_message="${jovial_parts[exec-elapsed]}${jovial_parts[exit-code]}"
        @jov.align-previous-right "${pin_message}" ${pin_length} pin_message
        print -P "${pin_message}"
    fi
}


@jov.set-date-time() {
    # trimming suffix trailing whitespace
    # donot print trailing whitespace for better interaction while terminal width in narrowing
    local suffix="${(MS)JOVIAL_AFFIXES[current-time.suffix]##*[[:graph:]]}"
    local current_time="${JOVIAL_AFFIXES[current-time.prefix]}${JOVIAL_PALETTE[time]}${(%):-%D{%H:%M:%S\}}${suffix}"
    # 8 is fixed lenght of datatime format `hh:mm:ss`
    jovial_part_lengths[current-time]=$(( 8 + ${jovial_affix_lengths[current-time]} ))
    @jov.align-right "${current_time}" ${jovial_part_lengths[current-time]} 'jovial_parts[current-time]'
}



@jov.prompt-node-version() {
    if @jov.rev-parse-find "package.json"; then
        if @jov.iscommand node; then
            local node_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "
            local node_prompt="%F{120}node `\node -v`"
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
            local go_prompt="%F{086}Golang ${go_version}"
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
            local php_prompt="%F{105}php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
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
        local python_prompt="%F{123}`$(@jov.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${python_prompt_prefix}${python_prompt}"
        return 0
    fi

    if @jov.rev-parse-find "requirements.txt"; then
        if @jov.iscommand python; then
            local python_prompt="%F{123}`\python --version 2>&1`"
        elif @jov.iscommand python3; then
            local python_prompt="%F{123}`\python3 --version 2>&1`"
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
    for segment_func in ${JOVIAL_DEV_ENV_DETECT_FUNCS[@]}; do
        local segment=`${segment_func}`
        if [[ -n ${segment} ]]; then 
            echo "${segment}"
            break
        fi
    done
}

@jov.set-dev-env-info() {
    local result="$1"
    local has_changed=false

    if [[ -z ${result} ]]; then
        if [[ -n ${jovial_previous_parts[dev-env]} ]]; then
            jovial_parts[dev-env]=''
            jovial_part_lengths[dev-env]=0
            has_changed=true
        fi

        @jov.infer-prompt-rerender ${has_changed}
        return
    fi

    jovial_parts[dev-env]="${JOVIAL_AFFIXES[dev-env.prefix]}${result}${JOVIAL_AFFIXES[dev-env.suffix]}"

    local -i result_len
    @jov.unstyle-len "${result}" result_len

    jovial_part_lengths[dev-env]=$((
        result_len
        + ${jovial_affix_lengths[dev-env]}
    ))

    if [[ ${jovial_parts[dev-env]} != ${jovial_previous_parts[dev-env]} ]]; then
        has_changed=true
    fi

    @jov.infer-prompt-rerender ${has_changed}
}


@jov.sync-dev-env-detect() {
    local -i output_fd=$1

    local dev_env="$(<& ${output_fd})"
    exec {output_fd}>& -

    @jov.set-dev-env-info "${dev_env}"
}

@jov.async-dev-env-detect() {
    # use cached prompt part for render, and try to update as async

    jovial_parts[dev-env]="${jovial_previous_parts[dev-env]}"
    jovial_part_lengths[dev-env]="${jovial_previous_lengths[dev-env]}"

    @jov.async 'dev-env' @jov.dev-env-detect @jov.set-dev-env-info
}

# return `true` for dirty
# return `false` for clean
@jov.judge-git-dirty() {
    local git_status
    local -a flags
    flags=('--porcelain' '--ignore-submodules')
    if [[ ${DISABLE_UNTRACKED_FILES_DIRTY} == true ]]; then
        flags+='--untracked-files=no'
    fi
    git_status="$(\git status ${flags} 2> /dev/null)"
    if [[ -n ${git_status} ]]; then
        echo true
    else
        echo false
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
        if [[ -f ${rebase_merge}/msgnum ]]; then
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
#   @jov.set-git-info [true|false]
# first param is whether git is dirty or not (`true` or `false`), 
# if first param is not set, will try to read by exec
@jov.set-git-info() {
    local is_dirty="$1"

    local dirty_fd branch_fd action_fd

    if [[ -z ${is_dirty} ]]; then
        exec {dirty_fd}<> <(@jov.judge-git-dirty)
    fi

    exec {branch_fd}<> <(@jov.git-branch)
    exec {action_fd}<> <(@jov.git-action-prompt)

    # read and close file descriptors
    local git_branch="$(<& ${branch_fd})"
    local git_action="$(<& ${action_fd})"
    exec {branch_fd}>& -
    exec {action_fd}>& -

    if [[ -n ${dirty_fd} ]]; then
        is_dirty="$(<& ${dirty_fd})"
        exec {dirty_fd}>& -
    fi

    local git_state='' state_color='' git_dirty_status=''
 
    if [[ ${is_dirty} == true ]]; then
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

    local has_changed=false

    if [[ ${jovial_parts[git-info]} != ${jovial_previous_parts[git-info]} ]]; then
        has_changed=true
    fi

    # `jovial_is_git_dirty` is global variable that `true` or `false`
    jovial_is_git_dirty="${is_dirty}"

    # set typing-pointer due to git_dirty state maybe changed
    @jov.set-typing-pointer

    @jov.infer-prompt-rerender ${has_changed}
}


@jov.sync-git-check() {
    if [[ -z ${jovial_rev_git_dir} ]]; then return; fi

    @jov.set-git-info
}

@jov.async-git-check() {
    if [[ -z ${jovial_rev_git_dir} ]]; then return; fi

    # use cached prompt part for render, and try to update as async

    jovial_parts[git-info]="${jovial_previous_parts[git-info]}"
    jovial_part_lengths[git-info]="${jovial_previous_lengths[git-info]}"

    @jov.async 'git-info' @jov.judge-git-dirty @jov.set-git-info
}

# `EPOCHSECONDS` is setup in zsh/datetime module
# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module
typeset -gi jovial_exec_timestamp=0
@jov.exec-timestamp() {
    jovial_exec_timestamp=${EPOCHSECONDS}
}
add-zsh-hook preexec @jov.exec-timestamp

@jov.set-margin-line() {
    # donot print empty line if terminal height less than 12 lines when prompt initial load
    if (( jovial_prompt_run_count == 1 )) && (( LINES <= 12 )); then
        return
    fi

    jovial_parts[margin-line]='\n'
}

@jov.prompt-prepare() {
    local -i exit_code=$?
    local -i exec_seconds=0

    if (( jovial_exec_timestamp > 0 )); then
        exec_seconds=$(( EPOCHSECONDS - jovial_exec_timestamp ))
        jovial_exec_timestamp=0
    fi

    jovial_prompt_run_count+=1

    @jov.reset-prompt-parts

    if (( jovial_prompt_run_count == 1 )); then
        @jov.init-affix
        
        local -i dev_env_fd
        exec {dev_env_fd}<> <(@jov.dev-env-detect)
        @jov.sync-git-check
        @jov.sync-dev-env-detect ${dev_env_fd}
    else
        @jov.async-dev-env-detect
        @jov.async-git-check
    fi

    @jov.pin-execute-info ${exec_seconds} ${exit_code}
    @jov.set-margin-line
    @jov.set-host-name
    @jov.set-user-name
    @jov.set-current-dir
    @jov.set-typing-pointer
    @jov.set-venv-info
}

add-zsh-hook precmd @jov.prompt-prepare



@jovial-prompt() {
    local -i total_length=${#JOVIAL_SYMBOL[corner.top]}
    local -A prompts=(
        margin-line ''
        host ''
        user ''
        path ''
        dev-env ''
        git-info ''
        current-time ''
        typing ''
        venv ''
    )

    local prompt_is_emtpy=true
    local key

    for key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        local -i part_length=${jovial_part_lengths[${key}]}

        # keep padding right 1 space
        if (( total_length + part_length + 1 > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi
        
        prompt_is_emtpy=false

        total_length+=${part_length}
        prompts[${key}]="${sgr_reset}${jovial_parts[${key}]}"
    done

    # always auto detect rest spaces to float current time
    @jov.set-date-time
    if (( total_length + ${jovial_part_lengths[current-time]} <= COLUMNS )); then
        prompts[current-time]="${sgr_reset}${jovial_parts[current-time]}"
    fi

    prompts[margin-line]="${sgr_reset}${jovial_parts[margin-line]}"
    prompts[typing]="${sgr_reset}${jovial_parts[typing]}"
    prompts[venv]="${sgr_reset}${jovial_parts[venv]}"

    local -a ordered_parts=()
    for key in ${JOVIAL_PROMPT_ORDER[@]}; do
        ordered_parts+="${prompts[${key}]}"
    done

    local corner_top="${prompts[margin-line]}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.top]}"
    local corner_bottom="${sgr_reset}${JOVIAL_PALETTE[normal]}${JOVIAL_SYMBOL[corner.bottom]}"

    echo "${corner_top}${(j..)ordered_parts}${prompts[current-time]}"
    echo "${corner_bottom}${prompts[typing]}${prompts[venv]} ${sgr_reset}"
}


PROMPT='$(@jovial-prompt)'
