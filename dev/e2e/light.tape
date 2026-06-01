# vhs tape: render jovial under a LIGHT terminal background.
# usage: handled by render.sh (runs inside the preview container).
#
# vhs ref: https://github.com/charmbracelet/vhs

Output "/work/dev/e2e/output/light.gif"

Set Shell "bash"
Set FontSize 20
Set Width 1180
Set Height 820
Set Padding 26
# light terminal background; 256-color codes use xterm's fixed palette
Set Theme { "name": "jovial-light", "background": "#FAFAFA", "foreground": "#2A2A2A", "cursor": "#2A2A2A", "selection": "#D6D6D6", "black": "#2A2A2A", "white": "#FAFAFA", "brightBlack": "#555555", "brightWhite": "#FFFFFF" }

# launch the themed shell with the mode forced, so the preview is deterministic
Hide
Type "clear"  Enter
Type "JOVIAL_THEME_MODE=light zsh"  Enter
Sleep 1.5s
Type "clear"  Enter
Sleep 500ms
Show

# node project (clean git) -> host / user / path / git-clean / dev-env.node
Type "cd ~/Project/node-demo"  Sleep 400ms  Enter
Sleep 1.2s

# golang project, made dirty -> git-dirty colors + dev-env.golang
Type "cd ~/Project/golang-demo"  Sleep 400ms  Enter
Sleep 1s
Type "echo '// touch' >> go.mod"  Sleep 300ms  Enter
Sleep 1.2s

# python project with venv active -> venv segment + dev-env.python
Type "cd ~/Project/python-demo && source venv/bin/activate"  Sleep 400ms  Enter
Sleep 1.5s

# a failing command -> exit-code + elapsed pin colors on the next prompt
Type "false"  Sleep 300ms  Enter
Sleep 1s

