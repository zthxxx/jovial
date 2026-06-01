# vhs tape: render jovial under a LIGHT terminal background.
# The demo workspace + zsh config come from the mounted dev/e2e/cases/ dir
# (prepared at runtime by cases/setup.zsh), so edits need no image rebuild.
#
# vhs ref: https://github.com/charmbracelet/vhs

Output "/work/dev/e2e/output/light.gif"

Set Shell "bash"
# 2x resolution: font + canvas + padding all doubled, so the layout is unchanged
# but every render is twice the pixels (crisper screenshots / recordings).
Set FontSize 40
Set Width 2360
Set Height 1640
Set Padding 52
# light terminal background; 256-color codes use xterm's fixed palette
Set Theme { "name": "jovial-light", "background": "#FAFAFA", "foreground": "#2A2A2A", "cursor": "#2A2A2A", "selection": "#D6D6D6", "black": "#2A2A2A", "white": "#FAFAFA", "brightBlack": "#555555", "brightWhite": "#FFFFFF" }

Hide
Type "clear"  Enter
# prepare the demo workspace (copy example projects, git init, venv) then launch
# the themed shell -- chained with `&&` so the shell can't start before setup
# finishes (config from the mounted cases/.zshrc, mode forced for determinism)
Type "zsh /work/dev/e2e/cases/setup.zsh && ZDOTDIR=/work/dev/e2e/cases JOVIAL_THEME_MODE=light zsh"  Enter
Sleep 3s
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
