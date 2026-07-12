#!/usr/bin/env zsh
#
# Unit test for @jov.theme-mode-from-colorfgbg: the zero-cost COLORFGBG hint that
# lets terminals exporting it (iTerm2, rxvt, Konsole) skip the OSC 11 query.
# No tty needed. Exits non-zero on any failure.
#
# Usage: zsh dev/unit/colorfgbg-test.zsh

local self_dir="${0:A:h}"
local theme_file="${self_dir}/../../jovial.zsh-theme"
source "${theme_file}" >/dev/null 2>&1

# each case: "COLORFGBG-value => expected-mode" ('-' means inconclusive/no change)
local -a cases=(
    '0;15 => light'           # iTerm2 light (fg black / bg white)
    '15;0 => dark'            # fg white / bg black
    '0;default;15 => light'   # 3-field form (bg is last)
    '15;default;0 => dark'
    '0;7 => light'            # bg 7 (white) -> light
    '0;8 => dark'             # bg 8 (bright black / dark gray) -> dark
    '0;6 => dark'             # bg 6 (cyan) -> dark
    '0;9 => light'            # bg 9 (bright) -> light
    'default;default => -'    # not numeric -> inconclusive
    ' => -'                   # unset/empty -> inconclusive
)

local failed=0 spec value expected
for spec in "${cases[@]}"; do
    value="${spec%% => *}"
    expected="${spec##* => }"

    if [[ ${value} == ' ' ]]; then
        unset COLORFGBG
    else
        COLORFGBG="${value}"
    fi
    JOVIAL_THEME_MODE=''
    @jov.theme-mode-from-colorfgbg
    local rc=$?

    local got="${JOVIAL_THEME_MODE:--}"
    # inconclusive must return non-zero and leave the mode unset
    if [[ ${expected} == '-' ]]; then
        if (( rc == 0 )) || [[ ${got} != '-' ]]; then
            print -r -- "[FAIL] COLORFGBG='${value}' expected inconclusive, got rc=${rc} mode=${got}"
            (( failed++ ))
            continue
        fi
    elif (( rc != 0 )) || [[ ${got} != ${expected} ]]; then
        print -r -- "[FAIL] COLORFGBG='${value}' expected ${expected}, got rc=${rc} mode=${got}"
        (( failed++ ))
        continue
    fi
    print -r -- "[PASS] COLORFGBG='${value}' -> ${got}"
done

if (( failed )); then
    print -r -- "${failed} case(s) failed"
    exit 1
fi
print -r -- "all ${#cases} cases passed"
