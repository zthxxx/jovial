#!/usr/bin/env bun
import { mkdir, writeFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createKernel, nodeFs, type Pty } from 'unkernel/node'

// unkernel@0.1.0-261117-0e4b2ec: offline guest and PTY boundaries.
// https://github.com/pithings/unkernel/blob/v0.1.0-261117-0e4b2ec/js/core/tty.ts
const site = resolve(fileURLToPath(new URL('..', import.meta.url)))
const logs = join(site, '.cache/logs')
const repetitions = Number(process.argv[2] ?? 3)
if (!Number.isInteger(repetitions) || repetitions < 1) throw new Error('Repetitions must be a positive integer')
const availableModes = ['full', 'cached-full', 'uncached-lean', 'lean', 'minimal'] as const
const modes = process.argv[3] ? process.argv[3].split(',') : [...availableModes]
if (modes.some(mode => !availableModes.includes(mode as typeof availableModes[number]))) throw new Error('Unknown shell profiling mode')
const raw: string[] = []
const results: unknown[] = []
const vm = await createKernel({
  kernel: join(site, 'public/runtime/unkernel.wasm'),
  initrd: join(site, 'public/runtime/jovial.cpio.gz'),
  memoryMiB: 768,
  mounts: { '/mnt/profile': { fs: nodeFs(join(site, '.cache/profile-input')), readOnly: true } },
  onOutput: (bytes) => raw.push(new TextDecoder().decode(bytes)),
})

async function readStartup(shell: Pty, profiled: boolean, closeAfter = true) {
  const reader = shell.output.getReader()
  const decoder = new TextDecoder()
  const started = performance.now()
  let text = '', queryWindow = '', color = false, device = false, cursor = false
  const deadline = setTimeout(() => { void shell.close() }, 120_000)
  let markerAt: number | undefined
  try {
    while (true) {
      const chunk = await reader.read()
      if (chunk.done) throw new Error('Shell exited before profiling completed')
      const value = decoder.decode(chunk.value, { stream: true })
      text += value
      queryWindow = (queryWindow + value).slice(-1024)
      if (!color && queryWindow.includes('\x1b]11;?')) {
        color = true
        await shell.write('\x1b]11;rgb:1111/1111/1111\x1b\\')
      }
      if (!device && queryWindow.includes('\x1b[c')) {
        device = true
        await shell.write('\x1b[?1;2c')
      }
      if (!cursor && queryWindow.includes('\x1b[6n')) {
        cursor = true
        await shell.write('\x1b[1;1R')
      }
      if (!markerAt && text.includes('\x1b]777;jovial-ready\x07')) markerAt = performance.now() - started
      const match = text.match(/\x1b\]777;jovial-profile;([^\x07]+)\x07/)
      if (profiled && match) return { outputMs: markerAt, profile: JSON.parse(Buffer.from(match[1], 'base64').toString()), text }
      if (!profiled && markerAt) return { outputMs: markerAt, text }
    }
  } finally {
    clearTimeout(deadline)
    reader.releaseLock()
    if (closeAfter) await shell.close()
  }
}
try {
  const prepared = await vm.exec('/bin/sh', ['-eu', '-c', `
    mkdir -p /home/zthxxx/.config/jovial-profile /home/zthxxx/.config/jovial-plain
    cp /mnt/profile/profile.zsh /home/zthxxx/.config/jovial-profile/profile.zsh
    cp /mnt/profile/profile.zshenv /home/zthxxx/.config/jovial-profile/.zshenv
    cp /mnt/profile/profile.zshrc /home/zthxxx/.config/jovial-profile/.zshrc
    cp /mnt/profile/terminal-ready.zsh /home/zthxxx/.config/jovial-preview.zsh
    cp /mnt/profile/*.zsh /home/zthxxx/.config/jovial-profile/
    cp /mnt/profile/*-plain.zsh /home/zthxxx/.config/jovial-plain/
    printf 'source "$HOME/.zshenv"\\n' > /home/zthxxx/.config/jovial-plain/.zshenv
    printf 'source "$ZDOTDIR/\${JOVIAL_PROFILE_MODE}-plain.zsh"\\nsource "$HOME/.config/jovial-preview.zsh"\\ncd "$HOME/Project"\\n' > /home/zthxxx/.config/jovial-plain/.zshrc
    install -m 755 /mnt/profile/profile-shell /usr/local/bin/jovial-profile-shell
    cp /home/zthxxx/.zcompdump /tmp/jovial-compdump-seed
    for dir in jovial-profile jovial-plain; do
      for mode in full cached-full uncached-lean lean minimal; do
        cp /tmp/jovial-compdump-seed "/home/zthxxx/.config/$dir/$mode.zcompdump"
      done
    done
    chown -R zthxxx:zthxxx /home/zthxxx/.config/jovial-profile /home/zthxxx/.config/jovial-plain
  `])
  if (prepared.exitCode !== 0) throw new Error(prepared.stderr)
  for (const profiled of [false, true]) {
    for (let run = 0; run < repetitions; run++) {
      for (const mode of run % 2 === 0 ? modes : [...modes].reverse()) {
        const started = performance.now()
        const shell = profiled
          ? await vm.spawn('/bin/su', ['-l', 'zthxxx', '-c', `export JOVIAL_PROFILE_MODE=${mode}; export ZDOTDIR="$HOME/.config/jovial-profile"; exec /bin/zsh -i`], { cols: 120, rows: 30 })
          : await vm.spawn('/bin/su', ['-l', 'zthxxx', '-c', `export JOVIAL_PROFILE_MODE=${mode}; export ZDOTDIR="$HOME/.config/jovial-plain"; exec /bin/zsh -i`], { cols: 120, rows: 30 })
        const spawnedMs = performance.now() - started
        const result = await readStartup(shell, profiled)
        raw.push(`\n===== ${profiled ? 'instrumented' : 'plain'} ${mode} run ${run + 1} =====\n${result.text}`)
        const entry = { mode, run: run + 1, profiled, spawnedMs, totalHostMs: spawnedMs + (result.outputMs ?? 0), ...('profile' in result ? { profile: result.profile } : {}) }
        results.push(entry)
        console.log(JSON.stringify({ mode, run: run + 1, profiled, totalHostMs: entry.totalHostMs, profileTotalMs: 'profile' in entry ? entry.profile.totalMs : undefined }))
        await writeFile(join(logs, 'shell-profile-results.json'), JSON.stringify(results, null, 2) + '\n')
      }
    }
  }
  const check = 'set -e; [[ ${_comps[ab]} = _ab ]]; (( ${+functions[gfco]} )); (( ! ${+functions[_zsh_autosuggest_start]} )); (( ${+functions[_zsh_highlight]} )); [[ $FAST_WORK_DIR = "$XDG_CONFIG_HOME/fsh" && -s $FAST_WORK_DIR/secondary_theme.zsh ]]; print -r -- LEAN_COMPLETIONS_AND_THEME_READY'
  const quoted = "'" + check.replaceAll("'", "'\\''") + "'"
  const completion = await vm.exec('/bin/su', ['-l', 'zthxxx', '-c', `export JOVIAL_PROFILE_MODE=lean; export ZDOTDIR="$HOME/.config/jovial-plain"; /bin/zsh -ic ${quoted}`])
  if (completion.exitCode !== 0) throw new Error(`Lean completion check failed: ${completion.stderr}`)
  raw.push('\n===== lean completion cache and theme =====\n' + completion.stdout + completion.stderr)
  console.log('LEAN_COMPLETIONS_AND_THEME_READY')
  const tabShell = await vm.spawn('/bin/su', ['-l', 'zthxxx', '-c', 'export JOVIAL_PROFILE_MODE=lean; export ZDOTDIR="$HOME/.config/jovial-plain"; exec /bin/zsh -i'], { cols: 120, rows: 30 })
  await readStartup(tabShell, false, false)
  const tabReader = tabShell.output.getReader()
  const tabDeadline = setTimeout(() => { void tabShell.close() }, 30_000)
  let tabOutput = ''
  try {
    await tabShell.write('cd ~/Project/no\t')
    while (!tabOutput.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, '').includes('node-demo/')) {
      const chunk = await tabReader.read()
      if (chunk.done) throw new Error('Shell exited before completing a project path')
      tabOutput += new TextDecoder().decode(chunk.value)
    }
    console.log('LEAN_TAB_COMPLETED_NODE_DEMO')
  } finally {
    clearTimeout(tabDeadline)
    tabReader.releaseLock()
    await tabShell.close()
    raw.push('\n===== lean Tab completion =====\n' + tabOutput)
  }

} finally {
  await vm.stop()
  await mkdir(logs, { recursive: true })
  await writeFile(join(logs, 'shell-profile-raw.log'), raw.join(''))
}
