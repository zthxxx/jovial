# vhs tape: TRUE end-to-end check of terminal background auto-detection.
#
# Unlike light.tape / dark.tape (which force JOVIAL_THEME_MODE for
# deterministic palette previews), this tape launches the themed shell WITHOUT
# a preset mode, so jovial must detect the background by actually querying the
# real terminal emulator (ttyd's xterm.js answers OSC 11 with the theme
# background set below). The `Wait+Screen` calls double as assertions -- vhs
# exits non-zero when they time out:
#
#   - a LIGHT background is configured, dark is the fallback: seeing
#     `mode=light` proves the OSC 11 round-trip really happened
#   - the stderr canary proves detection didn't eat the shell's stderr
#     (regression guard for the `exec ... 2>/dev/null` redirect bug)
#   - `typed-ahead-42` output proves input typed before the first prompt
#     survives detection (typeahead replay)
#
# vhs ref: https://github.com/charmbracelet/vhs

Output "/work/dev/preview/output/detect.gif"

Set Shell "bash"
Set FontFamily "Hack Nerd Font Mono"
Set FontSize 40
Set Width 2360
Set Height 1640
Set Padding 52
Set TypingSpeed 8ms
Set WaitTimeout 30s
# light terminal background: detection must resolve `light` (fallback is dark)
Set Theme { "name": "jovial-light", "background": "#FAFAFA", "foreground": "#2A2A2A", "cursor": "#2A2A2A", "selection": "#D6D6D6", "black": "#2A2A2A", "white": "#FAFAFA", "brightBlack": "#555555", "brightWhite": "#FFFFFF" }

Hide
Type "clear"  Enter
# launch the themed shell with NO preset mode -- detection has to do the work;
# COLORFGBG is cleared so the OSC 11 query path (not the env hint) is exercised
Type "zsh /work/dev/cases/setup.zsh && ZDOTDIR=/work/dev/cases COLORFGBG= zsh"  Enter
# input typed BEFORE the first prompt: must be replayed, not eaten by detection
Type "echo typed-ahead-$((6*7))"  Enter
Wait /╰─/
Show

# typeahead replay assertion: the pre-typed command must have actually run
Wait+Screen /typed-ahead-42/

# detection assertion: light background must be detected (dark is the fallback,
# so this only passes when the OSC 11 reply was actually received and parsed)
Type "echo mode=$JOVIAL_THEME_MODE"  Enter
Wait+Screen /mode=light/

# stderr assertion: detection must not have swallowed the shell's stderr
Type "echo stderr-canary-$((6*7)) >&2"  Enter
Wait+Screen /stderr-canary-42/

# hold the final frame
Sleep 3s
