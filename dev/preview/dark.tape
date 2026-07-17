# vhs tape: render jovial under a DARK terminal background.
# The demo flow itself lives in preview-steps.tape (shared with light.tape);
# this file only carries the dark-specific settings.
#
# vhs ref: https://github.com/charmbracelet/vhs

Output "/work/dev/preview/output/dark.gif"

Set Shell "bash"
# 2x resolution: font + canvas + padding all doubled, so the layout is unchanged
# but every render is twice the pixels (crisper screenshots / recordings).
Set FontFamily "Hack Nerd Font Mono"
Set FontSize 40
Set Width 2360
Set Height 1640
Set Padding 52
# fast typing (~0.2s for a `cd <path>` command) so input doesn't slow the demo
Set TypingSpeed 8ms
# upper bound for the `Wait` calls in the shared steps; each returns the
# instant the prompt matches, so this only caps the one genuinely slow step
# (workspace setup)
Set WaitTimeout 30s
# dark terminal background; 256-color codes use xterm's fixed palette
Set Theme { "name": "jovial-dark", "background": "#1E1E1E", "foreground": "#D6D6D6", "cursor": "#D6D6D6", "selection": "#3A3A3A", "black": "#1E1E1E", "white": "#D6D6D6", "brightBlack": "#6A6A6A", "brightWhite": "#FFFFFF" }

# force the mode for determinism; the shared steps launch the themed shell
Env JOVIAL_THEME_MODE "dark"

Source dev/preview/preview-steps.tape
