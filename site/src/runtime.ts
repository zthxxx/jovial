import { checkSupport, createKernel, type BootProgress, type Pty } from 'unkernel/web'

// unkernel@0.1.0-261117-0e4b2ec: js/core/instance.ts and js/core/tty.ts
// https://github.com/pithings/unkernel/tree/0e4b2ec/js/core
export interface Session {
  output: ReadableStream<Uint8Array>
  exited: Pty['ended']
  write(data: string): Promise<void>
  resize(cols: number, rows: number): void
  close(): Promise<void>
}

export interface SessionOptions {
  cols: number
  rows: number
  signal?: AbortSignal
  file?: string
  args?: string[]
  cwd?: string
}

export interface EnvironmentOptions {
  signal: AbortSignal
  onProgress(progress: BootProgress): void
}

export interface Environment {
  openSession(options: SessionOptions): Promise<Session>
  close(): Promise<void>
}

export type StartOptions = SessionOptions & EnvironmentOptions

const shellQuote = (value: string) => "'" + value.replaceAll("'", "'\\''") + "'"

export async function bootEnvironment(options: EnvironmentOptions): Promise<Environment> {
  const support = await checkSupport()
  if (!support.ok) {
    throw new Error('This browser cannot run the Linux environment yet. Open this page in an up-to-date Chrome or Edge browser with WebAssembly JSPI support.')
  }
  options.signal.throwIfAborted()
  const vm = await createKernel({
    kernel: new URL('/runtime/unkernel.wasm', document.baseURI),
    initrd: new URL('/runtime/jovial.cpio.gz', document.baseURI),
    worker: true,
    shared: false,
    memoryMiB: 768,
    memoryFallbackMiB: [512],
    cmdline: 'console=hvc0 rdinit=/init quiet',
    signal: options.signal,
    onProgress: options.onProgress,
    log: (message) => console.debug('[unkernel]', message),
  })
  let closed = false
  const cleanups = new Set<() => void>()
  return {
    async openSession(sessionOptions) {
      options.signal.throwIfAborted()
      if (closed) throw new Error('The Linux environment is closed.')
      const signal = sessionOptions.signal
        ? AbortSignal.any([options.signal, sessionOptions.signal])
        : options.signal
      signal.throwIfAborted()
      // su -l changes directory; set the initial path in the user's shell afterward.
      const customDirectory = sessionOptions.cwd && !sessionOptions.file
      const file = customDirectory ? '/bin/su' : sessionOptions.file ?? '/usr/local/bin/jovial-shell'
      const args = customDirectory
        ? ['-l', 'zthxxx', '-c', `cd -- ${shellQuote(sessionOptions.cwd!)} && exec /bin/zsh -i`]
        : sessionOptions.args ?? []
      const pty = await vm.spawn(file, args, {
        cols: sessionOptions.cols,
        rows: sessionOptions.rows,
        cwd: sessionOptions.file ? sessionOptions.cwd : undefined,
        term: 'xterm-256color',
        signal,
        timeout: 90_000,
      })
      if (signal.aborted || closed) {
        await pty.close()
        signal.throwIfAborted()
        throw new Error('The Linux environment is closed.')
      }
      const cleanup = () => {
        signal.removeEventListener('abort', abort)
        cleanups.delete(cleanup)
      }
      const close = async () => {
        cleanup()
        await pty.close()
      }
      const abort = () => { void close().catch(() => {}) }
      cleanups.add(cleanup)
      signal.addEventListener('abort', abort, { once: true })
      void pty.ended.then(cleanup, cleanup)
      return {
        output: pty.output,
        exited: pty.ended,
        write: (data) => pty.write(data),
        resize: (cols, rows) => pty.resize(cols, rows),
        close,
      }
    },
    async close() {
      if (closed) return
      closed = true
      for (const cleanup of cleanups) cleanup()
      await vm.stop()
    },
  }
}

// The local performance page owns one VM per measurement.
export async function startSession(options: StartOptions): Promise<Session> {
  const environment = await bootEnvironment(options)
  try {
    const session = await environment.openSession(options)
    return { ...session, close: () => environment.close() }
  } catch (error) {
    await environment.close()
    throw error
  }
}
