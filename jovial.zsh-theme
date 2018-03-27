# jovial.zsh-theme
# ref: http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html

VIRTUAL_ENV_DISABLE_PROMPT=true
ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[239]%}on%{$reset_color%} (%{$FG[159]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%})%{$FG[202]%}✘✘✘"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%})%{$FG[040]%}✔"


function iscommand { command -v "$1" > /dev/null; }

function is_git {
  command git rev-parse --is-inside-work-tree &>/dev/null
}

function rev_parse_find {
    local target="$1"
    local current_path="${2:-`pwd`}"
    local whether_output=${3:-false}
    local parent_path="`dirname $current_path`"
    while [[ "$parent_path" != "/" ]]; do
        if [ -e "${current_path}/${target}" ]; then
            if $whether_output; then echo "$current_path"; fi
            return 0; 
        fi
        current_path="$parent_path"
        parent_path="`dirname $parent_path`"
    done
    return 1
}

function venv_info_prompt { [ $VIRTUAL_ENV ] && echo "$FG[242](%{$FG[159]%}$(basename $VIRTUAL_ENV)$FG[242])%{$reset_color%} "; }

function get_host_name { echo "[%{$FG[157]%}%m%{$reset_color%}]"; }

function get_user_name {
    local name_prefix="%{$reset_color%}"
    if [[ "$USER" == 'root' || "%UID" == "0" ]]; then
        name_prefix="%{$FG[203]%}"
    fi
    echo "${name_prefix}%n%{$reset_color%}"
}

function type_tip_pointer {
    if is_git; then
        echo '(ﾉ˚Д˚)ﾉ'
    else
        echo '─➤'
    fi
}

function current_dir {
    echo "%{$terminfo[bold]$FG[228]%}%~%{$reset_color%}"
}

function get_date_time {
    # echo "%{$reset_color%}%D %*"
    date "+%m-%d %H:%M:%S"
}

function get_space_size {
    # ref: http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    local str="$1"
    local zero_pattern='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero_pattern/}}
    local size=$(( $COLUMNS - $len ))
    echo $size
}

function get_fill_space {
    local size=`get_space_size "$1"`
    printf "%${size}s"
}

function previous_align_right {
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    local new_line='
    '
    local str="$1"
    local align_site=`get_space_size "$str"`
    local previous_line="\033[1A"
    local cursor_back="\033[${align_site}G"
    echo "${previous_line}${cursor_back}${str}${new_line}"
}

function align_right {
    local str="$1"
    local align_site=`get_space_size "$str"`
    local cursor_back="\033[${align_site}G"
    local cursor_begin="\033[1G"
    echo "${cursor_back}${str}${cursor_begin}"
}

function get_return_status {
    local exit_code=$?
    if [[ $exit_code != 0 ]]; then
        local exit_code_warn=" %{$FG[246]%}exit:%{$fg_bold[red]%}${exit_code}%{$reset_color%}"
        previous_align_right "$exit_code_warn"
    fi
}

function prompt_node_version {
    if rev_parse_find "package.json" || rev_parse_find "node_modules"; then
        if iscommand node; then
            NODE_PROMPT_PREFIX="%{$FG[239]%}using%{$FG[120]%} "
            NODE_PROMPT="node `node -v`"
        else
            NODE_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            NODE_PROMPT="Nodejs%{$FG[242]%}]"
        fi
        echo "${NODE_PROMPT_PREFIX}${NODE_PROMPT}"
    fi
}

function prompt_python_version {
    PYTHON_PROMPT_PREFIX="%{$FG[239]%}using%{$FG[123]%} "
    if rev_parse_find "venv"; then
        PYTHON_PROMPT="`$(rev_parse_find venv '' true)/venv/bin/python --version`"
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}"
    elif rev_parse_find "requirements.txt"; then
        if iscommand python; then
            PYTHON_PROMPT="`python --version`"
        else
            PYTHON_PROMPT_PREFIX="%{$FG[242]%}[%{$FG[009]%}need "
            PYTHON_PROMPT="Python%{$FG[242]%}]"
        fi
        echo "${PYTHON_PROMPT_PREFIX}${PYTHON_PROMPT}"
    fi
}

function dev_env_segment {
    local SEGMENT_ELEMENTS=(node python)
    for element in "${SEGMENT_ELEMENTS[@]}"; do
        local segment=`prompt_${element}_version`
        if [ -n "$segment" ]; then 
            echo "$segment "
            break
        fi
    done
}

local JOVIAL_PROMPT_PREVIOUS='`get_return_status`'
local JOVIAL_PROMPT_HEAD='╭─$(get_host_name) %{$FG[239]%}as $(get_user_name) %{$FG[239]%}in $(current_dir) $(dev_env_segment)$(git_prompt_info)  '
local JOVIAL_PROMPT_FOOT='╰─$(type_tip_pointer) $(venv_info_prompt) '
local JOVIAL_PROMPT_HEAD_RIGHT_TIME='$(align_right " `get_date_time`")'

PROMPT="$JOVIAL_PROMPT_PREVIOUS
${JOVIAL_PROMPT_HEAD_RIGHT_TIME}${JOVIAL_PROMPT_HEAD}
$JOVIAL_PROMPT_FOOT"

