import '@fontsource-variable/jetbrains-mono'
import '@xterm/xterm/css/xterm.css'
import './playground.css'
import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { loadTerminalFonts, terminalOptions } from './terminal.ts'
import { waitForShellPrompt, waitForTerminalPaint } from './shell-ready.ts'
import { startSession, type Session, type EnvironmentProgress } from './runtime.ts'

type Variant = 'full' | 'lean' | 'minimal'
interface HostEvent { name: string; atMs: number }
interface GuestProfile {
  schemaVersion: 1
  mode: Variant
  stages: { name: string; atMs: number; durationMs: number }[]
  totalMs: number
  zprofBase64: string
  zprofMs?: number
}
interface Run {
  id: string
  variant: Variant
  startedAt: string
  status: 'running' | 'ready' | 'cancelled' | 'error'
  host: HostEvent[]
  guest?: GuestProfile
  error?: string
}

const STORAGE = 'jovial-terminal-profile-v1'
const labels: Record<Variant, string> = { full: 'Full example', lean: 'Lean', minimal: 'Minimal' }
const element = <T extends HTMLElement>(id: string) => document.getElementById(id) as T
const terminalElement = element('terminal')
const cover = element('terminal-cover')
const state = element('state')
const variant = element<HTMLSelectElement>('variant')
const progress = element<HTMLProgressElement>('loading-progress')
const errorElement = element('error')
const term = new Terminal({
  ...terminalOptions,
  cursorBlink: true,
  cursorStyle: 'bar',
  scrollback: 3000,
  screenReaderMode: true,
  theme: { background: '#111111', foreground: '#dedede', cursor: '#dedede', selectionBackground: '#38464a' },
})
const fit = new FitAddon()
term.loadAddon(fit)
let session: Session | undefined
let controller: AbortController | undefined
let operation = 0
let busy = false
let selected: Run | undefined
let records: Run[] = loadRecords()

function loadRecords(): Run[] {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE) ?? '[]') as Run[]
    return saved.slice(-20).map((run) => run.status === 'running' ? { ...run, status: 'cancelled' } : run)
  } catch { return [] }
}
function saveRecords() {
  records = records.slice(-20)
  try { localStorage.setItem(STORAGE, JSON.stringify(records)) } catch { /* Measurements remain available for JSON export. */ }
}
function formatMs(value: number | undefined): string {
  if (value === undefined) return '—'
  return value >= 1000 ? `${(value / 1000).toFixed(2)} s` : `${value.toFixed(1)} ms`
}
function milestone(run: Run, name: string): number | undefined { return run.host.find((item) => item.name === name)?.atMs }
function afterPty(run: Run): number | undefined {
  const start = milestone(run, 'PTY connected'), end = milestone(run, 'Prompt parsed')
  return start === undefined || end === undefined ? undefined : end - start
}
function cell(text: string, numeric = false): HTMLTableCellElement {
  const result = document.createElement('td')
  result.textContent = text
  if (numeric) result.className = 'number'
  return result
}
function emptyRow(columns: number, text: string): HTMLTableRowElement {
  const row = document.createElement('tr'), content = cell(text)
  content.colSpan = columns
  content.className = 'empty'
  row.append(content)
  return row
}
function renderRun(run: Run | undefined) {
  selected = run
  element('screen-time').textContent = run ? formatMs(milestone(run, 'Prompt on screen')) : '—'
  element('guest-time').textContent = formatMs(run?.guest?.totalMs)
  element('shell-time').textContent = run ? formatMs(afterPty(run)) : '—'
  const host = element('host-events'), guest = element('guest-events')
  host.replaceChildren()
  guest.replaceChildren()
  if (!run?.host.length) host.append(emptyRow(2, 'Start a run to collect browser timings.'))
  for (const event of run?.host ?? []) {
    const row = document.createElement('tr')
    row.append(cell(event.name), cell(formatMs(event.atMs), true))
    host.append(row)
  }
  if (!run?.guest) guest.append(emptyRow(3, 'Guest profiling is collected after its first prompt.'))
  for (const event of run?.guest?.stages ?? []) {
    const row = document.createElement('tr')
    row.append(cell(event.name), cell(formatMs(event.durationMs), true), cell(formatMs(event.atMs), true))
    guest.append(row)
  }
  element('zprof').textContent = run?.guest?.zprofBase64 ? decodeBase64(run.guest.zprofBase64) : 'No function profile collected.'
  element('profile-label').textContent = run ? `${labels[run.variant]} · ${run.startedAt.slice(11, 19)}` : 'zprof'
  element('profile-cost').textContent = run?.guest?.zprofMs === undefined ? '' : `Report collection after the first prompt: ${formatMs(run.guest.zprofMs)}. This is excluded from the guest startup total.`
  renderHistory()
}
function renderHistory() {
  const body = element('history')
  body.replaceChildren()
  if (!records.length) body.append(emptyRow(6, 'No completed runs.'))
  for (const run of [...records].reverse()) {
    const row = document.createElement('tr')
    if (run === selected) row.dataset.selected = ''
    const identity = cell(''), button = document.createElement('button')
    button.type = 'button'
    button.textContent = run.startedAt.slice(11, 19)
    button.title = run.startedAt
    button.addEventListener('click', () => renderRun(run))
    identity.append(button)
    row.append(identity, cell(labels[run.variant]), cell(run.status), cell(formatMs(milestone(run, 'Prompt on screen')), true), cell(formatMs(run.guest?.totalMs), true), cell(formatMs(afterPty(run)), true))
    body.append(row)
  }
  element<HTMLButtonElement>('export').disabled = records.length === 0
  element<HTMLButtonElement>('clear').disabled = busy || records.length === 0
}
async function closeSession() {
  const closing = session
  session = undefined
  await closing?.close()
}
function setControls() {
  element<HTMLButtonElement>('run').disabled = busy
  element<HTMLButtonElement>('compare').disabled = busy
  variant.disabled = busy
  element<HTMLButtonElement>('stop').disabled = !session && !busy
  element<HTMLButtonElement>('clear').disabled = busy || records.length === 0
}
function resize() {
  if (!term.element) return
  fit.fit()
  session?.resize(term.cols, term.rows)
  element('terminal-size').textContent = `${term.cols} × ${term.rows}`
}
new ResizeObserver(resize).observe(terminalElement)
term.onData((data) => {
  const currentOperation = operation
  void session?.write(data).catch((error) => { if (currentOperation === operation) showError(error) })
})
function showError(error: unknown) {
  errorElement.textContent = error instanceof Error ? error.message : String(error)
  errorElement.hidden = false
}
function showCover(title: string, detail: string) {
  cover.hidden = false
  element('cover-title').textContent = title
  element('cover-detail').textContent = detail
}
function decodeBase64(value: string): string {
  return new TextDecoder().decode(Uint8Array.from(atob(value), (character) => character.charCodeAt(0)))
}
function waitForProfile(signal: AbortSignal): Promise<GuestProfile> {
  return new Promise((resolve, reject) => {
    const handler = term.parser.registerOscHandler(777, (data) => {
      if (!data.startsWith('jovial-profile;')) return false
      cleanup()
      try { resolve(JSON.parse(decodeBase64(data.slice('jovial-profile;'.length))) as GuestProfile) }
      catch (error) { reject(error) }
      return true
    })
    const abort = () => { cleanup(); reject(signal.reason) }
    const cleanup = () => { handler.dispose(); signal.removeEventListener('abort', abort) }
    signal.addEventListener('abort', abort, { once: true })
    if (signal.aborted) abort()
  })
}

async function startRun(mode: Variant, currentOperation: number): Promise<void> {
  const run: Run = { id: crypto.randomUUID(), variant: mode, startedAt: new Date().toISOString(), status: 'running', host: [] }
  records.push(run)
  const started = performance.now()
  const mark = (name: string) => {
    if (currentOperation !== operation || run.host.some((event) => event.name === name)) return
    run.host.push({ name, atMs: performance.now() - started })
    renderRun(run)
  }
  mark('Start')
  controller?.abort(new DOMException('A new measurement started', 'AbortError'))
  await closeSession()
  await new Promise<void>((resolve) => term.write('', resolve))
  if (currentOperation !== operation) return
  const runController = new AbortController()
  controller = runController
  const signal = runController.signal
  const timer = setTimeout(() => runController.abort(new Error('The shell did not produce its first prompt within 120 seconds.')), 120_000)
  let profileTimer: ReturnType<typeof setTimeout> | undefined
  errorElement.hidden = true
  showCover('Preparing measurement', `${labels[mode]} · loading terminal fonts`)
  progress.hidden = false
  progress.removeAttribute('value')
  state.textContent = `Running ${labels[mode]}`
  element('terminal-label').textContent = `zthxxx@unkernel · ${labels[mode]}`
  try {
    await loadTerminalFonts()
    signal.throwIfAborted()
    mark('Fonts loaded')
    if (!term.element) term.open(terminalElement)
    term.reset()
    resize()
    const prompt = waitForShellPrompt(term, signal)
    const profile = waitForProfile(signal)
    const connected = startSession({
      cols: term.cols,
      rows: term.rows,
      signal,
      file: '/usr/local/bin/jovial-profile-shell',
      args: [mode],
      onProgress: (event: EnvironmentProgress) => {
        if (currentOperation !== operation) return
        if (event.stage === 'download') {
          const label = event.what === 'kernel' ? 'Kernel' : 'Image'
          element('cover-detail').textContent = `${labels[mode]} · ${label.toLowerCase()} ${(event.loaded / 1048576).toFixed(1)}${event.total ? ` / ${(event.total / 1048576).toFixed(1)}` : ''} MiB`
          if (event.total) { progress.max = event.total; progress.value = event.loaded } else progress.removeAttribute('value')
          if (event.done) mark(`${label} downloaded`)
        } else {
          const names: Record<string, string> = { worker: 'Worker ready', compile: 'Kernel load started', compiled: 'Kernel compiled', memory: 'Memory allocated', instantiate: 'Kernel instantiation started', start: 'Kernel started' }
          if (names[event.stage]) mark(names[event.stage]!)
          if (event.stage === 'start') {
            element('cover-detail').textContent = `${labels[mode]} · loading Zsh and waiting for its first prompt`
            progress.removeAttribute('value')
          }
        }
      },
    }).then((created) => {
      if (currentOperation !== operation || signal.aborted) { void created.close(); return }
      session = created
      mark('PTY connected')
      resize()
      setControls()
      const reader = created.output.getReader()
      const pump = async () => {
        try {
          while (true) {
            const chunk = await reader.read()
            if (chunk.done) break
            if (currentOperation !== operation) break
            mark('First output')
            term.write(chunk.value)
          }
          await created.exited
          if (currentOperation === operation && !signal.aborted) {
            state.textContent = 'Shell exited'
            if (run.status === 'running') controller?.abort(new Error('Zsh exited before profiling completed.'))
          }
        } catch (error) {
          if (!signal.aborted && currentOperation === operation) controller?.abort(error)
        } finally { reader.releaseLock() }
      }
      void pump()
    })
    const finishedProfile = profile.then((value) => {
      run.guest = value
      clearTimeout(profileTimer)
      if (currentOperation === operation) renderRun(run)
      return { value }
    }).catch((error: unknown) => ({ error }))
    await Promise.all([connected, prompt.then(() => {
      mark('Prompt parsed')
      clearTimeout(timer)
      if (!run.guest) profileTimer = setTimeout(() => runController.abort(new Error('The guest did not send its function profile within 30 seconds.')), 30_000)
    })])
    await new Promise<void>((resolve) => term.write('', resolve))
    await waitForTerminalPaint(term, signal)
    signal.throwIfAborted()
    mark('Prompt on screen')
    cover.hidden = true
    progress.hidden = true
    term.focus()
    const report = await finishedProfile
    if ('error' in report) throw report.error
    signal.throwIfAborted()
    run.status = 'ready'
    state.textContent = `${labels[mode]} measured · terminal is interactive`
  } catch (error) {
    run.status = signal.aborted && signal.reason?.name === 'AbortError' ? 'cancelled' : 'error'
    run.error = error instanceof Error ? error.message : String(error)
    if (currentOperation === operation) {
      if (run.status === 'error') showError(error)
      state.textContent = run.status === 'cancelled' ? 'Stopped' : 'Measurement failed'
      if (cover.hidden === false) showCover(run.status === 'cancelled' ? 'Measurement stopped' : 'Could not finish measurement', run.error)
      controller?.abort(error)
      await closeSession()
    }
  } finally {
    clearTimeout(timer)
    clearTimeout(profileTimer)
    saveRecords()
    if (currentOperation === operation) renderRun(run)
    else renderHistory()
  }
}

async function measure(modes: Variant[]) {
  const currentOperation = ++operation
  busy = true
  setControls()
  for (const mode of modes) {
    await startRun(mode, currentOperation)
    if (currentOperation !== operation) return
  }
  busy = false
  setControls()
}
element('run').addEventListener('click', () => { void measure([variant.value as Variant]) })
element('compare').addEventListener('click', () => { void measure(['full', 'lean', 'minimal']) })
element('stop').addEventListener('click', () => {
  ++operation
  controller?.abort(new DOMException('Measurement stopped', 'AbortError'))
  void session?.close()
  session = undefined
  busy = false
  state.textContent = 'Stopped'
  progress.hidden = true
  if (!cover.hidden) showCover('Measurement stopped', 'Start another run to open a fresh VM.')
  setControls()
})
element('clear').addEventListener('click', () => { records = []; saveRecords(); renderRun(undefined) })
element('export').addEventListener('click', () => {
  const content = JSON.stringify({ schemaVersion: 1, exportedAt: new Date().toISOString(), browser: navigator.userAgent, runs: records }, null, 2)
  const url = URL.createObjectURL(new Blob([content], { type: 'application/json' }))
  const link = document.createElement('a')
  link.href = url
  link.download = `jovial-terminal-profile-${new Date().toISOString().replace(/[:.]/g, '-')}.json`
  link.click()
  setTimeout(() => URL.revokeObjectURL(url), 0)
})
window.addEventListener('pagehide', () => { controller?.abort() })
renderRun(records.at(-1))
setControls()
