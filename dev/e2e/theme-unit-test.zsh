#!/usr/bin/env zsh
#
# Layer-1 unit tests for the theme-mode helpers, each verified in isolation --
# no tty, no PTY, no docker needed. Exits non-zero on any failure.
#
# Covers:
#   - @jov.theme-mode-from-osc-reply   (parsing + single-hex-digit scaling)
#   - @jov.theme-split-reply           (reply vs typeahead separation)
#   - JOVIAL_THEME_DETECT_TIMEOUT      (env preset honored, not clobbered)
#   - non-interactive shells           (env checks only, nothing costly)
#   - @jov.apply-theme-mode            (palette migration runs at most once)
#   - @jov.init-affix                  (idempotent re-expansion from templates)
#
# Usage: zsh dev/e2e/theme-unit-test.zsh

local self_dir="${0:A:h}"
local theme_file="${self_dir}/../../jovial.zsh-theme"

typeset -gi failed=0
pass() { print -r -- "[PASS] $1" }
fail() { print -r -- "[FAIL] $1${2:+  -- $2}"; (( failed++ )) }
check() {  # check <name> <expected> <got>
    if [[ "$2" == "$3" ]]; then
        pass "$1"
    else
        fail "$1" "expected='$2' got='$3'"
    fi
}

source "${theme_file}" >/dev/null 2>&1


# ---------- @jov.theme-mode-from-osc-reply ----------

local -a osc_cases=(
    # input => expected REPLY ('!' means the call must fail)
    $'\e]11;rgb:1e1e/1f1f/2828\a=> dark'
    $'\e]11;rgb:fafa/fafa/fafa\e\\=> light'
    $'\e]11;rgba:ffff/ffff/ffff/ffff\a=> light'
    $'\e]11;rgb:f/f/f\a=> light'          # 1-digit channels scale to 0xff
    $'\e]11;rgb:1/1/1\a=> dark'
    $'\e]11;rgb:80/80/80\a=> light'       # 0x80 == 128 -> boundary is light
    $'no color here=> !'
)
local spec input expected
for spec in "${osc_cases[@]}"; do
    input="${spec%%=> *}"
    expected="${spec##*=> }"
    REPLY=''
    if @jov.theme-mode-from-osc-reply "${input}"; then
        check "osc-reply parse: ${${input//$'\e'/ESC}//$'\a'/BEL}" "${expected}" "${REPLY}"
    else
        check "osc-reply parse: ${${input//$'\e'/ESC}//$'\a'/BEL}" "${expected}" '!'
    fi
done


# ---------- @jov.theme-split-reply ----------

local osc_st=$'\e]11;rgb:1e1e/1f1f/2828\e\\'
local osc_bel=$'\e]11;rgb:fafa/fafa/fafa\a'
local da1=$'\e[?1;2c'

split-case() {  # split-case <name> <input> <expected_result> <expected_typeahead>
    @jov.theme-split-reply "$2"
    check "split-reply $1 / result" "$3" "${jovial_theme_query_result}"
    check "split-reply $1 / typeahead" "$4" "${jovial_theme_typeahead}"
}

split-case 'osc+da1'            "${osc_st}${da1}"                 'dark'  ''
split-case 'bel-osc+da1'        "${osc_bel}${da1}"                'light' ''
split-case 'typed-before'       $'ls -la\r'"${osc_st}${da1}"      'dark'  $'ls -la\r'
split-case 'typed-after'        "${osc_st}${da1}"$'echo hi\r'     'dark'  $'echo hi\r'
split-case 'typed-interleaved'  'ab'"${osc_st}"'cd'"${da1}"'ef'   'dark'  'abcdef'
split-case 'da1-only'           "${da1}"                          ''      ''
split-case 'typed-only'         $'plain typed\r'                  ''      $'plain typed\r'
split-case 'empty'              ''                                ''      ''


# ---------- @jov.detokenize-palette (zpty worker palette tokens) ----------

# workers bake `<%jov:KEY%>` tokens; the callback must substitute them with
# the palette in effect at compose time, so fork order never affects colors
() {
    local -A saved_palette=( "${(@kv)JOVIAL_PALETTE}" )
    JOVIAL_PALETTE=( conj. '%F{102}' dev-env.python '%F{123}' )
    REPLY=''
    @jov.detokenize-palette '<%jov:conj.%>using <%jov:dev-env.python%>Python 3.11'
    check 'detokenize-palette substitutes applied colors' \
        '%F{102}using %F{123}Python 3.11' "${REPLY}"
    @jov.detokenize-palette 'no tokens here'
    check 'detokenize-palette passes plain text through' \
        'no tokens here' "${REPLY}"
    JOVIAL_PALETTE=( "${(@kv)saved_palette}" )
}


# ---------- JOVIAL_THEME_DETECT_TIMEOUT env preset ----------

local timeout_got="$(JOVIAL_THEME_DETECT_TIMEOUT=0.15 zsh -f -c "source '${theme_file}' >/dev/null 2>&1; print \${JOVIAL_THEME_DETECT_TIMEOUT}")"
if (( timeout_got == 0.15 )); then
    pass 'detect timeout honors env preset (0.15)'
else
    fail 'detect timeout honors env preset (0.15)' "got '${timeout_got}'"
fi
timeout_got="$(zsh -f -c "source '${theme_file}' >/dev/null 2>&1; print \${JOVIAL_THEME_DETECT_TIMEOUT}")"
if (( timeout_got == 0.3 )); then
    pass 'detect timeout defaults to 0.3'
else
    fail 'detect timeout defaults to 0.3' "got '${timeout_got}'"
fi


# ---------- non-interactive shells: env checks only, nothing costly ----------

# a non-interactive shell (script / pipeline) must resolve the mode from env
# vars alone and finish fast -- no tty query, no waiting on any budget.
# `\e]11;?` in the output would betray a query; a slow run would betray a wait.
local ni_out
typeset -F ni_start=${EPOCHREALTIME}
ni_out="$(print 'from-pipe' | COLORFGBG='0;15' zsh -f -c "source '${theme_file}'; print \"NI-\${JOVIAL_THEME_MODE}\"" 2>&1)"
typeset -F ni_elapsed=$(( EPOCHREALTIME - ni_start ))
if [[ ${ni_out} == *'NI-light'* && ${ni_out} != *$'\e]11;'* ]] && (( ni_elapsed < 1.0 )); then
    pass "non-interactive: COLORFGBG env resolved, no query, fast (${ni_elapsed}s)"
else
    fail 'non-interactive: COLORFGBG env resolved, no query, fast' "out='${ni_out}' elapsed=${ni_elapsed}"
fi

ni_start=${EPOCHREALTIME}
ni_out="$(print 'from-pipe' | zsh -f -c "source '${theme_file}'; print \"NI2-\${JOVIAL_THEME_MODE:-unset}\"" 2>&1)"
ni_elapsed=$(( EPOCHREALTIME - ni_start ))
if [[ ${ni_out} == *'NI2-unset'* && ${ni_out} != *$'\e]11;'* ]] && (( ni_elapsed < 1.0 )); then
    pass "non-interactive: no env hint -> mode left unset, no query, fast (${ni_elapsed}s)"
else
    fail 'non-interactive: no env hint -> mode left unset, no query, fast' "out='${ni_out}' elapsed=${ni_elapsed}"
fi


# ---------- @jov.apply-theme-mode: migration runs at most once ----------

zsh -f -c "
source '${theme_file}' >/dev/null 2>&1
JOVIAL_PALETTE=( normal '%F{1}' )        # pre-v2.6 style user override
local light_typing=\"\${JOVIAL_PALETTE_LIGHT[typing]}\"
JOVIAL_THEME_MODE=dark
@jov.apply-theme-mode                     # JOVIAL_PALETTE becomes a full dark copy
JOVIAL_THEME_MODE=light
@jov.apply-theme-mode                     # re-apply must NOT migrate that copy back
[[ \"\${JOVIAL_PALETTE_LIGHT[typing]}\" == \"\${light_typing}\" ]] || exit 1
[[ \"\${JOVIAL_PALETTE[typing]}\" == \"\${light_typing}\" ]] || exit 2
[[ \"\${JOVIAL_PALETTE_LIGHT[normal]}\" == '%F{1}' ]] || exit 3
[[ \"\${JOVIAL_PALETTE[normal]}\" == '%F{1}' ]] || exit 4
"
case $? in
    0) pass 'apply-theme-mode: re-apply keeps palettes intact + override' ;;
    1) fail 'apply-theme-mode: re-apply keeps palettes intact + override' 'light palette polluted by dark values' ;;
    2) fail 'apply-theme-mode: re-apply keeps palettes intact + override' 'active palette not redirected to light' ;;
    *) fail 'apply-theme-mode: re-apply keeps palettes intact + override' 'user override lost (exit '"$?"')' ;;
esac


# ---------- @jov.init-affix: idempotent, re-expands from templates ----------

zsh -f -c "
source '${theme_file}' >/dev/null 2>&1
JOVIAL_THEME_MODE=dark
@jov.apply-theme-mode
@jov.init-affix
local len1=\${jovial_affix_lengths[host]} v1=\"\${JOVIAL_AFFIXES[host.prefix]}\"
@jov.init-affix
[[ \${jovial_affix_lengths[host]} == \${len1} ]] || exit 1   # lengths must not accumulate
[[ \"\${JOVIAL_AFFIXES[host.prefix]}\" == \"\${v1}\" ]] || exit 2
JOVIAL_THEME_MODE=light
@jov.apply-theme-mode
@jov.init-affix
[[ \"\${JOVIAL_AFFIXES[host.prefix]}\" != \"\${v1}\" ]] || exit 3  # palette switch re-colors
"
case $? in
    0) pass 'init-affix: idempotent + re-expands on palette switch' ;;
    1) fail 'init-affix: idempotent + re-expands on palette switch' 'affix lengths accumulated on re-run' ;;
    2) fail 'init-affix: idempotent + re-expands on palette switch' 'affix value changed on plain re-run' ;;
    *) fail 'init-affix: idempotent + re-expands on palette switch' 'palette switch did not re-color affixes' ;;
esac


# ---------- summary ----------

if (( failed )); then
    print -r -- "${failed} unit case(s) failed"
    exit 1
fi
print -r -- 'all unit cases passed'
