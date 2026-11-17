import { checkSupport, createKernel, type BootProgress, type KernelHandle, type Pty } from 'unkernel/web'

// unkernel@0.1.0-261117-0e4b2ec: js/core/instance.ts and js/core/tty.ts
// https://github.com/pithings/unkernel/tree/0e4b2ec/js/core
export interface Session {
  write(data: string): Promise<void>
  resize(cols: number, rows: number): void
  close(): Promise<void>
}

export interface StartOptions {
  cols: number
  rows: number
  signal: AbortSignal
  onProgress(progress: BootProgress): void
  onOutput(bytes: Uint8Array): void
  onExit(): void
}

export async function startSession(options: StartOptions): Promise<Session> {
  const support = await checkSupport()
  if (!support.ok) {
    throw new Error('This browser cannot run the Linux environment yet. Open this page in an up-to-date Chrome or Edge browser with WebAssembly JSPI support.')
  }
  options.signal.throwIfAborted()
  let vm: KernelHandle | undefined
  let pty: Pty | undefined
  try {
    vm = await createKernel({
      kernel: new URL('runtime/unkernel.wasm', document.baseURI),
      initrd: new URL('runtime/jovial.cpio.gz', document.baseURI),
      worker: true,
      shared: false,
      memoryMiB: 768,
      memoryFallbackMiB: [512],
      cmdline: 'console=hvc0 rdinit=/init quiet',
      signal: options.signal,
      onProgress: options.onProgress,
      log: (message) => console.debug('[unkernel]', message),
    })
    pty = await vm.spawn('/usr/local/bin/jovial-shell', [], {
      cols: options.cols,
      rows: options.rows,
      term: 'xterm-256color',
      signal: options.signal,
      timeout: 90_000,
    })
    const output = pty.output.getReader()
    const pump = async () => {
      try {
        while (true) {
          const chunk = await output.read()
          if (chunk.done) break
          options.onOutput(chunk.value)
        }
        await pty!.ended
        if (!options.signal.aborted) options.onExit()
      } catch (error) {
        if (!options.signal.aborted) {
          console.error(error)
          options.onExit()
        }
      } finally {
        output.releaseLock()
      }
    }
    void pump()
    return {
      write: (data) => pty!.write(data),
      resize: (cols, rows) => pty!.resize(cols, rows),
      async close() {
        await vm!.stop()
      },
    }
  } catch (error) {
    await vm?.stop()
    throw error
  }
}
