import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { terminalOptions } from './terminal.ts'
import { waitForShellPrompt, waitForTerminalPaint } from './shell-ready.ts'
import type { Environment, Session } from './runtime.ts'
import type { TerminalPreset } from './demos.ts'

type State = 'idle' | 'opening' | 'ready' | 'exited' | 'error' | 'closed'

export class TerminalTab {
  readonly panel = document.createElement('div')
  readonly term = new Terminal({
    ...terminalOptions,
    cursorBlink: true, cursorStyle: 'bar', scrollback: 3000, screenReaderMode: true,
    theme: {
      background: '#111111', foreground: '#dedede', cursor: '#dedede', selectionBackground: '#38464a',
      black: '#202020', red: '#ef7676', green: '#a3ce76', yellow: '#e8c47a',
      blue: '#83a9eb', magenta: '#c9a0dc', cyan: '#59d4e8', white: '#dedede',
      brightBlack: '#8c8c8c', brightRed: '#ff9696', brightGreen: '#b9e88c', brightYellow: '#ffdb91',
      brightBlue: '#a6c9ff', brightMagenta: '#e6bcf7', brightCyan: '#86e8f4', brightWhite: '#ffffff',
    },
  })
  state: State = 'idle'
  error = ''
  private readonly fit = new FitAddon()
  private readonly controller = new AbortController()
  private session?: Session
  private output?: Promise<void>
  private starting?: Promise<void>
  private focusRequested = false

  constructor(
    readonly id: number,
    readonly preset: TerminalPreset,
    private readonly environment: Promise<Environment>,
    private readonly onChange: () => void,
  ) {
    this.panel.className = 'terminal-panel'
    this.panel.id = `terminal-panel-${id}`
    this.panel.hidden = true
    this.panel.setAttribute('role', 'tabpanel')
    this.panel.setAttribute('aria-labelledby', `terminal-tab-${id}`)
    this.term.loadAddon(this.fit)
    // xterm@6.0.0 sends OSC/DA replies through onData before the first prompt.
    // https://github.com/xtermjs/xterm.js/blob/6.0.0/src/common/services/CoreService.ts#L61
    this.term.onData((data) => this.write(data))
    this.term.onResize(({ cols, rows }) => this.session?.resize(cols, rows))
  }

  show(focus = true) {
    this.focusRequested = focus
    this.panel.hidden = false
    this.resize()
    this.starting ??= this.start()
    if (focus && this.state === 'ready') this.term.focus()
  }

  hide() { this.focusRequested = false; this.panel.hidden = true }

  resize() {
    if (!this.panel.hidden && this.term.element) this.fit.fit()
  }

  send(data: string) {
    if (this.state !== 'ready') return
    this.write(data)
    this.term.focus()
  }

  private write(data: string) {
    if (!this.session || this.controller.signal.aborted) return
    void this.session.write(data).catch((error) => this.fail(error))
  }

  private fail(error: unknown) {
    if (this.controller.signal.aborted) return
    this.error = error instanceof Error ? error.message : String(error)
    this.state = 'error'
    this.onChange()
    this.controller.abort(error)
    void this.session?.close()
  }

  private async start() {
    const signal = this.controller.signal
    this.state = 'opening'
    this.onChange()
    let timer: ReturnType<typeof setTimeout> | undefined
    try {
      const environment = await this.environment
      signal.throwIfAborted()
      this.term.open(this.panel)
      this.resize()
      timer = setTimeout(() => this.fail(new Error('Zsh took too long to open. Try again.')), 90_000)
      const prompt = waitForShellPrompt(this.term, signal)
      await Promise.all([prompt, environment.openSession({
        cols: this.term.cols, rows: this.term.rows, signal, cwd: this.preset.path,
      }).then(async (session) => {
        if (signal.aborted) { await session.close(); return }
        this.session = session
        this.resize()
        this.output = this.pump(session, signal)
      })])
      clearTimeout(timer)
      await new Promise<void>((resolve) => this.term.write('', resolve))
      await waitForTerminalPaint(this.term, signal)
      signal.throwIfAborted()
      this.state = 'ready'
      if (!this.panel.hidden && this.focusRequested) this.term.focus()
      this.onChange()
    } catch (error) {
      this.fail(error)
    } finally {
      clearTimeout(timer)
    }
  }

  private async pump(session: Session, signal: AbortSignal) {
    try {
      await session.output.pipeTo(new WritableStream<Uint8Array>({
        write: (bytes) => new Promise<void>((resolve) => this.term.write(bytes, resolve)),
      }), { signal })
      await session.exited
      if (signal.aborted) return
      if (this.state !== 'ready') throw new Error('Zsh exited before its first prompt was ready.')
      this.state = 'exited'
      this.onChange()
    } catch (error) {
      this.fail(error)
    }
  }

  async dispose() {
    this.hide()
    this.state = 'closed'
    this.controller.abort()
    await this.session?.close()
    await this.output
    this.term.dispose()
    this.panel.remove()
  }
}
