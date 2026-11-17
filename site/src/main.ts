import '@fontsource-variable/jetbrains-mono'
import '@xterm/xterm/css/xterm.css'
import './style.css'
import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { demos } from './demos.ts'
import { startSession, type Session } from './runtime.ts'
import type { BootProgress } from 'unkernel/web'

const element = <T extends HTMLElement>(id: string) => document.getElementById(id) as T
const workspace = document.querySelector<HTMLElement>('.workspace')!
const terminalElement = element('terminal')
const boot = element('boot')
const title = element('boot-title')
const detail = element('boot-detail')
const progress = element<HTMLProgressElement>('boot-progress')
const status = element('status')
const retry = element<HTMLButtonElement>('retry')
const demoContainer = element('demos')
const term = new Terminal({
  fontFamily: '"JetBrains Mono Variable", monospace',
  fontSize: 14,
  lineHeight: 1.3,
  cursorBlink: true,
  cursorStyle: 'bar',
  scrollback: 3000,
  allowProposedApi: false,
  screenReaderMode: true,
  theme: {
    background: '#111111', foreground: '#dedede', cursor: '#dedede',
    selectionBackground: '#38464a',
    black: '#202020', red: '#ef7676', green: '#a3ce76', yellow: '#e8c47a',
    blue: '#83a9eb', magenta: '#c9a0dc', cyan: '#59d4e8', white: '#dedede',
    brightBlack: '#8c8c8c', brightRed: '#ff9696', brightGreen: '#b9e88c', brightYellow: '#ffdb91',
    brightBlue: '#a6c9ff', brightMagenta: '#e6bcf7', brightCyan: '#86e8f4', brightWhite: '#ffffff',
  },
})
const fit = new FitAddon()
term.loadAddon(fit)
term.open(terminalElement)
let session: Session | undefined
let controller = new AbortController()
let generation = 0
let ready = false

function resize() {
  fit.fit()
  element('dimensions').textContent = `${term.cols} × ${term.rows}`
  session?.resize(term.cols, term.rows)
}
new ResizeObserver(resize).observe(terminalElement)
void document.fonts.ready.then(resize)
term.onData(send)

function send(data: string) {
  if (!ready || !session) return
  const current = generation
  void session.write(data).catch((error) => { if (generation === current) showError(error) })
}

function setReady(value: boolean) {
  ready = value
  for (const button of demoContainer.querySelectorAll<HTMLButtonElement>('button')) button.disabled = !value
  for (const button of document.querySelectorAll<HTMLButtonElement>('[data-key]')) button.disabled = !value
}

function showError(error: unknown) {
  setReady(false)
  boot.hidden = false
  boot.dataset.error = 'true'
  title.textContent = 'Your shell could not start'
  detail.textContent = error instanceof Error ? error.message : String(error)
  progress.hidden = true
  retry.hidden = false
  status.textContent = 'Could not start'
}

function showProgress(event: BootProgress) {
  if (event.stage === 'download') {
    const name = event.what === 'kernel' ? 'Linux kernel' : 'Preinstalled environment'
    detail.textContent = `${name} · ${(event.loaded / 1048576).toFixed(1)}${event.total ? ` / ${(event.total / 1048576).toFixed(1)}` : ''} MiB`
    if (event.total) {
      progress.max = event.total
      progress.value = event.loaded
    } else progress.removeAttribute('value')
  } else if (event.stage === 'compiled') {
    detail.textContent = 'Starting Linux and your preinstalled tools…'
    progress.removeAttribute('value')
  } else if (event.stage === 'start') {
    detail.textContent = 'Opening Zsh with Jovial…'
    status.textContent = 'Opening Zsh'
  }
}

async function start() {
  const current = ++generation
  setReady(false)
  controller.abort()
  controller = new AbortController()
  const signal = controller.signal
  await session?.close()
  if (generation !== current) return
  session = undefined
  term.reset()
  boot.hidden = false
  delete boot.dataset.error
  title.textContent = 'Getting your shell ready'
  detail.textContent = 'Checking browser support…'
  progress.hidden = false
  progress.removeAttribute('value')
  retry.hidden = true
  status.textContent = 'Starting Linux'
  resize()
  const timeout = setTimeout(() => {
    if (generation !== current) return
    controller.abort()
    showError(new Error('Starting the environment took too long. Try again to restart the download.'))
  }, 120_000)
  try {
    const created = await startSession({
      cols: term.cols, rows: term.rows, signal,
      onProgress: (event) => { if (generation === current) showProgress(event) },
      onOutput: (bytes) => { if (generation === current) term.write(bytes) },
      onExit: () => {
        if (generation !== current) return
        setReady(false)
        status.textContent = 'Shell exited · Restart to open a new shell'
      },
    })
    if (signal.aborted || generation !== current) { await created.close(); return }
    session = created
    boot.hidden = true
    status.textContent = 'Zsh · Alpine Linux · Runs locally'
    resize()
    setReady(true)
    term.focus()
  } catch (error) {
    if (generation === current && !signal.aborted) showError(error)
  } finally {
    clearTimeout(timeout)
  }
}

for (const demo of demos) {
  const button = document.createElement('button')
  button.type = 'button'
  button.disabled = true
  const name = document.createElement('span')
  name.className = 'demo-name'
  name.textContent = demo.name
  const description = document.createElement('span')
  description.className = 'demo-detail'
  description.textContent = demo.detail
  button.append(name, description)
  button.addEventListener('click', () => {
    send(`\x15${demo.command}\r`)
    term.focus()
  })
  demoContainer.append(button)
}
const keys: Record<string, string> = { escape: '\x1b', tab: '\t', interrupt: '\x03', up: '\x1b[A', down: '\x1b[B' }
for (const button of document.querySelectorAll<HTMLButtonElement>('[data-key]')) {
  button.addEventListener('click', () => {
    send(keys[button.dataset.key!]!)
    term.focus()
  })
}
element('reset').addEventListener('click', () => { void start() })
retry.addEventListener('click', () => { void start() })
const fullscreen = element<HTMLButtonElement>('fullscreen')
if (!document.fullscreenEnabled) fullscreen.hidden = true
fullscreen.addEventListener('click', () => {
  const request = document.fullscreenElement ? document.exitFullscreen() : workspace.requestFullscreen()
  void request.catch((error) => { status.textContent = `Fullscreen unavailable: ${String(error)}` })
})
document.addEventListener('fullscreenchange', () => {
  fullscreen.setAttribute('aria-label', document.fullscreenElement ? 'Exit fullscreen' : 'Enter fullscreen')
  resize()
  term.focus()
})
window.addEventListener('pagehide', () => { controller.abort() })
window.addEventListener('pageshow', (event) => { if (event.persisted) void start() })
void start()
