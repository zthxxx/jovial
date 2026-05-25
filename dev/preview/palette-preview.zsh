#!/usr/bin/env zsh

# palette-preview.zsh
#
# Generate a standalone HTML page that previews both jovial color palettes
# (JOVIAL_PALETTE_DARK and JOVIAL_PALETTE_LIGHT) side by side, so palette
# tweaks can be eyeballed in a browser without flipping the real terminal
# between its light and dark profiles.
#
# Why a generator instead of a static HTML file:
#   the palette values are read straight from jovial.zsh-theme, so the preview
#   never drifts out of sync with the theme. The only constant baked in here is
#   the xterm 256-color -> hex mapping, which is a fixed, well-known table that
#   is computed (not hard-coded) below.
#
# What it renders, per variant:
#   - a swatch grid of every palette key with its resolved hex value
#   - a few representative mock prompt lines exercising every color in context,
#     on both a plain and a tinted background (to check contrast on each)
#
# Scope note:
#   this previews colors only. It composes a mock prompt from the palette keys
#   rather than driving the real responsive/async renderer. For faithful
#   full-prompt screenshots use the sibling *.zsh scripts together with
#   iterm2-jovial-preview-prefile.json (see README.md in this directory).
#
# Usage:
#   zsh dev/preview/palette-preview.zsh [OUTPUT.html]
#   zsh dev/preview/palette-preview.zsh --open        # generate then open in browser
#
# Default output path: dev/preview/palette-preview.html

emulate -L zsh
setopt no_unset pipe_fail

# --- argument parsing -------------------------------------------------------

local script_dir=${0:A:h}
local theme_file=${script_dir}/../../jovial.zsh-theme
local out_file=${script_dir}/palette-preview.html
local do_open=false

local arg
for arg in "$@"; do
    case ${arg} in
        --open) do_open=true ;;
        -*)     print -ru2 -- "unknown option: ${arg}"; return 1 ;;
        *)      out_file=${arg} ;;
    esac
done

if [[ ! -f ${theme_file} ]]; then
    print -ru2 -- "cannot find theme file: ${theme_file}"
    return 1
fi

# --- load palettes from the theme ------------------------------------------

# Pin the variant so sourcing the theme does not fire the OSC 11 background
# query against this script's tty; we only need the two source-of-truth arrays,
# not the resolved JOVIAL_PALETTE.
typeset -g JOVIAL_THEME_MODE=dark
source ${theme_file}

if (( ${#JOVIAL_PALETTE_DARK} == 0 || ${#JOVIAL_PALETTE_LIGHT} == 0 )); then
    print -ru2 -- "theme did not define JOVIAL_PALETTE_DARK / JOVIAL_PALETTE_LIGHT"
    return 1
fi

# --- xterm 256-color index -> #rrggbb --------------------------------------

# Standard 16 ANSI base colors (indexes 0..15).
local -a xterm_base=(
    000000 800000 008000 808000 000080 800080 008080 c0c0c0
    808080 ff0000 00ff00 ffff00 0000ff ff00ff 00ffff ffffff
)

# Convert a 256-color index to "#rrggbb", echoing the result.
@palette.hex-of-256() {
    local -i n=$1

    # 0..15: fixed ANSI table
    if (( n < 16 )); then
        print -r -- "#${xterm_base[n + 1]}"
        return
    fi

    # 232..255: 24-step grayscale ramp
    if (( n >= 232 )); then
        local -i level=$(( 8 + (n - 232) * 10 ))
        printf '#%02x%02x%02x\n' ${level} ${level} ${level}
        return
    fi

    # 16..231: 6x6x6 color cube. Each channel step maps 0 -> 0, else 55 + s*40.
    local -i i=$(( n - 16 ))
    local -i ri=$(( i / 36 )) gi=$(( (i / 6) % 6 )) bi=$(( i % 6 ))
    local -i r=$(( ri == 0 ? 0 : 55 + ri * 40 ))
    local -i g=$(( gi == 0 ? 0 : 55 + gi * 40 ))
    local -i b=$(( bi == 0 ? 0 : 55 + bi * 40 ))
    printf '#%02x%02x%02x\n' ${r} ${g} ${b}
}

# Parse a palette value such as '%B%F{130}%}' and echo "<hex> <bold:0|1>".
# Falls back to "inherit 0" when no %F{...} is present.
@palette.parse-value() {
    local value=$1
    local -i bold=0
    [[ ${value} == *'%B'* ]] && bold=1

    # strip optional leading zeros from the index so it is read as decimal
    if [[ ${value} =~ '%F\{0*([0-9]+)\}' ]]; then
        print -r -- "$(@palette.hex-of-256 ${match[1]}) ${bold}"
    else
        print -r -- "inherit ${bold}"
    fi
}

# --- HTML emission helpers --------------------------------------------------

# Stable display order so the output is deterministic (assoc arrays are not).
local -a palette_keys=(
    host user root path git venv
    time elapsed exit.mark exit.code
    conj. typing normal success error
    dev-env.node dev-env.go dev-env.php dev-env.python
)

local html=''
@emit() { html+="$1"$'\n' }

# Return an HTML <span> for `text` colored by `key` within `variant`.
# `variant` is 'dark' or 'light'.
@palette.span() {
    local variant=$1 key=$2 text=$3
    local value
    if [[ ${variant} == light ]]; then
        value=${JOVIAL_PALETTE_LIGHT[${key}]-}
    else
        value=${JOVIAL_PALETTE_DARK[${key}]-}
    fi

    local parsed=("${(@s: :)$(@palette.parse-value ${value})}")
    local hex=${parsed[1]} bold=${parsed[2]}
    local weight=''
    (( bold )) && weight='font-weight:700;'
    print -r -- "<span style=\"color:${hex};${weight}\">${text}</span>"
}

# Build a full mock prompt block for one variant, exercising every color.
# `bg`/`fg` set the panel background and default text color.
@palette.mock-panel() {
    local variant=$1 bg=$2 fg=$3

    @emit "<div class=\"panel\" style=\"background:${bg};color:${fg}\">"

    # scene 1: clean tree, node dev-env, pinned time
    @emit "$(@palette.span ${variant} normal '╭─[')$(@palette.span ${variant} host 'MacBook')$(@palette.span ${variant} normal '] ')$(@palette.span ${variant} conj. 'as ')$(@palette.span ${variant} user 'zthxxx')$(@palette.span ${variant} conj. ' in ')$(@palette.span ${variant} path '~/Project/Shell/jovial')$(@palette.span ${variant} conj. ' on ')$(@palette.span ${variant} normal '(')$(@palette.span ${variant} git 'master')$(@palette.span ${variant} success ' ✔')$(@palette.span ${variant} normal ') ')$(@palette.span ${variant} conj. 'using ')$(@palette.span ${variant} dev-env.node 'node v20.10.0')   $(@palette.span ${variant} time '23:14:08')"
    @emit "$(@palette.span ${variant} normal '╰─➤ ')$(@palette.span ${variant} typing 'git status')"
    @emit ''

    # scene 2: root, dirty tree, elapsed + exit code, venv
    @emit "$(@palette.span ${variant} normal '╭─[')$(@palette.span ${variant} host 'server')$(@palette.span ${variant} normal '] ')$(@palette.span ${variant} conj. 'as ')$(@palette.span ${variant} root 'root')$(@palette.span ${variant} conj. ' in ')$(@palette.span ${variant} path '/etc/nginx')$(@palette.span ${variant} conj. ' on ')$(@palette.span ${variant} normal '(')$(@palette.span ${variant} git 'main')$(@palette.span ${variant} error ' ✘✘✘')$(@palette.span ${variant} normal ')')   $(@palette.span ${variant} time '23:14:08')"
    @emit "$(@palette.span ${variant} normal '╰─➤ ')$(@palette.span ${variant} elapsed '~3s') $(@palette.span ${variant} exit.mark 'exit:')$(@palette.span ${variant} exit.code '1') $(@palette.span ${variant} normal '(')$(@palette.span ${variant} venv 'venv')$(@palette.span ${variant} normal ') ')$(@palette.span ${variant} typing 'pip install -r requirements.txt')"
    @emit ''

    # scene 3: remaining dev-env languages
    @emit "$(@palette.span ${variant} normal '╭─[')$(@palette.span ${variant} host 'MacBook')$(@palette.span ${variant} normal '] ')$(@palette.span ${variant} conj. 'in ')$(@palette.span ${variant} path '~/work/api')$(@palette.span ${variant} conj. ' using ')$(@palette.span ${variant} dev-env.go 'Golang 1.22.0')  $(@palette.span ${variant} dev-env.php 'php 8.3.2')  $(@palette.span ${variant} dev-env.python 'Python 3.12.1')"
    @emit "$(@palette.span ${variant} normal '╰─➤ ')$(@palette.span ${variant} typing 'make build')"

    @emit "</div>"
}

# Build the swatch grid for one variant.
@palette.swatch-grid() {
    local variant=$1
    @emit "<div class=\"swatches\">"
    local key value parsed hex bold
    for key in ${palette_keys}; do
        if [[ ${variant} == light ]]; then
            value=${JOVIAL_PALETTE_LIGHT[${key}]-}
        else
            value=${JOVIAL_PALETTE_DARK[${key}]-}
        fi
        parsed=("${(@s: :)$(@palette.parse-value ${value})}")
        hex=${parsed[1]} bold=${parsed[2]}
        local bold_tag=''
        (( bold )) && bold_tag=' <em>B</em>'
        @emit "<div class=\"swatch\"><span class=\"chip\" style=\"background:${hex}\"></span><code>${key}</code><span class=\"hex\">${hex}${bold_tag}</span></div>"
    done
    @emit "</div>"
}

# --- compose the document ---------------------------------------------------

@emit '<!doctype html>'
@emit '<html lang="en"><head><meta charset="utf-8">'
@emit '<title>jovial palette preview</title>'
@emit '<style>'
@emit '  :root { --mono: "JetBrains Mono", "Menlo", "Monaco", "Courier New", monospace; }'
@emit '  body { margin: 0; padding: 28px; background: #222; color: #ccc; font-family: var(--mono); display: flex; flex-direction: column; gap: 28px; }'
@emit '  h2 { font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 14px; letter-spacing: .04em; color: #bbb; margin: 0 0 10px; }'
@emit '  .row { display: flex; gap: 16px; flex-wrap: wrap; }'
@emit '  .panel { flex: 1 1 460px; padding: 18px 22px; border-radius: 8px; font-size: 14px; line-height: 1.6; white-space: pre; overflow-x: auto; }'
@emit '  .swatches { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 8px; margin-top: 14px; }'
@emit '  .swatch { display: flex; align-items: center; gap: 8px; padding: 6px 10px; background: #2c2c2c; border-radius: 6px; font-size: 12px; }'
@emit '  .chip { width: 18px; height: 18px; border-radius: 4px; flex: none; box-shadow: inset 0 0 0 1px rgba(255,255,255,.15); }'
@emit '  .swatch code { color: #ddd; }'
@emit '  .swatch .hex { margin-left: auto; color: #888; font-family: var(--mono); }'
@emit '  .swatch .hex em { color: #e0a; font-style: normal; }'
@emit '  .note { font-family: -apple-system, sans-serif; font-size: 12px; color: #888; }'
@emit '</style></head><body>'

@emit '<div>'
@emit '<h2>DARK — JOVIAL_PALETTE_DARK</h2>'
@emit '<div class="row">'
@palette.mock-panel dark '#1e1e1e' '#d0d0d0'
@palette.mock-panel dark '#282828' '#d0d0d0'
@emit '</div>'
@palette.swatch-grid dark
@emit '</div>'

@emit '<div>'
@emit '<h2>LIGHT — JOVIAL_PALETTE_LIGHT</h2>'
@emit '<div class="row">'
@palette.mock-panel light '#fdfdfd' '#1a1a1a'
@palette.mock-panel light '#fdf6e3' '#2a2a2a'
@emit '</div>'
@palette.swatch-grid light
@emit '</div>'

@emit '<p class="note">Generated by dev/preview/palette-preview.zsh — values read live from jovial.zsh-theme.</p>'
@emit '</body></html>'

# --- write & optionally open ------------------------------------------------

print -rn -- ${html} > ${out_file}
print -r -- "wrote ${out_file}"

if [[ ${do_open} == true ]]; then
    if (( ${+commands[open]} )); then
        open ${out_file}
    elif (( ${+commands[xdg-open]} )); then
        xdg-open ${out_file}
    else
        print -ru2 -- "no opener found; open ${out_file} manually"
    fi
fi
