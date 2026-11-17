# Profiling is opt-in through the dedicated local debug shell.
# Zsh 5.9 zprof: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzprof-Module
zmodload zsh/datetime
zmodload zsh/zprof
typeset -gF _jovial_profile_started=$EPOCHREALTIME
typeset -ga _jovial_profile_names=()
typeset -ga _jovial_profile_times=()
_jovial_profile_mark() {
    _jovial_profile_names+=("$1")
    _jovial_profile_times+=("$EPOCHREALTIME")
}
_jovial_profile_precmd_start() {
    _jovial_profile_mark before-precmd
    add-zsh-hook -d precmd _jovial_profile_precmd_start
}
_jovial_profile_precmd_end() {
    _jovial_profile_mark precmd
    add-zsh-hook -d precmd _jovial_profile_precmd_end
}
_jovial_profile_finished() {
    _jovial_profile_mark first-prompt
    add-zle-hook-widget -d line-init _jovial_profile_finished
    local -F 3 previous=0 at=0 duration=0
    local -i i=1
    local json="{\"schemaVersion\":1,\"mode\":\"${JOVIAL_PROFILE_MODE}\",\"stages\":["
    for (( i=1; i <= ${#_jovial_profile_names}; i++ )); do
        (( at = ( ${_jovial_profile_times[i]} - _jovial_profile_started ) * 1000 ))
        (( duration = at - previous ))
        (( i > 1 )) && json+=','
        json+="{\"name\":\"${_jovial_profile_names[i]}\",\"atMs\":${at},\"durationMs\":${duration}}"
        previous=$at
    done
    local -F 6 report_started=$EPOCHREALTIME
    local zprof_encoded="$(zprof | base64 | tr -d '\n')"
    local -F 3 zprof_ms=$(( ( EPOCHREALTIME - report_started ) * 1000 ))
    json+="],\"totalMs\":${at},\"zprofMs\":${zprof_ms},\"zprofBase64\":\"${zprof_encoded}\"}"
    local encoded="$(print -rn -- "$json" | base64 | tr -d '\n')"
    printf '\033]777;jovial-profile;%s\007' "$encoded"
}
