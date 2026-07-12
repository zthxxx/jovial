# vhs tape: render jovial under a LIGHT terminal background.
# The demo workspace + zsh config come from the mounted dev/e2e/cases/ dir
# (prepared at runtime by cases/setup.zsh), so edits need no image rebuild.
#
# vhs ref: https://github.com/charmbracelet/vhs

Output "/work/dev/e2e/output/light.gif"

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
# upper bound for the `Wait` calls below; each returns the instant the prompt
# matches, so this only caps the one genuinely slow step (workspace setup)
Set WaitTimeout 30s
# light terminal background; 256-color codes use xterm's fixed palette
Set Theme { "name": "jovial-light", "background": "#FAFAFA", "foreground": "#2A2A2A", "cursor": "#2A2A2A", "selection": "#D6D6D6", "black": "#2A2A2A", "white": "#FAFAFA", "brightBlack": "#555555", "brightWhite": "#FFFFFF" }

Hide
Type "clear"  Enter
# prepare the demo workspace (copy example projects, git init, venv) then launch
# the themed shell -- chained with `&&` so the shell can't start before setup
# finishes (config from the mounted cases/.zshrc, mode forced for determinism)
Type "zsh /work/dev/e2e/cases/setup.zsh && ZDOTDIR=/work/dev/e2e/cases JOVIAL_THEME_MODE=light zsh"  Enter
# block until the first jovial prompt's bottom corner renders (setup done + zsh up)
Wait /╰─/
Type "clear"  Enter
# post-clear prompt, then a beat for async segments before revealing
Wait /╰─/
Sleep 200ms
Show

# each step below: run the command, then `Wait /╰─/` blocks until the next
# jovial prompt's bottom corner (`╰─`) is drawn -- i.e. the command finished --
# instead of guessing a fixed sleep. the 200ms beat after lets the async
# git / dev-env segments settle before the next keystrokes.

# node project (clean git) -> host / user / path / git-clean / dev-env.node
Type "cd ~/Project/node-demo"  Enter
Wait /╰─/
Sleep 200ms

# golang project, made dirty -> git-dirty colors + dev-env.golang
Type "cd ~/Project/golang-demo"  Enter
Wait /╰─/
Sleep 200ms
Type "echo '// touch' >> go.mod"  Enter
Wait /╰─/
Sleep 200ms

# python project with venv active -> venv segment + dev-env.python
Type "cd ~/Project/python-demo && source venv/bin/activate"  Enter
Wait /╰─/
Sleep 200ms

# a failing command -> exit-code + elapsed pin colors on the next prompt
Type "false"  Enter
Wait /╰─/

# hold on the final frame for 3s after the whole demo completes
Sleep 3s
