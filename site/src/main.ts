import '@fontsource-variable/jetbrains-mono'
import '@xterm/xterm/css/xterm.css'
import './style.css'
import './landing.css'
import './landing-assets.ts'
import './terminal-theme.css'
import { defaultPresets, presets, type TerminalPreset } from './demos.ts'
import { loadTerminalFonts } from './terminal.ts'
import { TerminalTab } from './terminal-tab.ts'
import { bootEnvironment, type Environment } from './runtime.ts'
import { attachTerminalResize } from './resize.ts'
import type { BootProgress } from 'unkernel/web'
import { applyColorScheme, getColorScheme, restoreColorScheme } from './theme.ts'
import { loadGitHubStars } from './github.ts'

restoreColorScheme()
void loadGitHubStars()

const element = <T extends HTMLElement>(id: string) => document.getElementById(id) as T
const workspace = document.querySelector<HTMLElement>('.workspace')!
const body = document.querySelector<HTMLElement>('.terminal-body')!
const panels = element('terminal-panels')
const tabList = element('terminal-tabs')
const boot = element('boot')
const title = element('boot-title')
const detail = element('boot-detail')
const progress = element<HTMLProgressElement>('boot-progress')
const retry = element<HTMLButtonElement>('retry')
const status = element('status')
const commands = element('demos')
const explore = document.querySelector<HTMLElement>('.explore')!
const add = element<HTMLButtonElement>('new-terminal')
const reset = element<HTMLButtonElement>('reset')
interface Entry { tab: TerminalTab; button: HTMLButtonElement; item: HTMLElement }
const tabs = new Map<number, Entry>()
let activeId: number | undefined
let nextId = 1
let generation = 0
let controller = new AbortController()
let environment: Environment | undefined
let environmentReady: Promise<Environment>
let environmentState: 'loading' | 'ready' | 'error' = 'loading'
let environmentError = ''

function active() { return activeId === undefined ? undefined : tabs.get(activeId)?.tab }

function keepSelectedVisible() {
  const item = activeId === undefined ? undefined : tabs.get(activeId)?.item
  if (!item) return
  const parent = tabList.getBoundingClientRect()
  const selected = item.getBoundingClientRect()
  if (selected.left < parent.left) tabList.scrollLeft -= parent.left - selected.left
  else if (selected.right > parent.right) tabList.scrollLeft += selected.right - parent.right
}

function updateControls() {
  const tab = active()
  keepSelectedVisible()
  const ready = tab?.state === 'ready'
  for (const button of commands.querySelectorAll<HTMLButtonElement>('button')) button.disabled = !ready
  for (const button of document.querySelectorAll<HTMLButtonElement>('[data-key]')) button.disabled = !ready
  if (!tab) {
    boot.hidden = false
    delete boot.dataset.error
    title.textContent = 'Open a terminal'
    detail.textContent = 'Create a new tab to return to ~/Project.'
    progress.hidden = true
    retry.hidden = false
    retry.textContent = 'New terminal'
    status.textContent = 'No open terminals'
    element('dimensions').textContent = ''
    return
  }
  const failed = environmentState === 'error' || tab.state === 'error'
  boot.hidden = ready || tab.state === 'exited'
  retry.hidden = !failed
  retry.textContent = 'Try again'
  progress.hidden = failed
  if (failed) {
    boot.dataset.error = ''
    title.textContent = 'Your shell could not start'
    detail.textContent = environmentError || tab.error
    status.textContent = 'Could not start'
  } else {
    delete boot.dataset.error
    title.textContent = 'Getting your shell ready'
    if (environmentState === 'ready' && !ready) {
      detail.textContent = `Opening Zsh in ${tab.preset.label}…`
      progress.removeAttribute('value')
    }
    status.textContent = ready ? 'Zsh · Alpine Linux · Runs locally'
      : tab.state === 'exited' ? 'Shell exited · Open another terminal'
        : environmentState === 'loading' ? 'Starting Linux' : 'Opening Zsh'
  }
  element('dimensions').textContent = `${tab.term.cols} × ${tab.term.rows}`
}

function showCommands() {
  commands.replaceChildren()
  const tab = active()
  element('command-title').textContent = tab ? `${tab.preset.name} commands` : 'Terminal commands'
  element('command-detail').textContent = tab ? `Run a preset in terminal ${tab.id}, or type your own commands.` : 'Open a terminal to try a command.'
  for (const preset of tab?.preset.commands ?? []) {
    const button = document.createElement('button')
    button.type = 'button'
    const name = document.createElement('span')
    name.className = 'demo-name'
    name.textContent = preset.name
    const description = document.createElement('span')
    description.className = 'demo-detail'
    description.textContent = preset.detail
    button.append(name, description)
    button.addEventListener('click', () => {
      active()?.send(`\x15${preset.command}\r`)
      keepSelectedVisible()
    })
    commands.append(button)
  }
  updateControls()
}

function select(id: number, focus = true) {
  const selected = tabs.get(id)
  if (!selected) return
  activeId = id
  for (const [key, entry] of tabs) {
    const current = key === id
    entry.button.setAttribute('aria-selected', String(current))
    entry.button.tabIndex = current ? 0 : -1
    entry.item.toggleAttribute('data-selected', current)
    if (current) entry.tab.show(focus)
    else entry.tab.hide()
  }
  keepSelectedVisible()
  showCommands()
  resize.refresh()
}

function create(preset: TerminalPreset = presets.project) {
  const id = nextId++
  const current = generation
  const tab = new TerminalTab(id, preset, environmentReady, () => {
    if (generation === current && activeId === id) updateControls()
  })
  const item = document.createElement('div')
  item.className = 'terminal-tab-item'
  const button = document.createElement('button')
  button.type = 'button'
  button.className = 'terminal-tab'
  button.id = `terminal-tab-${id}`
  button.setAttribute('role', 'tab')
  button.setAttribute('aria-controls', tab.panel.id)
  button.setAttribute('aria-selected', 'false')
  button.tabIndex = -1
  button.textContent = `${id} ${preset.label}`
  button.title = `Terminal ${id} · opened in ${preset.label}`
  button.addEventListener('click', () => select(id))
  button.addEventListener('keydown', (event) => {
    const ids = [...tabs.keys()]
    const index = ids.indexOf(id)
    const target = event.key === 'ArrowRight' ? ids[(index + 1) % ids.length]
      : event.key === 'ArrowLeft' ? ids[(index + ids.length - 1) % ids.length]
        : event.key === 'Home' ? ids[0] : event.key === 'End' ? ids.at(-1) : undefined
    if (target !== undefined) { event.preventDefault(); select(target, false); tabs.get(target)!.button.focus() }
  })
  const close = document.createElement('button')
  close.type = 'button'
  close.className = 'terminal-tab-close'
  close.setAttribute('aria-label', `Close terminal ${id}`)
  close.title = `Close terminal ${id}`
  close.textContent = '×'
  close.addEventListener('click', () => remove(id))
  item.append(button, close)
  tabList.append(item)
  panels.append(tab.panel)
  tabs.set(id, { tab, button, item })
  return id
}

function remove(id: number) {
  const entry = tabs.get(id)
  if (!entry) return
  const ids = [...tabs.keys()]
  const index = ids.indexOf(id)
  tabs.delete(id)
  entry.item.remove()
  void entry.tab.dispose()
  if (activeId === id) {
    const next = ids[index + 1] ?? ids[index - 1]
    if (next !== undefined) select(next)
    else { activeId = undefined; showCommands() }
  }
}

const resize = attachTerminalResize({
  element: workspace,
  container: workspace.parentElement!,
  getMinimumHeight() {
    const row = active()?.panel.querySelector('.xterm-rows > div')?.getBoundingClientRect().height || 16
    return workspace.getBoundingClientRect().height - panels.getBoundingClientRect().height + row * 10 + 1
  },
  onResize() {
    active()?.resize()
    explore.style.width = `${workspace.getBoundingClientRect().width}px`
    updateControls()
  },
})
new ResizeObserver(() => { active()?.resize(); updateControls() }).observe(body)

function showProgress(event: BootProgress) {
  if (!active()) return
  if (event.stage === 'download') {
    const name = event.what === 'kernel' ? 'Linux kernel' : 'Preinstalled environment'
    detail.textContent = `${name} · ${(event.loaded / 1048576).toFixed(1)}${event.total ? ` / ${(event.total / 1048576).toFixed(1)}` : ''} MiB`
    if (event.total) { progress.max = event.total; progress.value = event.loaded } else progress.removeAttribute('value')
  } else if (event.stage === 'compiled' || event.stage === 'start') {
    detail.textContent = 'Starting Linux and opening Zsh…'
    progress.removeAttribute('value')
  }
}

async function start(focusTerminal = true) {
  const current = ++generation
  add.disabled = true
  reset.disabled = true
  retry.disabled = true
  controller.abort()
  const previousEnvironment = environment
  environment = undefined
  const previous = [...tabs.values()]
  tabs.clear()
  activeId = undefined
  boot.hidden = false
  retry.hidden = true
  progress.hidden = false
  progress.removeAttribute('value')
  title.textContent = 'Getting your shell ready'
  detail.textContent = 'Starting a fresh environment…'
  status.textContent = 'Starting Linux'
  for (const button of document.querySelectorAll<HTMLButtonElement>('#demos button, [data-key]')) button.disabled = true
  await Promise.all(previous.map((entry) => entry.tab.dispose()))
  await previousEnvironment?.close()
  if (generation !== current) return
  tabList.replaceChildren()
  panels.replaceChildren()
  nextId = 1
  const currentController = new AbortController()
  controller = currentController
  const signal = currentController.signal
  environmentState = 'loading'
  environmentError = ''
  detail.textContent = 'Loading your environment and terminal fonts…'
  progress.hidden = false
  progress.removeAttribute('value')
  const timeout = setTimeout(() => currentController.abort(new Error('Starting Linux took too long. Try again.')), 120_000)
  environmentReady = Promise.all([
    loadTerminalFonts(),
    bootEnvironment({ signal, onProgress: (event) => { if (generation === current && !signal.aborted) showProgress(event) } }),
  ]).then(async ([, ready]) => {
    if (generation !== current || signal.aborted) {
      await ready.close()
      throw signal.reason ?? new DOMException('Environment restarted', 'AbortError')
    }
    environment = ready
    environmentState = 'ready'
    resize.refresh()
    updateControls()
    return ready
  }).finally(() => clearTimeout(timeout))
  void environmentReady.catch((error) => {
    if (generation !== current) return
    currentController.abort(error)
    environmentState = 'error'
    environmentError = error instanceof Error ? error.message : String(error)
    updateControls()
  })
  for (const preset of defaultPresets) create(preset)
  add.disabled = false
  reset.disabled = false
  retry.disabled = false
  select(1, focusTerminal)
}

add.addEventListener('click', () => select(create()))
reset.addEventListener('click', () => { void start() })
retry.addEventListener('click', () => {
  if (!active()) select(create())
  else void start()
})
const keys: Record<string, string> = { escape: '\x1b', tab: '\t', interrupt: '\x03', up: '\x1b[A', down: '\x1b[B' }
for (const button of document.querySelectorAll<HTMLButtonElement>('[data-key]')) {
  button.addEventListener('click', () => active()?.send(keys[button.dataset.key!]!))
}
const fullscreen = element<HTMLButtonElement>('fullscreen')
if (!document.fullscreenEnabled) fullscreen.hidden = true
fullscreen.addEventListener('click', () => {
  const request = document.fullscreenElement ? document.exitFullscreen() : workspace.requestFullscreen()
  void request.catch((error) => { status.textContent = `Fullscreen unavailable: ${String(error)}` })
})
document.addEventListener('fullscreenchange', () => {
  fullscreen.setAttribute('aria-label', document.fullscreenElement ? 'Exit fullscreen' : 'Enter fullscreen')
  active()?.resize()
  updateControls()
})
element<HTMLButtonElement>('theme-toggle')?.addEventListener('click', () => {
  applyColorScheme(getColorScheme() === 'dark' ? 'light' : 'dark', true)
  void start(false)
})
window.addEventListener('pagehide', () => { controller.abort() })
window.addEventListener('pageshow', (event) => { if (event.persisted) void start() })
void start()
