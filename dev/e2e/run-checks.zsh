#!/usr/bin/env zsh
#
# Run the whole detection test suite (inside the `check` container, but works
# in any Linux/macOS environment with zsh + python3). Aggregates all layers:
#
#   layer 0  zsh -n                 theme parses
#   layer 1  theme-unit-test.zsh    helpers in isolation (no tty)
#   layer 1  colorfgbg-test.zsh     COLORFGBG fast path (no tty)
#   layer 2  osc-pty-test.py        query engine on a real PTY (function level)
#   layer 2  session-test.py        full interactive sessions, one per fix

local self_dir="${0:A:h}"
local repo="${self_dir}/../.."

typeset -i failed=0
run-check() {
    local title="$1"; shift
    print -r -- ""
    print -r -- "===> ${title}"
    if "$@"; then
        print -r -- "===> ${title}: OK"
    else
        print -r -- "===> ${title}: FAILED"
        (( failed++ ))
    fi
}

run-check 'theme syntax'          zsh -n "${repo}/jovial.zsh-theme"
run-check 'unit tests'            zsh "${self_dir}/theme-unit-test.zsh"
run-check 'colorfgbg fast path'   zsh "${self_dir}/colorfgbg-test.zsh"
run-check 'pty query matrix'      python3 "${self_dir}/osc-pty-test.py" "${repo}/jovial.zsh-theme"
run-check 'session scenarios'     python3 "${self_dir}/session-test.py" "${repo}/jovial.zsh-theme"

print -r -- ""
if (( failed )); then
    print -r -- "${failed} check group(s) FAILED"
    exit 1
fi
print -r -- 'all check groups passed'
