# Shared demo flow for the palette preview tapes -- `Source`d by light.tape
# and dark.tape, which differ only in their `Output` / `Set Theme` /
# `Env JOVIAL_THEME_MODE` settings (vhs ignores settings inside sourced
# tapes, so this file holds commands only).
#
# The theme mode is forced through the JOVIAL_THEME_MODE env var set by the
# sourcing tape, which makes the preview deterministic regardless of whether
# xterm.js answers OSC 11 queries.
#
# vhs ref: https://github.com/charmbracelet/vhs

Hide
Type "clear"  Enter
# prepare the demo workspace (copy example projects, git init, venv) then
# launch the themed shell -- chained with `&&` so the shell can't start before
# setup finishes (config from the mounted dev/cases/.zshrc; the mode comes
# from the JOVIAL_THEME_MODE env var set by the sourcing tape)
Type "zsh /work/dev/cases/setup.zsh && ZDOTDIR=/work/dev/cases zsh"  Enter
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
