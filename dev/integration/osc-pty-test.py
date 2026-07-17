#!/usr/bin/env python3
# Faithful test for @jov.query-terminal-background:
# spin up a real PTY, run zsh on the slave (so /dev/tty works), and have the
# master act like a terminal emulator that answers the OSC 11 query with a chosen
# background color AND the trailing DA1 (ESC [ c) sentinel the query now sends.
# Then assert the resolved JOVIAL_THEME_MODE, that NO reply bytes leaked into the
# shell input, and that detection finishes via the DA1 sentinel (not by burning the
# whole timeout) -- which is what makes it correct over high-latency SSH.
#
# Usage:
#   python3 osc-pty-test.py <theme_file>              # run the whole matrix
#   python3 osc-pty-test.py <theme_file> <reply_kind> # run one scenario
#     reply_kind: light-st | dark-st | light-bel | dark-bel
#               | unsupported | silent | laggy-dark | laggy-light

import os, pty, sys, select, time

theme = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "jovial.zsh-theme")
ALL_KINDS = [
    "light-st", "dark-st", "light-bel", "dark-bel",
    "unsupported",   # DA1 answered but OSC 11 ignored -> falls back, fast (no wait)
    "silent",        # nothing answered -> falls back after the full deadline
    "laggy-dark", "laggy-light",  # weak-network SSH: reply delayed but still detected
]

# deliberately FAR from the built-in default (0.3): the env preset must be
# honored by the theme (it used to be clobbered by a plain `typeset -gF ...`),
# so the 'silent' lower-bound timing assertion below (elapsed >= 0.8 * 0.6)
# can only pass when the preset takes effect -- the default would fail it
DETECT_TIMEOUT = 0.6   # JOVIAL_THEME_DETECT_TIMEOUT preset for the child

# when no scenario is given, run the full matrix and exit non-zero on any failure
if len(sys.argv) <= 2:
    rc = 0
    for k in ALL_KINDS:
        rc |= os.system(f"{sys.executable} {os.path.abspath(__file__)} {theme} {k}")
    sys.exit(1 if rc else 0)

kind = sys.argv[2]

ESC = b"\x1b"
BEL = b"\x07"
DA1_REPLY = ESC + b"[?1;2c"   # a typical Device Attributes response (CSI ? 1 ; 2 c)

# background color + terminator per scenario
COLORS = {
    "light": b"fafa/fafa/fafa",   # near-white -> light
    "dark":  b"1e1e/1f1f/2828",   # near-black -> dark
}

# per-scenario terminal behavior: does it answer OSC 11 / DA1, with what tone /
# terminator, and after how much simulated link latency (seconds).
def behavior(kind):
    if kind == "silent":
        return dict(osc=False, da1=False, tone=None, term=None, lag=0.0)
    if kind == "unsupported":
        return dict(osc=False, da1=True, tone=None, term=None, lag=0.0)
    if kind.startswith("laggy-"):
        tone = kind.split("-")[1]
        return dict(osc=True, da1=True, tone=tone, term="bel" if tone == "light" else "st", lag=0.25)
    tone, term = kind.split("-")
    return dict(osc=True, da1=True, tone=tone, term=term, lag=0.0)

beh = behavior(kind)

def osc_reply(beh):
    if not beh["osc"]:
        return b""
    body = ESC + b"]11;rgb:" + COLORS[beh["tone"]]
    return body + (BEL if beh["term"] == "bel" else ESC + b"\\")

# zsh script run on the slave side. time the detection, then drain any leftover
# input in RAW mode and report how many stray bytes were pending (must be 0 = no
# leak). RESULT_ELAPSED proves the DA1 sentinel short-circuits the wait.
script = f"""
source {theme}
typeset -F start=$EPOCHREALTIME
@jov.query-terminal-background
typeset -F elapsed=$(( EPOCHREALTIME - start ))
print -r -- "RESULT_MODE=${{JOVIAL_THEME_MODE}}"
print -r -- "RESULT_ELAPSED=${{elapsed}}"
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
    # child: exec zsh -c with the script directly
    os.environ["JOVIAL_THEME_DETECT_TIMEOUT"] = str(DETECT_TIMEOUT)
    os.execvp("zsh", ["zsh", "-f", "-c", script])
    os._exit(127)

# parent: behave like the terminal emulator. the shell sends OSC 11 + DA1 in one
# write; we key off the DA1 query (ESC [ c) so both have fully arrived, optionally
# sleep to emulate link latency, then reply OSC-then-DA1 in the real terminal order.
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
        # the DA1 query marks the end of the request the shell sent
        if not answered and (ESC + b"[c") in buf:
            if beh["lag"]:
                time.sleep(beh["lag"])
            if beh["osc"]:
                os.write(master, osc_reply(beh))
            if beh["da1"]:
                os.write(master, DA1_REPLY)
            answered = True
    if b"RESULT_DONE=1" in out:
        break

os.close(master)
try:
    os.waitpid(pid, 0)
except OSError:
    pass

text = out.decode(errors="replace")
# the query echo can be glued before a RESULT line with no newline, so match the
# markers anywhere and capture up to the next whitespace / escape
import re
def grab(key):
    m = re.search(key + r"=([^\s\x1b\\]*)", text)
    return m.group(1) if m else None
mode = grab("RESULT_MODE")
leftover = grab("RESULT_LEFTOVER")
elapsed = grab("RESULT_ELAPSED")

expect_mode = "" if kind in ("silent", "unsupported") else (
    kind.split("-")[1] if kind.startswith("laggy-") else kind.split("-")[0]
)
ok_mode = (mode == expect_mode)
ok_leak = (leftover == "0")

# timing invariant: only a terminal that ignores even DA1 (the "silent" case) may
# wait out the full timeout. every other scenario -- including the laggy ones and
# the unsupported-but-answers-DA1 one -- must return via the sentinel, comfortably
# before the deadline. this is the regression guard for the SSH / static-terminal
# wins the DA1 sentinel buys.
try:
    el = float(elapsed) if elapsed is not None else None
except ValueError:
    el = None
if kind == "silent":
    ok_time = (el is not None and el >= DETECT_TIMEOUT * 0.8)
else:
    ok_time = (el is not None and el < DETECT_TIMEOUT * 0.9)

status = "PASS" if (ok_mode and ok_leak and ok_time) else "FAIL"
print(f"[{status}] kind={kind:12s} mode={mode!r} (expect {expect_mode!r}) "
      f"leftover={leftover!r} elapsed={elapsed!r} ok_time={ok_time}")
sys.exit(0 if status == "PASS" else 1)
