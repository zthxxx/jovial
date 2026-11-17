import type { Terminal } from '@xterm/xterm'

// site/image/terminal-ready.zsh emits this OSC after Zsh paints its first prompt.
export function waitForShellPrompt(term: Terminal, signal: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const handler = term.parser.registerOscHandler(777, (data) => {
      if (data !== 'jovial-ready') return false
      cleanup()
      resolve()
      return true
    })
    const abort = () => { cleanup(); reject(signal.reason) }
    const cleanup = () => {
      handler.dispose()
      signal.removeEventListener('abort', abort)
    }
    signal.addEventListener('abort', abort, { once: true })
    if (signal.aborted) abort()
  })
}

// xterm@6.0.0: onRender fires after the viewport renderer updates its rows.
// https://github.com/xtermjs/xterm.js/blob/6.0.0/src/browser/services/RenderService.ts
export function waitForTerminalPaint(term: Terminal, signal: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const rendered = term.onRender(() => { cleanup(); resolve() })
    const abort = () => { cleanup(); reject(signal.reason) }
    const cleanup = () => {
      rendered.dispose()
      signal.removeEventListener('abort', abort)
    }
    signal.addEventListener('abort', abort, { once: true })
    if (signal.aborted) abort()
    else term.refresh(0, term.rows - 1)
  })
}
