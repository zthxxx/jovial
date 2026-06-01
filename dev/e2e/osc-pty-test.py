#!/usr/bin/env python3
# Faithful test for @jov.query-terminal-background:
# spin up a real PTY, run zsh on the slave (so /dev/tty works), and have the
# master act like a terminal emulator that answers the OSC 11 query with a chosen
# background color. Then assert the resolved JOVIAL_THEME_MODE and that NO reply
# bytes leaked into the shell input (the bug being fixed).
#
# Usage:
#   python3 osc-pty-test.py <theme_file>              # run the whole matrix
#   python3 osc-pty-test.py <theme_file> <reply_kind> # run one scenario
#     reply_kind: light-st | dark-st | light-bel | dark-bel | silent

import os, pty, sys, select, time

theme = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "jovial.zsh-theme")
ALL_KINDS = ["light-st", "dark-st", "light-bel", "dark-bel", "silent"]

# when no scenario is given, run the full matrix and exit non-zero on any failure
if len(sys.argv) <= 2:
    rc = 0
    for k in ALL_KINDS:
        rc |= os.system(f"{sys.executable} {os.path.abspath(__file__)} {theme} {k}")
    sys.exit(1 if rc else 0)

kind = sys.argv[2]

ESC = b"\x1b"
BEL = b"\x07"

# background color + terminator per scenario
COLORS = {
    "light": b"fafa/fafa/fafa",   # near-white -> light
    "dark":  b"1e1e/1f1f/2828",   # near-black -> dark
}
def make_reply(kind):
    if kind == "silent":
        return None
    tone, term = kind.split("-")
    body = ESC + b"]11;rgb:" + COLORS[tone]
    return body + (BEL if term == "bel" else ESC + b"\\")

reply = make_reply(kind)

# zsh script run on the slave side. after detection, drain any leftover input in
# RAW mode and report how many stray bytes were pending (must be 0 = no leak).
script = f"""
source {theme}
@jov.query-terminal-background
print -r -- "RESULT_MODE=${{JOVIAL_THEME_MODE}}"
leftover=''
typeset old="$(stty -g </dev/tty)"
stty raw -echo </dev/tty
while read -rs -k 1 -t 0.2 c </dev/tty; do leftover+="$c"; done
stty "$old" </dev/tty
print -r -- "RESULT_LEFTOVER=${{#leftover}}"
print -r -- "RESULT_DONE=1"
"""

pid, master = pty.fork()
if pid == 0:
    # child: replace stdin with a here-doc of the script via zsh -s is awkward;
    # instead exec zsh -c with the script directly
    os.environ["JOVIAL_THEME_DETECT_TIMEOUT"] = "0.5"
    os.execvp("zsh", ["zsh", "-f", "-c", script])
    os._exit(127)

# parent: behave like the terminal emulator
buf = b""
out = b""
answered = False
deadline = time.time() + 6
while time.time() < deadline:
    r, _, _ = select.select([master], [], [], 0.2)
    if master in r:
        try:
            data = os.read(master, 4096)
        except OSError:
            break
        if not data:
            break
        out += data
        buf += data
        # answer the first OSC 11 query we see
        if not answered and reply is not None and b"]11;?" in buf:
            os.write(master, reply)
            answered = True
    if b"RESULT_DONE=1" in out:
        break

os.close(master)
try:
    os.waitpid(pid, 0)
except OSError:
    pass

text = out.decode(errors="replace")
# the query echo (ESC ] 11 ; ? ST) can be glued before a RESULT line with no
# newline, so match the markers anywhere and capture up to the next whitespace
import re
def grab(key):
    m = re.search(key + r"=([^\s\x1b\\]*)", text)
    return m.group(1) if m else None
mode = grab("RESULT_MODE")
leftover = grab("RESULT_LEFTOVER")

expect_mode = "" if kind == "silent" else kind.split("-")[0]
ok_mode = (mode == expect_mode)
ok_leak = (leftover == "0")
status = "PASS" if (ok_mode and ok_leak) else "FAIL"
print(f"[{status}] kind={kind:11s} mode={mode!r} (expect {expect_mode!r}) leftover={leftover!r}")
sys.exit(0 if status == "PASS" else 1)
