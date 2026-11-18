import { checkSupport, createKernel, loadBytes, loadKernelModule, moduleIsMemory64, type BootProgress, type Pty } from 'unkernel/web'

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
  onProgress(progress: EnvironmentProgress): void
}

export type EnvironmentProgress = BootProgress | { stage: 'pty' }

export interface Environment {
  openSession(options: SessionOptions): Promise<Session>
  close(): Promise<void>
}

export type StartOptions = SessionOptions & EnvironmentOptions

const shellQuote = (value: string) => "'" + value.replaceAll("'", "'\\''") + "'"

type BootAsset = { url: string; bytes: number }
declare const __JOVIAL_BOOT_ASSETS__: Record<'kernel' | 'initrd', BootAsset>
const bootAssets = __JOVIAL_BOOT_ASSETS__
let compiledKernel: { module: WebAssembly.Module; bytes: number } | undefined

async function fetchBootAsset(asset: BootAsset, signal: AbortSignal): Promise<Response> {
  const response = await fetch(new URL(asset.url, document.baseURI), {
    signal,
    priority: import.meta.env.PROD ? 'low' : 'auto',
  })
  if (!response.ok) throw new Error(`Could not download ${response.url}: HTTP ${response.status}`)
  return response
}

async function loadBootAssets(options: EnvironmentOptions) {
  const controller = new AbortController()
  const signal = AbortSignal.any([options.signal, controller.signal])
  let initrdBytes = 0
  const progress = (event: BootProgress) => {
    if (event.stage !== 'download') return options.onProgress(event)
    const bytes = event.what === 'kernel' ? bootAssets.kernel.bytes : initrdBytes
    options.onProgress({ ...event, total: Math.max(bytes, event.total, event.done ? event.loaded : 0) })
  }
  for (const what of ['kernel', 'initrd'] as const) {
    progress({ stage: 'download', what, url: bootAssets[what].url, loaded: 0, total: 0, done: false })
  }
  const loadKernel = async () => {
    const asset = bootAssets.kernel
    if (compiledKernel) {
      const { module, bytes } = compiledKernel
      progress({ stage: 'download', what: 'kernel', url: asset.url, loaded: bytes, total: bytes, done: true })
      return module
    }
    progress({ stage: 'compile' })
    const started = performance.now()
    let bytes = 0
    const module = await loadKernelModule(await fetchBootAsset(asset, signal), {
      signal,
      onProgress(event) {
        bytes = event.loaded
        progress(event)
      },
    })
    signal.throwIfAborted()
    compiledKernel = { module, bytes }
    progress({ stage: 'compiled', ms: performance.now() - started, memory64: moduleIsMemory64(module) })
    return module
  }
  try {
    // unkernel@0.1.0-261117-0e4b2ec's createKernelInWorker prepares kernel and
    // initrd in sequence. Its loaders can stream both responses in parallel.
    // https://github.com/pithings/unkernel/blob/0e4b2ec/js/core/worker-host.ts
    return await Promise.all([
      loadKernel(),
      fetchBootAsset(bootAssets.initrd, signal).then((response) => {
        // The browser may decode a gzip response before the SDK counts its bytes.
        if (!response.headers.has('content-encoding')) initrdBytes = bootAssets.initrd.bytes
        return loadBytes(response, { what: 'initrd', signal, onProgress: progress })
      }),
    ])
  } catch (error) {
    controller.abort()
    throw error
  }
}

export async function bootEnvironment(options: EnvironmentOptions): Promise<Environment> {
  const support = await checkSupport()
  if (!support.ok) {
    throw new Error('This browser cannot run the Linux environment yet. Open this page in an up-to-date Chrome or Edge browser with WebAssembly JSPI support.')
  }
  options.signal.throwIfAborted()
  const [kernel, initrd] = await loadBootAssets(options)
  options.signal.throwIfAborted()
  const vm = await createKernel({
    kernel,
    initrd,
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
      options.onProgress({ stage: 'pty' })
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
