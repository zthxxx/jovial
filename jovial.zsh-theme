# jovial.zsh-theme
# https://github.com/zthxxx/jovial


export JOVIAL_VERSION='2.6.1'


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
# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fsystem-Module
# provides `sysread` for a single raw read(2), used by terminal background detection
zmodload zsh/system
# provides `zselect` to race multiple file descriptors under one deadline,
# used by the first-paint budget window (see `@jov.first-paint-window`)
zmodload zsh/zselect

# expand and execute the PROMPT variable 
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
setopt prompt_subst

## Options like misc in ohmyzsh/lib/misc.zsh
## https://zsh.sourceforge.io/Doc/Release/Options.html

# Allow redirect to multiple streams: echo >file1 >file2
setopt multios
# Print job notifications in the long format by default.
setopt long_list_jobs
# Allow `#` comments even in interactive shells.
setopt interactive_comments

# disable oh-my-zsh's URL auto-escape feature by default, due to it's too slow for paste
# https://github.com/ohmyzsh/ohmyzsh/issues/5569
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/misc.zsh
export DISABLE_MAGIC_FUNCTIONS=true


# setup this flag for hidden python `venv` default prompt
# https://github.com/python/cpython/blob/3.10/Lib/venv/scripts/common/activate#L56
export VIRTUAL_ENV_DISABLE_PROMPT=true

# the default `TERM`` in `screen` command is 'linux', which will cause colorless in terminal, same with 'xterm',
# so that set it to a compatible colorful value.
# otherwise shouldn't override `TERM` if it's a specific user setting.
if [[ ${TERM} == 'linux' || ${TERM} == 'xterm' ]]; then
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
#   %B              => bold
#   %U              => underline
#   ${sgr_reset}    => reset all effect (provide by jovial)
#
# jovial provides two palettes, one tuned for a dark terminal background and one
# for a light background. on the first prompt render, jovial resolves the active
# theme mode (see `JOVIAL_THEME_MODE` and `@jov.theme-detect`) and redirects
# `JOVIAL_PALETTE` to the matching palette, so every downstream color read stays
# unchanged. the per-key meaning of each color is documented on the dark palette.
#
# colors for a dark terminal background
typeset -gA JOVIAL_PALETTE_DARK=(
    # hostname
    host '%F{157}'

    # common user name
    user '%F{253}'

    # only root user
    root '%B%F{203}'

    # current work dir path
    path '%B%F{227}%}'

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

    # development environment version tags (used by `@jov.prompt-*-version`)
    dev-env.node '%F{120}'
    dev-env.golang '%F{086}'
    dev-env.python '%F{123}'
    dev-env.php '%F{105}'
)

# colors for a light terminal background
# darker, more saturated tones so text keeps enough contrast on a bright background
typeset -gA JOVIAL_PALETTE_LIGHT=(
    # hostname
    host '%F{34}'

    # common user name
    user '%F{241}'

    # only root user
    root '%B%F{160}'

    # current work dir path
    path '%B%F{214}'

    # git status info (dirty or clean / rebase / merge / cherry-pick)
    git '%F{75}'

    # virtual env activate prompt for python
    venv '%F{30}'

    # current time when prompt render, pin at end-of-line
    time '%F{242}'

    # elapsed time of last command executed
    elapsed '%F{130}'

    # exit code of last command
    exit.mark '%F{102}'
    exit.code '%B%F{160}'

    # 'conj.': short for 'conjunction', like as, at, in, on, using
    conj. '%F{102}'

    # shell typing area pointer
    typing '%F{102}'

    # for other common case text color
    normal '%F{102}'

    success '%F{28}'
    error '%F{160}'

    # development environment version tags (used by `@jov.prompt-*-version`)
    dev-env.node '%F{35}'
    dev-env.golang '%F{30}'
    dev-env.python '%F{25}'
    dev-env.php '%F{56}'
)

# backward-compatible override slot (the pre-v2.6 single palette).
# kept empty by default; any key you set here is migrated into BOTH palettes
# above during `@jov.apply-theme-mode`, then this becomes the active palette.
# after theme resolution it holds a full copy of the resolved mode's colors.
typeset -gA JOVIAL_PALETTE=()

# the active theme mode, one of: 'light' | 'dark'
#
# - preset it yourself (as an env var, or in `~/.zshrc`) to force a palette and
#   skip terminal background detection entirely (zero extra startup cost)
# - leave it empty to let jovial auto-detect from the terminal background color,
#   falling back to 'dark' when the terminal can't be queried
typeset -g JOVIAL_THEME_MODE="${JOVIAL_THEME_MODE}"

# the *first paint budget*, in seconds: a hard cap on how long the first
# prompt may wait for everything slow -- the terminal's OSC 11 + DA1 reply,
# the git status check, and the dev-env probe, all racing in parallel inside
# this one shared window. whatever finishes in time joins the first render
# synchronously; whatever doesn't keeps running async and joins by rerendering
# the prompt once all of it is done (see `@jov.infer-prompt-rerender`).
# the OSC query is sent at theme source time, so its round-trip overlaps the
# rest of `~/.zshrc` and rarely spends any of this budget; a terminal that
# answers even later than this is handled by the zle reply guard.
# honors a value preset in the environment or before sourcing the theme.
typeset -gF JOVIAL_THEME_DETECT_TIMEOUT="${JOVIAL_THEME_DETECT_TIMEOUT:-0.3}"

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
    # datetime format provide by [`strftime(3)`](https://www.man7.org/linux/man-pages/man3/strftime.3.html)
    current-time.dynamic   '%H:%M:%S'
    current-time.suffix    ' '
)



#
# ########## Terminal Background / Theme Mode Detection ##########
#
# resolving the light/dark theme mode, cheapest source first:
#
#   1. `JOVIAL_THEME_MODE` preset       -- trusted as-is, zero cost
#   2. `COLORFGBG` env hint             -- zero cost, no tty round-trip
#   3. OSC 11 terminal query            -- one tty round-trip, overlapped:
#      the query is *sent* at theme source time (see the call at the bottom of
#      this file) and its reply *harvested* at first precmd, so the terminal
#      answers while the rest of `~/.zshrc` is still loading and the first
#      prompt (almost) never waits on it.
#
# the overlapped send needs `stty` to switch the tty for the whole time the
# reply may arrive. on a system without a usable `stty` (busybox builds
# without the applet -- OpenWrt routers, minimal containers -- or a tty it
# can't drive) the same query runs synchronously at first precmd instead,
# with nothing but the `read` builtin (see `@jov.theme-query-builtin`): the
# result is identical, the first prompt just pays one terminal round-trip
# (still capped by the first paint budget).
#
# in a non-interactive / tty-less shell (scripts, pipelines) only the two env
# checks above ever run -- nothing costly, no tty access, no subprocess.
#
# the first prompt waits at most the *first paint budget*
# (`JOVIAL_THEME_DETECT_TIMEOUT`) for the reply. when the terminal answers
# later than that -- with the first prompt already on screen -- a zle
# keybinding guard swallows the reply (which would otherwise be typed into the
# command line as garbage like `11;rgb:1e1e/...`), then applies the fresh mode
# and repaints on the spot.
#
# this works on local, SSH and inside-container (docker) sessions alike: the
# OSC escape is interpreted by the real terminal emulator at the far end of
# the pty, and its reply travels back the same channel.
#
# reply format (xterm OSC 11):  ESC ] 11 ; rgb:RRRR/GGGG/BBBB <terminator>
# each channel is 1-4 hex digits; <terminator> is BEL (\a) or ST (ESC \).
# the query is chased by a DA1 (Device Attributes, `ESC [ c`) whose reply
# (`ESC [ ... c`) acts as an end-of-answers sentinel, since terminals answer
# queries in order -- so completion is detected the instant it lands instead
# of betting on a fixed wait, and the timeout only caps terminals that never
# answer at all.
# refs:
#   https://invisible-island.net/xterm/ctlseqs/ctlseqs.html  (OSC 10/11, DA1)
#   https://en.wikipedia.org/wiki/ANSI_escape_code#OSC_(Operating_System_Command)_sequences

# in-flight query state (set by `@jov.theme-query-send`, consumed by
# `@jov.theme-query-harvest` / `@jov.theme-query-cleanup`)
typeset -g jovial_tty_fd='' jovial_tty_state=''
typeset -gi jovial_theme_query_inflight=0

# harvest output: the mode resolved from the reply ('light' / 'dark' / '') and
# any user keystrokes that arrived interleaved with it (see the replay widget)
typeset -g jovial_theme_query_result='' jovial_theme_typeahead=''

# the DA1 reply (CSI ... c) that ends the whole answer to the query; matched
# on its parameter bytes so typed-ahead arrow keys (`ESC [ A`) can't fake it
typeset -g jovial_theme_reply_end_regex=$'\e\\[[?0-9;]*c'

# request a theme (re-)resolution at next precmd; re-sourcing the theme file
# resets it to 1, so a re-source re-detects with fresh config
typeset -gi jovial_theme_detect_pending=1

# @jov.theme-mode-from-osc-reply( $reply_text )
# parse an OSC 11 reply and judge the background tone; sets `REPLY` to
# 'light' or 'dark', or returns 1 when no color payload is found
@jov.theme-mode-from-osc-reply() {
    [[ $1 =~ 'rgba?:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)' ]] || return 1

    # xterm scales each channel to its digit width (a 1-digit `f` means 0xff,
    # not 0x0f), so widen single-digit channels before taking the top byte
    local r_hex="${match[1]}" g_hex="${match[2]}" b_hex="${match[3]}"
    (( ${#r_hex} == 1 )) && r_hex="${r_hex}${r_hex}"
    (( ${#g_hex} == 1 )) && g_hex="${g_hex}${g_hex}"
    (( ${#b_hex} == 1 )) && b_hex="${b_hex}${b_hex}"

    local -i r=$(( 16#${r_hex[1,2]} ))
    local -i g=$(( 16#${g_hex[1,2]} ))
    local -i b=$(( 16#${b_hex[1,2]} ))

    # perceived luminance (ITU-R BT.601), range 0-255; >= 128 means light
    local -i luminance=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

    if (( luminance >= 128 )); then
        REPLY='light'
    else
        REPLY='dark'
    fi
}

# @jov.theme-split-reply( $harvested_bytes )
# split everything the harvest read into the terminal replies (one OSC 11
# reply, one DA1 reply) and whatever else was in the tty input queue -- which
# can only be keystrokes the user typed ahead while `~/.zshrc` was loading.
# sets `jovial_theme_query_result` (parsed mode or empty) and
# `jovial_theme_typeahead` (non-reply bytes, original order preserved).
@jov.theme-split-reply() {
    local raw="$1"
    jovial_theme_query_result=''
    jovial_theme_typeahead=''

    if @jov.theme-mode-from-osc-reply "${raw}"; then
        jovial_theme_query_result="${REPLY}"
    fi

    local typeahead='' rest="${raw}" pre=''

    # cut the OSC 11 reply:  ESC ] ... (BEL | ESC \)
    pre="${rest%%$'\e]'*}"
    if (( ${#pre} < ${#rest} )); then
        typeahead+="${pre}"
        rest="${rest[$(( ${#pre} + 1 )),-1]}"
        local bel_head="${rest%%$'\a'*}" st_head="${rest%%$'\e\\'*}"
        local -i bel_end=$(( ${#bel_head} < ${#rest} ? ${#bel_head} + 1 : 0 ))
        local -i st_end=$((  ${#st_head}  < ${#rest} ? ${#st_head}  + 2 : 0 ))
        local -i end=0
        if (( bel_end && st_end )); then
            (( end = bel_end < st_end ? bel_end : st_end ))
        else
            (( end = bel_end + st_end ))
        fi
        (( end )) || end=${#rest}    # unterminated reply: treat the tail as reply
        rest="${rest[$(( end + 1 )),-1]}"
    fi

    # cut the DA1 reply:  ESC [ ... c
    pre="${rest%%$'\e['*}"
    if (( ${#pre} < ${#rest} )); then
        typeahead+="${pre}"
        rest="${rest[$(( ${#pre} + 3 )),-1]}"    # also drop the `ESC [` itself
        local c_head="${rest%%c*}"
        if (( ${#c_head} < ${#rest} )); then
            rest="${rest[$(( ${#c_head} + 2 )),-1]}"
        else
            rest=''                              # unterminated: all reply
        fi
    fi

    jovial_theme_typeahead="${typeahead}${rest}"
}

# @jov.replay-typeahead()
# one-shot `zle-line-init` hook: push the keystrokes that the harvest had to
# read together with the query reply back into zle, exactly as if they were
# typed now -- so commands typed ahead of the first prompt survive detection
@jov.replay-typeahead() {
    if [[ -n ${jovial_theme_typeahead} ]]; then
        zle -U "${jovial_theme_typeahead}"
        jovial_theme_typeahead=''
    fi
    add-zle-hook-widget -d line-init @jov.replay-typeahead
}

# @jov.theme-osc-reply-guard()
# zle widget bound to the OSC 11 reply prefix (`ESC ] 11 ;`): it fires only
# when the terminal answers *after* detection already gave up, i.e. the reply
# lands while the line editor is reading. swallow the reply (instead of
# letting it type into the command line), then self-correct: apply the fresh
# mode and repaint the prompt on the spot.
@jov.theme-osc-reply-guard() {
    local seq="${KEYS}" key=''
    local -i guard=0
    while (( guard++ < 128 )); do
        read -t 0.05 -k 1 key 2>/dev/null || break
        seq+="${key}"
        # the whole answer ends with the DA1 reply (CSI ... c)
        [[ ${seq} =~ ${jovial_theme_reply_end_regex} ]] && break
    done

    @jov.theme-mode-from-osc-reply "${seq}" || return 0
    [[ ${REPLY} == "${JOVIAL_THEME_MODE}" ]] && return 0

    JOVIAL_THEME_MODE="${REPLY}"
    @jov.apply-theme-mode
    @jov.init-affix
    # recolor the cheap, synchronous prompt parts right away; the async parts
    # (git-info / dev-env) catch up with the palette on the next prompt
    @jov.set-host-name
    @jov.set-user-name
    @jov.set-current-dir
    @jov.set-typing-pointer
    @jov.set-venv-info
    zle reset-prompt 2>/dev/null
    return 0
}

# @jov.theme-csi-reply-guard()
# companion guard for a late CSI-style reply arriving alone (e.g. the DA1
# `ESC [ ? ... c` of a terminal that doesn't support OSC 11 at all): swallow
# up to the CSI final byte so it never types into the command line
@jov.theme-csi-reply-guard() {
    local key=''
    local -i guard=0
    while (( guard++ < 64 )); do
        read -t 0.02 -k 1 key 2>/dev/null || break
        [[ ${key} == [a-zA-Z~] ]] && break
    done
}

# @jov.theme-guard-bind()
# register the late-reply guards in the common keymaps (only meaningful in
# interactive shells where the line editor exists)
@jov.theme-guard-bind() {
    [[ -o zle ]] || return 0
    zle -N @jov.theme-osc-reply-guard
    zle -N @jov.theme-csi-reply-guard
    local keymap=''
    for keymap in emacs viins vicmd; do
        bindkey -M "${keymap}" $'\e]11;' @jov.theme-osc-reply-guard 2>/dev/null
        bindkey -M "${keymap}" $'\e[?'   @jov.theme-csi-reply-guard 2>/dev/null
    done
    return 0
}

# @jov.theme-query-cleanup()
# safety net (`zshexit` hook) for a shell that dies between query send and
# harvest: restore the tty mode so the terminal is never left in no-echo
@jov.theme-query-cleanup() {
    if [[ -n ${jovial_tty_fd} ]]; then
        stty "${jovial_tty_state}" <&${jovial_tty_fd} 2>/dev/null
        exec {jovial_tty_fd}>&-
        jovial_tty_fd=''
        jovial_tty_state=''
    fi
    add-zsh-hook -d zshexit @jov.theme-query-cleanup
}

# @jov.theme-query-send()
# fire the OSC 11 + DA1 query at the terminal and return immediately -- the
# reply is collected later by `@jov.theme-query-harvest`, so the round-trip
# overlaps whatever runs in between (ideally the rest of `~/.zshrc`).
#
# the controlling tty is switched to `-icanon -echo` until the harvest:
#   - `-icanon`: the reply (which has no newline) is readable immediately
#   - `-echo`  : reply bytes are not painted onto the screen meanwhile
# deliberately NOT `stty raw`: ISIG / OPOST stay on, so ^C keeps working and
# output printed during the window still renders normally. `stty` (a few ms,
# twice) is the only shell-out on this path -- never on per-prompt rendering.
#
# returns 1 -- with nothing sent and the tty untouched -- when the tty can't
# be opened, or when there is no `stty` to switch it (or it can't drive this
# tty): callers then fall back to `@jov.theme-query-builtin`.
@jov.theme-query-send() {
    (( jovial_theme_query_inflight )) && return 0

    # no external `stty` at all (busybox without the applet, e.g. OpenWrt):
    # skip even the fork attempt, the builtin collector takes over at precmd
    (( ${+commands[stty]} )) || return 1

    # the brace group keeps `2>/dev/null` scoped to this one open: a bare
    # `exec {fd}<>/dev/tty 2>/dev/null` would *permanently* redirect the
    # shell's stderr to /dev/null, since every redirection of `exec` persists
    { exec {jovial_tty_fd}<>/dev/tty } 2>/dev/null || {
        jovial_tty_fd=''
        return 1
    }

    # snapshot the tty mode, to restore verbatim at harvest (or shell exit);
    # bail out (leaving the tty untouched) if it can't be read
    jovial_tty_state="$(stty -g <&${jovial_tty_fd} 2>/dev/null)"
    if [[ -z ${jovial_tty_state} ]]; then
        exec {jovial_tty_fd}>&-
        jovial_tty_fd=''
        return 1
    fi

    stty -icanon -echo <&${jovial_tty_fd} 2>/dev/null

    # OSC 11 (ST terminated), then the DA1 sentinel (`ESC [ c`); like
    # `printf '\e]11;?\e\\\e[c' >&${fd}` but without the redirect overhead
    print -n -u ${jovial_tty_fd} '\e]11;?\e\\\e[c'

    jovial_theme_query_inflight=1
    add-zsh-hook zshexit @jov.theme-query-cleanup
    @jov.theme-guard-bind
    return 0
}

# @jov.theme-query-harvest( $deadline )
# collect the reply of a previously sent query, then restore the tty.
#
#   $1 -- absolute deadline (`EPOCHREALTIME`-based) to block until while the
#         reply is still missing; 0 (or absent) means take only what already
#         arrived. a responding terminal returns in a single round-trip thanks
#         to the DA1 sentinel, so the deadline only caps terminals that never
#         answer -- it does NOT slow the common case. a reply arriving after
#         the deadline is handled by the zle guard (`@jov.theme-osc-reply-guard`).
#
# the reply is read with `sysread` (raw read(2)) instead of a char-by-char
# `read` loop: the latter costs one syscall + timeout setup per byte (~300ms
# for a 25-byte reply), while `sysread` pulls each chunk at once in a few ms.
@jov.theme-query-harvest() {
    local -F deadline=${1:-0}

    jovial_theme_query_result=''
    jovial_theme_typeahead=''
    (( jovial_theme_query_inflight )) || return 1
    jovial_theme_query_inflight=0

    local reply='' chunk=''
    local -F remaining=0
    local -i guard=0 grace_used=0

    {
        while (( guard++ < 64 )); do
            remaining=$(( deadline - EPOCHREALTIME ))
            (( remaining > 0 )) || remaining=0
            if ! sysread -t ${remaining} -i ${jovial_tty_fd} chunk 2>/dev/null; then
                # nothing pending right now; when a reply has *started* to
                # arrive, grant one short grace period to let it finish rather
                # than leaking a half-consumed reply to the line editor
                if (( ! grace_used )) && \
                    [[ ${reply} == *$'\e]'* || ${reply} == *$'\e['* ]]; then
                    grace_used=1
                    deadline=$(( EPOCHREALTIME + 0.2 ))
                    continue
                fi
                break
            fi
            reply+="${chunk}"
            # the DA1 reply (CSI ... c) marks the end of all answers
            [[ ${reply} =~ ${jovial_theme_reply_end_regex} ]] && break
        done
    } always {
        # restore the tty mode and close the fd no matter what -- even on an
        # interrupt mid-read -- so the shell is never left in no-echo mode
        stty "${jovial_tty_state}" <&${jovial_tty_fd} 2>/dev/null
        exec {jovial_tty_fd}>&-
        jovial_tty_fd=''
        jovial_tty_state=''
        add-zsh-hook -d zshexit @jov.theme-query-cleanup
    }

    @jov.theme-reply-consume "${reply}"
}

# @jov.theme-query-builtin( $deadline )
# fallback collector for a system without a usable `stty` (busybox built
# without the applet -- OpenWrt routers, minimal containers -- or a tty that
# `stty -g` can't read): the whole round-trip, send + collect, in one
# synchronous step, using nothing but the `read` builtin.
#
#   $1 -- absolute deadline (`EPOCHREALTIME`-based) to wait for the reply
#         to *start*; 0 (or absent) means take only what already arrived.
#         same contract as `@jov.theme-query-harvest`.
#
# `read -s` (no echo) and `read -d` (non-canonical) switch the tty through
# zsh's own termios calls, for exactly the duration of each `read`, which
# also restores it by itself -- even on ^C or timeout -- so nothing external
# is needed and the tty can never be left in a bad state.
# the query rides as the `read` prompt string: `read` prints its prompt right
# AFTER it turned echo off, so the reply can't possibly land while echo is
# still on. each `read` returns at a `c` byte -- the final byte of the DA1
# sentinel (`ESC [ ... c`) -- and the loop goes on until the whole sentinel
# is in, since a `c` may also occur as a hex digit inside the color payload.
#
# without `stty` the tty can't be switched at theme source time, so the early
# overlapped send is off the table: the first prompt pays one full terminal
# round-trip here, capped by the deadline; a reply landing later than that is
# handled by the zle guard, as usual.
@jov.theme-query-builtin() {
    local -F deadline=${1:-0}

    jovial_theme_query_result=''
    jovial_theme_typeahead=''

    @jov.theme-guard-bind

    local reply='' chunk=''
    local -F remaining=0
    local -i guard=0
    # keep every byte verbatim: with a non-empty IFS `read` would strip the
    # leading / trailing whitespace of each chunk (typed-ahead spaces / Enter)
    local IFS=
    # OSC 11 (ST terminated), then the DA1 sentinel; sent by the first `read`
    # as its prompt (see above), the reads after it just collect the rest
    local prompt=$'\e]11;?\e\\\e[c'

    while (( guard++ < 64 )); do
        remaining=$(( deadline - EPOCHREALTIME ))
        (( remaining > 0 )) || remaining=0
        chunk=''
        # `-t` caps only the wait for the first byte of each read; once the
        # answer started arriving, the read blocks up to its `c` -- the same
        # grace a half-arrived reply gets in `@jov.theme-query-harvest`.
        # (no stderr redirect here: in a non-interactive shell `read` prints
        # its prompt -- our query -- to stderr rather than the shell's tty)
        read -rs -d c -t ${remaining} "chunk?${prompt}" || break
        prompt=''
        reply+="${chunk}c"
        [[ ${reply} =~ ${jovial_theme_reply_end_regex} ]] && break
    done

    @jov.theme-reply-consume "${reply}"
}

# @jov.theme-reply-consume( $collected_bytes )
# common tail of both collectors: split what was read into the terminal
# replies and the keystrokes typed ahead of them, schedule those keystrokes
# to be replayed into the line editor, and report whether a mode came out
@jov.theme-reply-consume() {
    @jov.theme-split-reply "$1"

    # give back any keystrokes that were typed ahead of the reply
    if [[ -n ${jovial_theme_typeahead} && -o zle ]]; then
        autoload -Uz add-zle-hook-widget
        add-zle-hook-widget line-init @jov.replay-typeahead
    fi

    [[ -n ${jovial_theme_query_result} ]]
}

# @jov.query-terminal-background()
# synchronous query: send + blocking harvest in one call, setting the global
# `JOVIAL_THEME_MODE` on success. kept as the self-contained primitive (and
# for direct use / tests); the normal startup path splits send and harvest
# apart to overlap the round-trip with `~/.zshrc` (see `@jov.theme-detect`).
@jov.query-terminal-background() {
    if (( jovial_theme_query_inflight )) || @jov.theme-query-send; then
        @jov.theme-query-harvest $(( EPOCHREALTIME + JOVIAL_THEME_DETECT_TIMEOUT )) || return 1
    else
        # nothing could be sent ahead (no usable `stty`): builtin round-trip
        @jov.theme-query-builtin $(( EPOCHREALTIME + JOVIAL_THEME_DETECT_TIMEOUT )) || return 1
    fi
    JOVIAL_THEME_MODE="${jovial_theme_query_result}"
}

# @jov.theme-mode-from-colorfgbg()
# resolve the mode from the `COLORFGBG` env var when present (exported by
# iTerm2, rxvt, Konsole, ...). it encodes "fg;bg" or "fg;<extra>;bg" ANSI
# color indices, so the background is the last `;`-separated field.
#
# this is a zero-cost hint -- no tty round-trip at all -- and lets terminals
# that export it skip the OSC 11 query entirely (notably iTerm2, which is
# slow to answer OSC 11).
#
# returns 0 and sets `JOVIAL_THEME_MODE` on success, or 1 if it can't decide.
@jov.theme-mode-from-colorfgbg() {
    # background color index is the last field
    local bg="${COLORFGBG##*;}"

    # only decide for a numeric ANSI index 0-15; anything else (empty,
    # 'default') is inconclusive -> let the caller fall back to the query
    [[ ${bg} == <0-15> ]] || return 1

    # ANSI base indices 0-6 and 8 are dark tones; 7 and 9-15 are light tones
    # (matches the long-standing vim `COLORFGBG` background heuristic)
    if (( bg == 7 || bg >= 9 )); then
        JOVIAL_THEME_MODE='light'
    else
        JOVIAL_THEME_MODE='dark'
    fi
}

# @jov.theme-detect( $deadline )
# resolve `JOVIAL_THEME_MODE` for this session, cheapest source first: an
# explicit preset, then the `COLORFGBG` env hint (both are pure env checks --
# the ONLY thing that ever runs in a non-interactive / tty-less shell), then
# the OSC 11 query. runs at first precmd (not at source time) so user
# `~/.zshrc` overrides are already in place.
#
# the query round-trip was normally already started at source time (see
# `@jov.theme-early-send`), so the harvest here usually returns immediately;
# a mute terminal is capped by the given absolute deadline (the first-paint
# budget) and a reply arriving even later than that is handled by the zle
# reply guard -- the prompt is never blocked longer than the budget.
@jov.theme-detect() {
    local -F deadline=${1:-0}

    # user preset the mode -> trust it, no detection at all
    [[ -n ${JOVIAL_THEME_MODE} ]] && return 0

    # cheap, no-I/O env hint; resolves instantly when the terminal exports it
    @jov.theme-mode-from-colorfgbg && return 0

    # no prompt is rendered without an interactive tty, so anything costly
    # (tty round-trip, stty forks) is pointless there: bail out, leaving only
    # the env checks above to have run
    [[ -o interactive && -t 0 && -t 1 ]] || return 0

    # start the query now if source time couldn't (e.g. the theme was loaded
    # by a deferred plugin manager while the line editor was already active),
    # then harvest -- this also restores the tty and recovers typeahead.
    # without a usable `stty` nothing was (or can be) sent ahead of time: run
    # the whole round-trip right here with the builtin-only collector instead
    if (( jovial_theme_query_inflight )) || @jov.theme-query-send; then
        @jov.theme-query-harvest ${deadline}
    else
        @jov.theme-query-builtin ${deadline}
    fi

    if [[ -n ${jovial_theme_query_result} ]]; then
        JOVIAL_THEME_MODE="${jovial_theme_query_result}"
    fi
    return 0
}

# @jov.theme-early-send()
# called when the theme file is sourced (see the bottom of this file): start
# the terminal query as early as possible so its round-trip overlaps the rest
# of `~/.zshrc`. skipped when a fast path will resolve the mode anyway, when
# there is no interactive tty, or when the line editor is already active
# (theme loaded deferred -- `@jov.theme-detect` then sends at first precmd).
@jov.theme-early-send() {
    [[ -n ${JOVIAL_THEME_MODE} ]] && return 0
    @jov.theme-mode-from-colorfgbg && return 0
    [[ -o interactive && -t 0 && -t 1 ]] || return 0
    zle 2>/dev/null && return 0
    @jov.theme-query-send
    return 0
}

# tracks whether the pre-v2.6 `JOVIAL_PALETTE` override slot was migrated:
# the migration must run at most once per session, because after it
# `JOVIAL_PALETTE` holds a full copy of the active palette, and migrating
# that again would overwrite BOTH palettes with a single mode's colors
typeset -gi jovial_palette_migrated=0

# @jov.apply-theme-mode()
# the "after-theme-detect" step: finalize the mode and redirect
# `JOVIAL_PALETTE` to the matching palette so all downstream color reads work
# unchanged. safe to call again mid-session (see the late-reply guard).
@jov.apply-theme-mode() {
    # default to dark when detection was skipped or inconclusive
    [[ ${JOVIAL_THEME_MODE} == 'light' || ${JOVIAL_THEME_MODE} == 'dark' ]] || JOVIAL_THEME_MODE='dark'

    # compatibility (pre-v2.6): a non-empty `JOVIAL_PALETTE` means the user
    # customized colors the old single-palette way; migrate those overrides
    # into both palettes so they keep taking effect regardless of the mode
    if (( ! jovial_palette_migrated )) && (( ${#JOVIAL_PALETTE} )); then
        local key=''
        for key in ${(k)JOVIAL_PALETTE}; do
            JOVIAL_PALETTE_DARK[${key}]="${JOVIAL_PALETTE[${key}]}"
            JOVIAL_PALETTE_LIGHT[${key}]="${JOVIAL_PALETTE[${key}]}"
        done
    fi
    jovial_palette_migrated=1

    # redirect the active palette to the resolved mode
    if [[ ${JOVIAL_THEME_MODE} == 'light' ]]; then
        JOVIAL_PALETTE=( "${(@kv)JOVIAL_PALETTE_LIGHT}" )
    else
        JOVIAL_PALETTE=( "${(@kv)JOVIAL_PALETTE_DARK}" )
    fi
}


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

    # bake palette *tokens* instead of colors: this worker is a fork, and at
    # fork time the palette may not be applied yet (theme detection races the
    # probes on the first prompt). the callback substitutes tokens with the
    # palette actually in effect at compose time (`@jov.detokenize-palette`),
    # so job start order and palette readiness are fully decoupled.
    # tokens are printable on purpose: the callback trims the output to its
    # first..last `[[:graph:]]` char, which would strip control characters.
    local key=''
    for key in ${(k)JOVIAL_PALETTE_DARK} ${(k)JOVIAL_PALETTE_LIGHT} ${(k)JOVIAL_PALETTE}; do
        JOVIAL_PALETTE[${key}]="<%jov:${key}%>"
    done

    ${handler}

    # always print new line to avoid handler has not any output that cannot trigger callback
    echo ''
}

# @jov.detokenize-palette( $text )
# replace the palette tokens a zpty worker baked into its output (see
# `@jov.zpty-worker`) with the currently applied `JOVIAL_PALETTE` colors;
# sets the substituted text into `REPLY`
@jov.detokenize-palette() {
    local text="$1" key=''
    for key in ${(k)JOVIAL_PALETTE}; do
        # the quoted pattern keeps `<`/`%` literal (not glob syntax)
        text="${text//"<%jov:${key}%>"/${JOVIAL_PALETTE[${key}]}}"
    done
    REPLY="${text}"
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


# @jov.first-paint-window( $deadline )
# spend what remains of the first-paint budget waiting on the still-running
# async jobs (git check / dev-env probe): race their fds under the one shared
# absolute deadline via `zselect`. whichever finishes in time is consumed
# right here -- through the exact same callback path as the async flow -- so
# it joins the first render synchronously; whatever is still running when the
# budget runs out stays on its `zle -F` handler and rerenders the prompt once
# all of it is done (see `@jov.infer-prompt-rerender`).
@jov.first-paint-window() {
    local -F deadline=${1:-0}

    while (( ${#jovial_async_jobs} )); do
        local -F remaining=$(( deadline - EPOCHREALTIME ))
        local -i last_poll=0
        # budget exhausted: one final zero-timeout poll still picks up jobs
        # that finished while the deadline was being spent elsewhere (e.g. on
        # a slow terminal reply), then stop waiting
        local -i centisec=0
        if (( remaining > 0 )); then
            centisec=$(( remaining * 100 + 1 ))
        else
            last_poll=1
        fi

        local -a select_args=() ready=()
        local fd=''
        for fd in ${(v)jovial_async_jobs}; do
            select_args+=( -r ${fd} )
        done

        # zselect timeout unit is centiseconds; non-zero status = timeout/error
        if ! zselect -t ${centisec} -a ready ${select_args} 2>/dev/null; then
            break
        fi
        # `ready` holds `-r <fd> ...`: strip the flag tokens, keep the fds
        for fd in ${ready:#-r}; do
            @jov.zle-callback-handler ${fd}
        done

        (( last_poll )) && break
    done
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

        # only call zle rerender while the line editor is actively displaying
        # a prompt; during precmd the parts land in the upcoming render anyway
        if zle 2>/dev/null; then
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
    local key=''
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

# pristine (pre-expansion) copy of `JOVIAL_AFFIXES`, captured on the first
# `@jov.init-affix` run (i.e. after `~/.zshrc` overrides are in place): the
# expansion below bakes palette colors into `JOVIAL_AFFIXES` in place, so any
# re-run -- e.g. when a late terminal reply switches the palette -- must
# re-expand from these templates, not from the already-expanded values
typeset -gA jovial_affix_templates=()

# for expanding `JOVIAL_AFFIXES` values after .zshrc config overrides;
# safe to run repeatedly: each run re-expands from the pristine templates
@jov.init-affix() {
    if (( ! ${#jovial_affix_templates} )); then
        jovial_affix_templates=( "${(@kv)JOVIAL_AFFIXES}" )
    else
        JOVIAL_AFFIXES=( "${(@kv)jovial_affix_templates}" )
    fi
    jovial_affix_lengths=()

    local key result
    for key in ${(k)JOVIAL_AFFIXES}; do
        # if a key ends in .dynamic then it's a dynamic value and should not be pre-expanded
        if [[ ${key} =~ '\.dynamic$' ]]; then
            continue
        fi

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
    : 'for python venv or virtualenv or miniconda'

    local venv_name=""

    if [[ -n ${CONDA_DEFAULT_ENV} && ${CONDA_DEFAULT_ENV} != "base"  ]]; then
        # for miniconda
        # need set `conda config --set changeps1 false` to avoid conda auto set prompt
        # `${...:t}` means basename of the path
        venv_name="${CONDA_DEFAULT_ENV:t}"

    elif [[ -n ${VIRTUAL_ENV} && ${VIRTUAL_ENV} != "base" ]]; then
        # for python venv or virtualenv
        # need set VIRTUAL_ENV_DISABLE_PROMPT to avoid python venv auto set prompt
        # `${...:t}` means basename of the path
        venv_name="${VIRTUAL_ENV:t}"
    fi

    if [[ -z ${venv_name} ]]; then
        jovial_parts[venv]=''
    else
        jovial_parts[venv]="${JOVIAL_AFFIXES[venv.prefix]}${JOVIAL_PALETTE[venv]}${venv_name}${JOVIAL_AFFIXES[venv.suffix]}"
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


# if path is too long, truncate path to fit terminal width
# only run if `jovial_part_lengths[path]` exceeds terminal width after 
#
# - `jovial_part_lengths[path]` set by `@jov.set-current-dir` on per chpwd hook
# - `@jov.update-path-truncate max_length` called each prompt render
@jov.update-path-truncate() {
    local -i max_length="${1}"

    # after truncated, the path length should not exceed `max_length`
    jovial_part_lengths[path-truncated]=${max_length} 

    # 1 is for display ellipsis `…`
    local -i truncate_length=$(( max_length - ${jovial_affix_lengths[path]} - 1 ))

    if (( truncate_length <= 0 )); then
        # if truncate length is less than or equal to 0, then no need to truncate
        jovial_parts[path-truncated]=""
        jovial_part_lengths[path-truncated]=0
        return
    fi

    local path_untruncated="${(%):-${JOVIAL_AFFIXES[current-dir]}}"
    local -i path_length=${#path_untruncated}
    local -i slice_start=$(( path_length - truncate_length))
    # ${name:offset}
    # ${name:offset:length}
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion
    local path_truncated="…${path_untruncated:${slice_start}}"

    jovial_parts[path-truncated]="${JOVIAL_AFFIXES[path.prefix]}${JOVIAL_PALETTE[path]}${path_truncated}${JOVIAL_AFFIXES[path.suffix]}"
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
    # do not print trailing whitespace for better interaction while terminal width in narrowing
    local suffix="${(MS)JOVIAL_AFFIXES[current-time.suffix]##*[[:graph:]]}"

    # expand datetime format by zsh `%D{string}` [Prompt-Expansion](https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#13_2_4_Date_and_time)
    # `{string}` is formatted by [`strftime(3)`](https://www.man7.org/linux/man-pages/man3/strftime.3.html)
    local current_time="${(%):-%D{${JOVIAL_AFFIXES[current-time.dynamic]}\}}"

    jovial_part_lengths[current-time]=$(( ${#current_time} + ${jovial_affix_lengths[current-time]} ))

    # format the current time and align it to the right
    current_time="${JOVIAL_AFFIXES[current-time.prefix]}${JOVIAL_PALETTE[time]}${current_time}${suffix}"
    @jov.align-right "${current_time}" ${jovial_part_lengths[current-time]} 'jovial_parts[current-time]'
}



@jov.prompt-node-version() {
    if @jov.rev-parse-find "package.json"; then
        if @jov.iscommand node; then
            local node_prompt_prefix="${JOVIAL_PALETTE[conj.]}using "
            local node_prompt="${JOVIAL_PALETTE[dev-env.node]}node `\node -v`"
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
            local go_prompt="${JOVIAL_PALETTE[dev-env.golang]}Golang ${go_version}"
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
            local php_prompt="${JOVIAL_PALETTE[dev-env.php]}php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
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
        local python_prompt="${JOVIAL_PALETTE[dev-env.python]}`$(@jov.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${python_prompt_prefix}${python_prompt}"
        return 0
    fi

    if @jov.rev-parse-find "requirements.txt"; then
        if @jov.iscommand python; then
            local python_prompt="${JOVIAL_PALETTE[dev-env.python]}`\python --version 2>&1`"
        elif @jov.iscommand python3; then
            local python_prompt="${JOVIAL_PALETTE[dev-env.python]}`\python3 --version 2>&1`"
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
    local segment_func=''
    for segment_func in ${JOVIAL_DEV_ENV_DETECT_FUNCS[@]}; do
        local segment=`${segment_func}`
        if [[ -n ${segment} ]]; then 
            echo "${segment}"
            break
        fi
    done
}

@jov.set-dev-env-info() {
    # the segment comes from a zpty worker with palette TOKENS baked in;
    # resolve them against the palette in effect right now (post-apply)
    local REPLY=''
    @jov.detokenize-palette "$1"
    local result="${REPLY}"
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
    flags=('--porcelain')
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

        local rebase_step="$(< ${rebase_apply}/next)"
        local rebase_total="$(< ${rebase_apply}/last)"
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

    # the first prompt gets one shared *first paint budget* (a hard cap on
    # how long it may wait): the terminal background reply, the git check and
    # the dev-env probe all race in parallel under this single absolute
    # deadline. whatever finishes in time joins the first render
    # synchronously; whatever doesn't keeps running async and joins via ONE
    # `zle reset-prompt` once all of it completed (@jov.infer-prompt-rerender)
    local -F first_paint_deadline=0
    if (( jovial_prompt_run_count == 1 )); then
        first_paint_deadline=$(( EPOCHREALTIME + JOVIAL_THEME_DETECT_TIMEOUT ))
    fi

    # start the slow probes as parallel zpty jobs right away, so they run
    # CONCURRENTLY with the theme-mode harvest below; their workers bake
    # palette tokens -- not colors -- so forking before the palette is applied
    # is safe (their callbacks colorize at compose time, always post-apply)
    @jov.async-dev-env-detect
    @jov.async-git-check

    if (( jovial_theme_detect_pending )); then
        # resolve light/dark theme mode and redirect `JOVIAL_PALETTE` before
        # any color or affix is expanded. done here (not at source time) so
        # that user `~/.zshrc` overrides are already in place when
        # migrated/redirected; the OSC query itself was normally already sent
        # at source time (see `@jov.theme-early-send`), so its round-trip
        # overlapped `~/.zshrc` and rarely spends any of the budget here.
        @jov.theme-detect ${first_paint_deadline}
        @jov.apply-theme-mode

        @jov.init-affix

        # cleared only after the whole block ran: if it was interrupted
        # midway (e.g. ^C while waiting on a mute terminal), the next precmd
        # retries instead of leaving the session half-initialized
        jovial_theme_detect_pending=0
    fi

    # spend whatever remains of the budget racing the parallel probes: their
    # callbacks compose parts with the palette and affixes just applied above
    if (( first_paint_deadline )); then
        @jov.first-paint-window ${first_paint_deadline}
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


    # prepare length accumulator of the left part prompt 
    # keep padding 1 space from left path to end or right part
    local -i total_length=$(( 1 + ${#JOVIAL_SYMBOL[corner.top]} ))

    local key=''
    for key in ${JOVIAL_PROMPT_PRIORITY[@]}; do
        local -i part_length=${jovial_part_lengths[${key}]}
        local prompt_part="${jovial_parts[${key}]}"

        if [[ ${key} == 'path' ]] ; then
            # if path size is exceed, truncate path to fit terminal width
            if (( total_length + part_length > COLUMNS )) ; then
                local remaining_length=$(( COLUMNS - total_length ))
                @jov.update-path-truncate "${remaining_length}"

                prompt_part="${jovial_parts[path-truncated]}"
                part_length=${jovial_part_lengths[path-truncated]}

                if (( part_length <= 0 )); then
                    # if path is empty after truncate, skip this part
                    continue
                fi
            fi
        elif (( total_length + part_length > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi
        
        prompt_is_emtpy=false

        total_length+=${part_length}
        prompts[${key}]="${sgr_reset}${prompt_part}"
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

# start terminal background detection as early as possible: the OSC query
# round-trip overlaps the rest of `~/.zshrc`, and the reply is harvested at
# first precmd (see the Terminal Background / Theme Mode Detection section)
@jov.theme-early-send
