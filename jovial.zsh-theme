# jovial.zsh-theme
# ref: http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html

autoload -Uz add-zsh-hook

REV_GIT_DIR=""

iscommand() { command -v "$1" > /dev/null; }

is_git_dir() { command git rev-parse &>/dev/null; }

chpwd_git_dir_hook() { REV_GIT_DIR=`command git rev-parse --git-dir 2>/dev/null`; }
add-zsh-hook chpwd chpwd_git_dir_hook
chpwd_git_dir_hook

# rev_parse_find(filename:string, path:string, output:boolean)
# reverse from path to root wanna find the targe file
# output: whether show the file path
rev_parse_find() {
    local target="$1"
    local current_path="${2:-`pwd`}"
    local whether_output=${3:-false}
    local parent_path="`dirname $current_path`"
    while [[ ${parent_path} != "/" ]]; do
        if [[ -e ${current_path}/${target} ]]; then
            if $whether_output; then echo "$current_path"; fi
            return 0; 
        fi
        current_path="$parent_path"
        parent_path="`dirname $parent_path`"
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

type_tip_pointer() {
    if [[ -n ${REV_GIT_DIR} ]]; then
        if [[ -z $(git status -s 2> /dev/null) ]]; then
            echo '(๑˃̵ᴗ˂̵)و'
        else
            echo '(ﾉ˚Д˚)ﾉ'
        fi
    else
        echo '─➤'
    fi
}

current_dir() {
    echo "%{$terminfo[bold]$FG[228]%}%~%{$reset_color%}"
}

get_date_time() {
    # echo "%{$reset_color%}%D %*"
    date "+%m-%d %H:%M:%S"
}

get_space_size() {
    # ref: http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    local str="$1"
    local zero_pattern='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero_pattern/}}
    local size=$(( $COLUMNS - $len ))
    echo $size
}

get_fill_space() {
    local size=`get_space_size "$1"`
    printf "%${size}s"
}

previous_align_right() {
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    local new_line='
    '
    local str="$1"
    local align_site=`get_space_size "$str"`
    local previous_line="\033[1A"
    local cursor_back="\033[${align_site}G"
    echo "${previous_line}${cursor_back}${str}${new_line}"
}

align_right() {
    local str="$1"
    local align_site=`get_space_size "$str"`
    local cursor_back="\033[${align_site}G"
    local cursor_begin="\033[1G"
    echo "${cursor_back}${str}${cursor_begin}"
}

# pin the last commad exit code at previous line end
get_pin_exit_code() {
    local exit_code=$?
    if [[ $exit_code != 0 ]]; then
        local exit_code_warn=" %{$FG[246]%}exit:%{$fg_bold[red]%}${exit_code}%{$reset_color%}"
        previous_align_right "$exit_code_warn"
    fi
}

prompt_node_version() {
    if rev_parse_find "package.json" || rev_parse_find "node_modules"; then
        if iscommand node; then
            local NODE_PROMPT_PREFIX="%{$FG[239]%}using%{$FG[120]%} "
            local NODE_PROMPT="node `node -v`"
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
            local PHP_PROMPT_PREFIX="%{$FG[239]%}using%{$FG[105]%} "
            local PHP_PROMPT="php `php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
        else
            local PHP_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            local PHP_PROMPT="php%{$FG[242]%}]"
        fi
        echo "${PHP_PROMPT_PREFIX}${PHP_PROMPT}%{$reset_color%}"
    fi
}

prompt_python_version() {
    local PYTHON_PROMPT_PREFIX="%{$FG[239]%}using%{$FG[123]%} "
    if rev_parse_find "venv"; then
        local PYTHON_PROMPT="`$(rev_parse_find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}%{$reset_color%}"
    elif rev_parse_find "requirements.txt"; then
        if iscommand python; then
            local PYTHON_PROMPT="`python --version 2>&1`"
        else
            PYTHON_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            local PYTHON_PROMPT="Python%{$FG[242]%}]"
        fi
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}%{$reset_color%}"
    fi
}

dev_env_segment() {
    local SEGMENT_ELEMENTS=(node php python)
    for element in "${SEGMENT_ELEMENTS[@]}"; do
        local segment=`prompt_${element}_version`
        if [[ -n $segment ]]; then 
            echo "$segment "
            break
        fi
    done
}

git_action_prompt() {
    if [[ -z ${REV_GIT_DIR} ]]; then return 1; fi
    local action=""
    local rebase_merge="${REV_GIT_DIR}/rebase-merge"
    local rebase_apply="${REV_GIT_DIR}/rebase-apply"
	if [[ -d ${rebase_merge} ]]; then
        local rebase_step=`cat "${rebase_merge}/msgnum"`
        local rebase_total=`cat "${rebase_merge}/end"`
        local rebase_process="${rebase_step}/${rebase_total}"
		if [[ -f ${rebase_merge}/interactive ]]; then
			action="REBASE-i"
		else
			action="REBASE-m"
		fi
	elif [[ -d ${rebase_apply} ]]; then
        local rebase_step=`cat "${rebase_apply}/next"`
        local rebase_total=`cat "${rebase_apply}/last"`
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


VIRTUAL_ENV_DISABLE_PROMPT=true

ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[239]%}on%{$reset_color%} (%{$FG[159]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
GIT_PROMPT_DIRTY_STYLE="%{$reset_color%})%{$FG[202]%}✘✘✘"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%})%{$FG[040]%}✔"

git_action_prompt_hook() {
    if [[ -z ${REV_GIT_DIR} ]]; then return 1; fi
    ZSH_THEME_GIT_PROMPT_DIRTY="`git_action_prompt`${GIT_PROMPT_DIRTY_STYLE}"
}
add-zsh-hook precmd git_action_prompt_hook
git_action_prompt_hook

local JOVIAL_PROMPT_PREVIOUS='`get_pin_exit_code`'
local JOVIAL_PROMPT_HEAD='╭─$(get_host_name) %{$FG[239]%}as $(get_user_name) %{$FG[239]%}in $(current_dir) $(dev_env_segment)$(git_prompt_info)  '
local JOVIAL_PROMPT_FOOT='╰─$(type_tip_pointer) $(venv_info_prompt) '
local JOVIAL_PROMPT_HEAD_RIGHT_TIME='$(align_right " `get_date_time`")'

PROMPT="$JOVIAL_PROMPT_PREVIOUS
${JOVIAL_PROMPT_HEAD_RIGHT_TIME}${JOVIAL_PROMPT_HEAD}
$JOVIAL_PROMPT_FOOT"

