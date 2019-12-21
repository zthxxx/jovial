# jovial.zsh-theme
# https://github.com/zthxxx/jovial

# dev refs: 
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
# https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
# https://donsnotes.com/tech/charsets/ascii.html
#
# Cursor Up        <ESC>[{COUNT}A
# Cursor Down      <ESC>[{COUNT}B
# Cursor Right     <ESC>[{COUNT}C
# Cursor Left      <ESC>[{COUNT}D
# Cursor Horizontal Absolute      <ESC>[{COUNT}G

export JOVIAL_VERSION="1.1.1"

autoload -Uz add-zsh-hook
autoload -Uz regexp-replace

# JOVIAL_ARROW='─>'
# JOVIAL_ARROW='─▶'
local JOVIAL_ARROW='─➤'

# git prompt
local REV_GIT_DIR=""
local IS_GIT_DIRTY=false
local GIT_STATUS_PROMPT=""

local LAST_EXIT_CODE=0


setopt RE_MATCH_PCRE
VIRTUAL_ENV_DISABLE_PROMPT=true

ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[102]%}on%{$reset_color%} (%{$FG[159]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
GIT_PROMPT_DIRTY_STYLE="%{$reset_color%})%{$FG[202]%}✘✘✘"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%})%{$FG[040]%}✔"

iscommand() { [[ -e $commands[$1] ]] }

is_git_dir() { command git rev-parse &>/dev/null }

chpwd_git_dir_hook() { REV_GIT_DIR=`command git rev-parse --git-dir 2>/dev/null` }
add-zsh-hook chpwd chpwd_git_dir_hook
chpwd_git_dir_hook

# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
# https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
unstyle_len() {
    local str="$1"
    regexp-replace str '\e\[[0-9;]*?[a-zA-Z]' ''
    echo ${#str}
}

# rev_parse_find(filename:string, path:string, output:boolean)
# reverse from path to root wanna find the targe file
# output: whether show the file path
rev_parse_find() {
    local target="$1"
    local current_path="${2:-`pwd`}"
    local whether_output=${3:-false}
    local parent_path="`command dirname $current_path`"
    while [[ ${parent_path} != "/" ]]; do
        if [[ -e ${current_path}/${target} ]]; then
            if $whether_output; then echo "$current_path"; fi
            return 0
        fi
        current_path="$parent_path"
        parent_path="`command dirname $parent_path`"
    done
    return 1
}

venv_info_prompt() { [[ -n ${VIRTUAL_ENV} ]] && echo "$FG[242](%{$FG[159]%}$(basename $VIRTUAL_ENV)$FG[242])%{$reset_color%} "; }

get_host_name() { echo "[%{$FG[157]%}%m%{$reset_color%}]"; }

get_user_name() {
    local name_prefix="%{$reset_color%}"
    if [[ $USER == 'root' || $UID == 0 ]]; then
        name_prefix="%{$FG[203]%}"
    fi
    echo "${name_prefix}%n%{$reset_color%}"
}


git_prompt_info () {
    if [[ -z ${REV_GIT_DIR} ]]; then return 1; fi
    local ref
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}${GIT_STATUS_PROMPT}$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

judge_git_dirty () {
	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain' '--ignore-submodules=dirty')
    if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]; then
        FLAGS+='--untracked-files=no'
    fi
    STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
	if [[ -n $STATUS ]]; then
        return 0
	else
        return 1
	fi
}

type_tip_pointer() {
    if [[ -n ${REV_GIT_DIR} ]]; then
        if [[ ${IS_GIT_DIRTY} == false ]]; then
            echo '(๑˃̵ᴗ˂̵)و'
        else
            echo '(ﾉ˚Д˚)ﾉ'
        fi
    else
        echo "${JOVIAL_ARROW}"
    fi
}

current_dir() {
    echo "%{$terminfo[bold]$FG[228]%}%~%{$reset_color%}"
}

get_date_time() {
    # echo "%{$reset_color%}%D %*"
    command date "+%H:%M:%S"
}

get_space_size() {
    # ref: http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    local str="$1"
    local zero_pattern='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero_pattern/}}
    local size=$(( $COLUMNS - $len + 1 ))
    echo "$size"
}

previous_align_right() {
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    local new_line_space='\n '
    local str="$1"
    local align_site=`get_space_size "$str"`
    local previous_line="\e[1A"
    local cursor_cols="\e[${align_site}G"
    echo "${previous_line}${cursor_cols}${str}${new_line_space}"
}

align_right() {
    local str="$1"
    local align_site=`get_space_size "$str"`
    local cursor_cols="\e[${align_site}G"
    echo "${cursor_cols}${str}"
}

# pin the last commad exit code at previous line end
get_pin_exit_code() {
    # LAST_EXIT_CODE changed in `gen_jovial_prompt`, 
    # because $? must be read in the first function of PROMPT
    local exit_code=${LAST_EXIT_CODE}
    if [[ $exit_code != 0 ]]; then
        local exit_code_warn=" %{$FG[246]%}exit:%{$fg_bold[red]%}${exit_code}%{$reset_color%}"
        previous_align_right "$exit_code_warn"
    fi
}

prompt_node_version() {
    if rev_parse_find "package.json"; then
        if iscommand node; then
            local NODE_PROMPT_PREFIX="%{$FG[102]%}using%{$FG[120]%} "
            local NODE_PROMPT="node `command node -v`"
        else
            local NODE_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            local NODE_PROMPT="Nodejs%{$FG[242]%}]"
        fi
        echo "${NODE_PROMPT_PREFIX}${NODE_PROMPT}%{$reset_color%}"
    fi
}

# http://php.net/manual/en/reserved.constants.php
prompt_php_version() {
    if rev_parse_find "composer.json"; then
        if iscommand php; then
            local PHP_PROMPT_PREFIX="%{$FG[102]%}using%{$FG[105]%} "
            local PHP_PROMPT="php `command php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
        else
            local PHP_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            local PHP_PROMPT="php%{$FG[242]%}]"
        fi
        echo "${PHP_PROMPT_PREFIX}${PHP_PROMPT}%{$reset_color%}"
    fi
}

prompt_python_version() {
    local PYTHON_PROMPT_PREFIX="%{$FG[102]%}using%{$FG[123]%} "
    if rev_parse_find "venv"; then
        local PYTHON_PROMPT="`$(rev_parse_find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}%{$reset_color%}"
    elif rev_parse_find "requirements.txt"; then
        if iscommand python; then
            local PYTHON_PROMPT="`command python --version 2>&1`"
        else
            PYTHON_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            local PYTHON_PROMPT="Python%{$FG[242]%}]"
        fi
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}%{$reset_color%}"
    fi
}

dev_env_segment() {
    local segment_funcs=(
        prompt_node_version
        prompt_php_version
        prompt_python_version
    )
    for segment_func in "${segment_funcs[@]}"; do
        local segment=`${segment_func}`
        if [[ -n $segment ]]; then 
            echo " $segment"
            break
        fi
    done
}

git_action_prompt() {
    if [[ -z ${REV_GIT_DIR} ]]; then return 1; fi
    if [[ ${IS_GIT_DIRTY} == false ]]; then return 1; fi

    local action=""
    local rebase_merge="${REV_GIT_DIR}/rebase-merge"
    local rebase_apply="${REV_GIT_DIR}/rebase-apply"
	if [[ -d ${rebase_merge} ]]; then
        local rebase_step=`command cat "${rebase_merge}/msgnum"`
        local rebase_total=`command cat "${rebase_merge}/end"`
        local rebase_process="${rebase_step}/${rebase_total}"
		if [[ -f ${rebase_merge}/interactive ]]; then
			action="REBASE-i"
		else
			action="REBASE-m"
		fi
	elif [[ -d ${rebase_apply} ]]; then
        local rebase_step=`command cat "${rebase_apply}/next"`
        local rebase_total=`command cat "${rebase_apply}/last"`
        local rebase_process="${rebase_step}/${rebase_total}"
        if [[ -f ${rebase_apply}/rebasing ]]; then
            action="REBASE"
        elif [[ -f ${rebase_apply}/applying ]]; then
            action="AM"
        else
            action="AM/REBASE"
        fi
    elif [[ -f ${REV_GIT_DIR}/MERGE_HEAD ]]; then
        action="MERGING"
    elif [[ -f ${REV_GIT_DIR}/CHERRY_PICK_HEAD ]]; then
        action="CHERRY-PICKING"
    elif [[ -f ${REV_GIT_DIR}/REVERT_HEAD ]]; then
        action="REVERTING"
    elif [[ -f ${REV_GIT_DIR}/BISECT_LOG ]]; then
        action="BISECTING"
    fi

	if [[ -n ${rebase_process} ]]; then
		action="$action $rebase_process"
	fi
    if [[ -n $action ]]; then
		action="|$action"
	fi

    echo "$action"
}


git_action_prompt_hook() {
    if [[ -z ${REV_GIT_DIR} ]]; then return 1; fi

    if judge_git_dirty; then
        IS_GIT_DIRTY=true
    else
        IS_GIT_DIRTY=false
    fi

    if [[ ${IS_GIT_DIRTY} == true ]]; then
        ZSH_THEME_GIT_PROMPT_DIRTY="`git_action_prompt`${GIT_PROMPT_DIRTY_STYLE}"
        GIT_STATUS_PROMPT="$ZSH_THEME_GIT_PROMPT_DIRTY"
    else
        GIT_STATUS_PROMPT="$ZSH_THEME_GIT_PROMPT_CLEAN"
    fi
}

local JOVIAL_PROMPT_UP_CORNER='╭─'
local JOVIAL_PROMPT_DOWN_CORNER='╰─'
local -A JOVIAL_PROMPT_FORMATS=(
    host '$(get_host_name)%{$FG[102]%} as'
    user ' $(get_user_name)%{$FG[102]%} in'
    path ' $(current_dir)'
    dev_env '$(dev_env_segment)'
    git_info ' $(git_prompt_info)'
    current_time '$(align_right " `get_date_time`")'
)

local JOVIAL_PROMPT_PRIORITY=(
    path
    git_info
    user
    host
    dev_env
    current_time
)

gen_jovial_prompt() {
    LAST_EXIT_CODE=$?
    local -i total_length=${#JOVIAL_PROMPT_UP_CORNER}
    local -A prompts=(
        host ''
        user ''
        path ''
        dev_env ''
        git_info ''
        current_time ''
    )

    for key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        if (( total_length <= COLUMNS )); then
            local item=$(print -P "${JOVIAL_PROMPT_FORMATS[${key}]}")
            total_length+=$(unstyle_len "${item}")

            # always display current path
            if [[ ${key} == path ]] || (( total_length <= COLUMNS )); then
                prompts[${key}]="${item}"
            fi
        fi
    done

    echo "$(get_pin_exit_code)"
    echo "${JOVIAL_PROMPT_UP_CORNER}${prompts[host]}${prompts[user]}${prompts[path]}${prompts[dev_env]}${prompts[git_info]}${prompts[current_time]}"
    echo "${JOVIAL_PROMPT_DOWN_CORNER}$(type_tip_pointer) $(venv_info_prompt) "
}

add-zsh-hook precmd git_action_prompt_hook
git_action_prompt_hook

PROMPT='$(gen_jovial_prompt)'
