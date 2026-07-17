#!/usr/bin/env python3
# Layer-2 session-level isolation tests for terminal background detection.
#
# Each scenario spawns a REAL interactive `zsh -d -i` on a PTY with the theme
# loaded from ZDOTDIR, while this process plays the terminal emulator on the
# master side (answering OSC 11 + DA1 with configurable latency / silence).
# One scenario per fix, each with its own throwaway cache dir, so every
# behavior is verified in isolation:
#
# The core contract -- the *first paint budget* (default 0.3s) is a hard cap:
# the OSC 11 reply, the git check and the dev-env probe all race IN PARALLEL
# inside one shared window; whatever finishes in time joins the first paint
# synchronously, whatever doesn't joins via async rerender, and the first
# paint is never delayed beyond the budget.
#
#   stderr-visible    `echo x >&2` works while detection ran (exec redirect fix)
#   typeahead-replay  input typed before the first prompt is replayed, not eaten
#   late-reply-guard  reply slower than the budget: swallowed by the zle guard,
#                     mode self-corrects on the spot, zero screen garbage
#   early-send        the query is sent at source time and its round-trip
#                     overlaps the rest of ~/.zshrc (no serial wait)
#   timeout-env       JOVIAL_THEME_DETECT_TIMEOUT preset in env is honored
#   ctrl-c-wait       ^C during the silent-terminal wait: shell stays alive,
#                     tty is restored (ISIG kept by `-icanon -echo`)
#   silent-fallback   a mute terminal costs exactly one budget, then dark
#   slow-git-parallel a slow `git status` cannot delay the first paint beyond
#                     the budget; the git segment joins via rerender
#   fast-git-sync     a fast git check finishes inside the budget and renders
#                     synchronously on the very first paint
#   shared-budget     mute terminal + slow git together still cost ONE budget
#                     (all waits share the same deadline, they never stack)
#   dev-env-color     the dev-env segment carries palette colors on the very
#                     first paint (workers bake palette TOKENS, resolved by
#                     the callback against the applied palette)
#   non-interactive   a tty-less / non-interactive shell does env checks only:
#                     no query bytes, no waiting
#   colorfgbg-skip    conclusive COLORFGBG -> no query bytes sent at all
#   preset-skip       preset JOVIAL_THEME_MODE -> no query bytes sent at all
#
# Command markers use `$((6*7))` so the *echoed input* (literal) can never
# satisfy an assertion -- only real execution output ("...-42") can.
#
# Usage:
#   python3 session-test.py <theme_file>              # whole matrix
#   python3 session-test.py <theme_file> <scenario>   # one scenario

import fcntl, os, pty, select, shutil, struct, subprocess, sys, tempfile, time
import termios

THEME = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else 'jovial.zsh-theme')

ESC = b'\x1b'
OSC_QUERY = ESC + b']11;?'
DA1_QUERY = ESC + b'[c'
DA1_REPLY = ESC + b'[?1;2c'
PROMPT_MARK = '╰─'.encode()   # the prompt's bottom corner `╰─`
RGB = {'light': b'fafa/fafa/fafa', 'dark': b'1e1e/1f1f/2828'}


def osc_reply(tone):
    return ESC + b']11;rgb:' + RGB[tone] + ESC + b'\\'


def make_git_repo(branch='e2e-branch'):
    """an empty git repo on the given branch (no commit needed: the branch
    name comes from .git/HEAD, which jovial reads without forking git)"""
    repo = tempfile.mkdtemp(prefix='jovial-repo-')
    subprocess.run(['git', 'init', '-q', '-b', branch, repo], check=True)
    with open(os.path.join(repo, 'file.txt'), 'w') as f:
        f.write('x\n')
    return repo


def make_slow_git(sleep_seconds):
    """a PATH shim that makes exactly `git status` (the dirty check that runs
    inside the zpty job) slow, leaving every other git call untouched"""
    shim_dir = tempfile.mkdtemp(prefix='jovial-bin-')
    real_git = shutil.which('git')
    shim = os.path.join(shim_dir, 'git')
    with open(shim, 'w') as f:
        f.write(f'#!/bin/sh\ncase "$1" in status) sleep {sleep_seconds};; esac\n'
                f'exec {real_git} "$@"\n')
    os.chmod(shim, 0o755)
    return shim_dir


def run_session(env=None, workdir=None, typeahead=None,
                lag=0.0, tone='dark', answer=True, zshrc_extra='',
                injects=(), commands=(), settle=0.3, total=30.0):
    """Interactive themed zsh on a PTY. Everything the parent writes is
    SCHEDULED, never slept-for, so timing measurements and event ordering stay
    honest (a blocking sleep would delay every later event past `exit`).

      injects  -- [(seconds_after_query, bytes), ...] raw writes relative to
                  the moment the OSC query is first seen (e.g. a ^C)
      commands -- sent 0.4s apart once the first prompt appeared + `settle`,
                  followed by `exit`

    Returns a dict with the decoded output and query/prompt timings (relative
    to spawn)."""
    zdot = tempfile.mkdtemp(prefix='jovial-zdot-')
    with open(os.path.join(zdot, '.zshrc'), 'w') as f:
        f.write(f'source {THEME}\n{zshrc_extra}\n')
    # default to a neutral, empty working dir: keeps the first prompt's git /
    # dev-env probes out of the timing measurements unless a scenario opts in
    # (running inside a real repo checkout would add its `git status` cost)
    workdir = workdir or tempfile.mkdtemp(prefix='jovial-cwd-')

    pid, master = pty.fork()
    if pid == 0:
        # a wide, fixed window: the prompt's responsive design must never drop
        # the git segment because of a long tmpdir path (macOS /var/folders/…)
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 200, 0, 0))
        os.chdir(workdir)
        for var in ('COLORFGBG', 'JOVIAL_THEME_MODE', 'JOVIAL_THEME_DETECT_TIMEOUT',
                    'SSH_CONNECTION', 'SSH_TTY', 'TERM_PROGRAM'):
            os.environ.pop(var, None)
        os.environ['TERM'] = 'xterm-256color'
        os.environ['ZDOTDIR'] = zdot
        if env:
            os.environ.update(env)
        os.execvp('zsh', ['zsh', '-d', '-i'])
        os._exit(127)

    t_spawn = time.time()
    if typeahead:
        os.write(master, typeahead)

    out = b''
    t_query = t_prompt = None
    pending = []           # [(abs_time, bytes)] scheduled writes
    reply_scheduled = False
    deadline = time.time() + total
    while time.time() < deadline:
        rd, _, _ = select.select([master], [], [], 0.02)

        now = time.time()
        for item in [p for p in pending if now >= p[0]]:
            pending.remove(item)
            try:
                os.write(master, item[1])
            except OSError:
                pass

        if master not in rd:
            continue
        try:
            data = os.read(master, 4096)
        except OSError:
            break
        if not data:
            break
        out += data

        if t_query is None and OSC_QUERY in out:
            t_query = time.time()
            for delay, payload in injects:
                pending.append((t_query + delay, payload))
        if not reply_scheduled and DA1_QUERY in out:
            # schedule the reply exactly once, `lag` after the query arrived
            reply_scheduled = True
            if answer:
                pending.append((time.time() + lag, osc_reply(tone) + DA1_REPLY))
        if t_prompt is None and PROMPT_MARK in out:
            t_prompt = time.time()
            when = t_prompt + settle
            for cmd in commands:
                pending.append((when, cmd))
                when += 0.4
            pending.append((when, b'exit\r'))

    os.close(master)
    try:
        os.waitpid(pid, 0)
    except OSError:
        pass

    global LAST_OUT
    LAST_OUT = out.decode(errors='replace')
    return dict(
        out=LAST_OUT,
        t_query=(t_query - t_spawn) if t_query else None,
        t_prompt=(t_prompt - t_spawn) if t_prompt else None,
        q2p=(t_prompt - t_query) if (t_prompt and t_query) else None,
    )


def fmt(seconds):
    return 'n/a' if seconds is None else f'{seconds * 1000:.0f}ms'


# ---------- scenarios ----------

def scenario_stderr_visible():
    r = run_session(commands=(b'echo "SE-$((6*7))" >&2\r',
                              b'echo "SO-$((6*7))"\r',
                              b'echo "MODE-$JOVIAL_THEME_MODE"\r'))
    ok = ('SE-42' in r['out'] and 'SO-42' in r['out'] and 'MODE-dark' in r['out'])
    return ok, (f"stderr={'SE-42' in r['out']} stdout={'SO-42' in r['out']} "
                f"mode-dark={'MODE-dark' in r['out']}")


def scenario_typeahead_replay():
    r = run_session(typeahead=b'echo "TA-$((6*7))"\r',
                    commands=(b'echo "CT-$((6*7))"\r',))
    leaked = '1e1e' in r['out']           # reply payload must never hit the screen
    ok = 'TA-42' in r['out'] and 'CT-42' in r['out'] and not leaked
    return ok, (f"typeahead-ran={'TA-42' in r['out']} control-ran={'CT-42' in r['out']} "
                f"reply-leaked={leaked}")


def scenario_late_reply_guard():
    # terminal answers at 0.8s, past the 0.3s first-paint budget: the first
    # prompt falls back to dark, then the zle guard must swallow the late
    # reply (no `fafa` garbage on screen) and self-correct to light
    r = run_session(lag=0.8, tone='light', settle=0.3,
                    commands=(b'echo "MODE1-$JOVIAL_THEME_MODE"\r',
                              b'echo "MODE2-$JOVIAL_THEME_MODE"\r'))
    leaked = 'fafa' in r['out']
    ok = ('MODE1-dark' in r['out'] and 'MODE2-light' in r['out'] and not leaked)
    return ok, (f"fallback-first={'MODE1-dark' in r['out']} "
                f"self-corrected={'MODE2-light' in r['out']} leaked={leaked}")


def scenario_early_send():
    # ~400ms of "the rest of ~/.zshrc" after the theme is sourced; terminal
    # answers 250ms after the query. with the query sent at source time the
    # round-trip hides inside the 400ms, so the prompt appears right after
    # zshrc with the fresh mode -- no serial wait anywhere.
    r = run_session(lag=0.25, tone='dark',
                    zshrc_extra='zmodload zsh/zselect; zselect -t 40 || true',
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    early = r['t_query'] is not None and r['t_query'] < 0.30
    overlapped = r['q2p'] is not None and r['q2p'] < 0.60
    ok = early and overlapped and 'MODE-dark' in r['out']
    return ok, (f"query-at={fmt(r['t_query'])} (early={early}) "
                f"query->prompt={fmt(r['q2p'])} (overlapped={overlapped}) "
                f"mode-dark={'MODE-dark' in r['out']}")


def scenario_timeout_env():
    # a silent terminal with JOVIAL_THEME_DETECT_TIMEOUT=0.15 preset in env:
    # the wait must track the preset (~0.15s), not the built-in default 0.3s
    # (the tight upper bound is what discriminates preset from default)
    r = run_session(env={'JOVIAL_THEME_DETECT_TIMEOUT': '0.15'}, answer=False,
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    ok = (r['q2p'] is not None and 0.10 <= r['q2p'] <= 0.26
          and 'MODE-dark' in r['out'])
    return ok, f"query->prompt={fmt(r['q2p'])} (expect ~150ms) mode-dark={'MODE-dark' in r['out']}"


def scenario_ctrl_c_during_wait():
    # ^C while detection waits on a mute terminal: `-icanon -echo` keeps ISIG,
    # so the shell must survive and the tty must be restored. detection is
    # retried on the next prompt (an Enter is injected, as a user would press),
    # and a later command must run with its output visible
    r = run_session(answer=False, settle=0.5,
                    injects=((0.2, b'\x03'), (0.7, b'\r')),
                    commands=(b'echo "OK-$((6*7))"\r',))
    ok = 'OK-42' in r['out'] and r['t_prompt'] is not None
    return ok, (f"alive-and-echoing={'OK-42' in r['out']} prompt={fmt(r['t_prompt'])} "
                f"query->prompt={fmt(r['q2p'])}")


def scenario_silent_fallback():
    # a terminal that never answers costs exactly one first-paint budget
    # (default 0.3s), then falls back to dark; no more and no less
    r = run_session(answer=False,
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    ok = (r['q2p'] is not None and 0.26 <= r['q2p'] <= 0.50
          and 'MODE-dark' in r['out'])
    return ok, f"query->prompt={fmt(r['q2p'])} (expect ~300ms) mode-dark={'MODE-dark' in r['out']}"


def scenario_slow_git_parallel():
    # `git status` takes 1.2s (PATH shim) inside a real repo: the first paint
    # must NOT wait for it beyond the budget -- the prompt renders without the
    # git segment, which then joins via an async rerender
    repo = make_git_repo()
    shim = make_slow_git(1.2)
    r = run_session(workdir=repo, settle=2.5,
                    env={'PATH': shim + os.pathsep + os.environ['PATH']},
                    commands=(b'echo "SG-$((6*7))"\r',))
    out = r['out']
    mark_idx = out.find(PROMPT_MARK.decode())
    branch_idx = out.find('e2e-branch')
    capped = r['q2p'] is not None and r['q2p'] < 0.60
    rerendered_later = mark_idx != -1 and branch_idx > mark_idx
    ok = capped and rerendered_later and 'SG-42' in out
    return ok, (f"query->prompt={fmt(r['q2p'])} (capped={capped}) "
                f"git-joined-after-first-paint={rerendered_later} "
                f"alive={'SG-42' in out}")


def scenario_fast_git_sync():
    # a fast git check inside a real repo finishes within the budget, so the
    # git segment must be part of the very first paint (before the prompt's
    # bottom corner), with no artificial wait added
    repo = make_git_repo()
    r = run_session(workdir=repo,
                    commands=(b'echo "FG-$((6*7))"\r',))
    out = r['out']
    mark_idx = out.find(PROMPT_MARK.decode())
    branch_idx = out.find('e2e-branch')
    in_first_paint = branch_idx != -1 and mark_idx != -1 and branch_idx < mark_idx
    # upper bound is budget + scheduling slack: a cold container can spend a
    # beat spawning the zpty worker, but the paint must never exceed ~budget
    # (serial-wait degradation is what the slow-git scenario discriminates)
    fast = r['q2p'] is not None and r['q2p'] < 0.45
    ok = in_first_paint and fast and 'FG-42' in out
    return ok, (f"query->prompt={fmt(r['q2p'])} (fast={fast}) "
                f"git-in-first-paint={in_first_paint}")


def scenario_shared_budget():
    # the acid test for ONE shared budget: a mute terminal AND a slow git
    # (1.2s) together -- the OSC wait and the probes race concurrently, so the
    # first paint still costs about one budget (~0.3s), never the sum of both
    repo = make_git_repo()
    shim = make_slow_git(1.2)
    r = run_session(workdir=repo, answer=False, settle=2.5,
                    env={'PATH': shim + os.pathsep + os.environ['PATH']},
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    out = r['out']
    mark_idx = out.find(PROMPT_MARK.decode())
    branch_idx = out.find('e2e-branch')
    one_budget = r['q2p'] is not None and 0.26 <= r['q2p'] <= 0.65
    rerendered_later = mark_idx != -1 and branch_idx > mark_idx
    ok = one_budget and rerendered_later and 'MODE-dark' in out
    return ok, (f"query->prompt={fmt(r['q2p'])} (one-budget={one_budget}) "
                f"git-joined-later={rerendered_later} "
                f"mode-dark={'MODE-dark' in out}")


def scenario_dev_env_color_first_paint():
    # the dev-env zpty worker bakes palette TOKENS (not colors) at fork time;
    # its callback must resolve them against the applied palette, so the
    # segment on the very FIRST paint carries real colors -- regression guard
    # for both the colorless-first-paint bug and the token machinery. assert,
    # within the first paint region only, the conj. color right before
    # `using` and the dev-env color right before the version text.
    workdir = tempfile.mkdtemp(prefix='jovial-pydemo-')
    with open(os.path.join(workdir, 'requirements.txt'), 'w') as f:
        f.write('requests\n')
    r = run_session(workdir=workdir, commands=(b'echo "DE-$((6*7))"\r',))
    out = r['out']
    mark = PROMPT_MARK.decode()
    first_paint = out[:out.find(mark)] if mark in out else ''
    segment_in_first = 'using' in first_paint
    # dark palette: conj. = %F{102}, dev-env.python = %F{123}
    conj_colored = '\x1b[38;5;102musing' in first_paint
    version_colored = '\x1b[38;5;123mPython' in first_paint
    leftover_token = '<%jov:' in out
    ok = (segment_in_first and conj_colored and version_colored
          and not leftover_token and 'DE-42' in out)
    return ok, (f"segment-in-first-paint={segment_in_first} "
                f"conj-colored={conj_colored} version-colored={version_colored} "
                f"leftover-token={leftover_token}")


def scenario_non_interactive():
    # a NON-interactive shell on a real tty (like a script or pipeline run
    # from a terminal): only env checks may happen -- no OSC query bytes may
    # reach the tty, and sourcing must not wait on any budget
    cmd = f'source {THEME}; echo "NI-$((6*7))-${{JOVIAL_THEME_MODE:-unset}}"'
    pid, master = pty.fork()
    if pid == 0:
        for var in ('COLORFGBG', 'JOVIAL_THEME_MODE', 'JOVIAL_THEME_DETECT_TIMEOUT'):
            os.environ.pop(var, None)
        os.environ['TERM'] = 'xterm-256color'
        os.execvp('zsh', ['zsh', '-d', '-f', '-c', cmd])
        os._exit(127)
    t0 = time.time()
    out = b''
    while time.time() - t0 < 8:
        rd, _, _ = select.select([master], [], [], 0.05)
        if master in rd:
            try:
                data = os.read(master, 4096)
            except OSError:
                break
            if not data:
                break
            out += data
    duration = time.time() - t0
    os.close(master)
    try:
        os.waitpid(pid, 0)
    except OSError:
        pass
    global LAST_OUT
    LAST_OUT = out.decode(errors='replace')
    ok = (b'NI-42-unset' in out and OSC_QUERY not in out and duration < 2.0)
    return ok, (f"ran={b'NI-42-unset' in out} query-sent={OSC_QUERY in out} "
                f"took={duration * 1000:.0f}ms")


def scenario_colorfgbg_skip():
    r = run_session(env={'COLORFGBG': '15;0'},
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    ok = r['t_query'] is None and 'MODE-dark' in r['out']
    return ok, f"query-sent={r['t_query'] is not None} mode-dark={'MODE-dark' in r['out']}"


def scenario_preset_skip():
    r = run_session(env={'JOVIAL_THEME_MODE': 'light'},
                    commands=(b'echo "MODE-$JOVIAL_THEME_MODE"\r',))
    ok = r['t_query'] is None and 'MODE-light' in r['out']
    return ok, f"query-sent={r['t_query'] is not None} mode-light={'MODE-light' in r['out']}"


SCENARIOS = {
    'stderr-visible':    scenario_stderr_visible,
    'typeahead-replay':  scenario_typeahead_replay,
    'late-reply-guard':  scenario_late_reply_guard,
    'early-send':        scenario_early_send,
    'timeout-env':       scenario_timeout_env,
    'ctrl-c-wait':       scenario_ctrl_c_during_wait,
    'silent-fallback':   scenario_silent_fallback,
    'slow-git-parallel': scenario_slow_git_parallel,
    'fast-git-sync':     scenario_fast_git_sync,
    'shared-budget':     scenario_shared_budget,
    'dev-env-color':     scenario_dev_env_color_first_paint,
    'non-interactive':   scenario_non_interactive,
    'colorfgbg-skip':    scenario_colorfgbg_skip,
    'preset-skip':       scenario_preset_skip,
}


LAST_OUT = ''   # raw output of the most recent session, for failure diagnosis


def main():
    wanted = sys.argv[2:] or list(SCENARIOS)
    rc = 0
    for name in wanted:
        ok, detail = SCENARIOS[name]()
        print(f"[{'PASS' if ok else 'FAIL'}] session:{name:18s} {detail}", flush=True)
        if not ok:
            print(f"        last session output tail: {LAST_OUT[-300:]!r}", flush=True)
        rc |= (0 if ok else 1)
    sys.exit(rc)


if __name__ == '__main__':
    main()
