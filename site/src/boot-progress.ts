import './boot-progress.css'
import type { EnvironmentProgress } from './runtime.ts'

type Stage = 'kernel' | 'disk' | 'linux' | 'shell'
type Download = Extract<Stage, 'kernel' | 'disk'>
type State = 'waiting' | 'active' | 'done'

interface Transfer {
  loaded: number
  total?: number
  done: boolean
}

interface StageRow {
  row: HTMLElement
  mark: Element
  detail: Element
}

const marks = { waiting: '○', active: '●', done: '✓' } satisfies Record<State, string>
const size = (bytes: number) => (bytes / 2 ** 20).toFixed(1)

// Stage layout follows terminal-glance/components/LinuxBoot.vue at 14b7ddc.
// https://github.com/zthxxx/slides/blob/14b7ddcccac33fccea2e6c1f74cb17853eb138e6/present/terminal-glance/components/LinuxBoot.vue
export class BootScreen {
  private readonly label: HTMLElement
  private readonly stages: HTMLElement
  private readonly detail: HTMLElement
  private readonly progress: HTMLProgressElement
  private readonly rows = new Map<Stage, StageRow>()
  private readonly transfers = new Map<Download, Transfer>()
  private linuxStartedAt?: number

  constructor(private readonly root: HTMLElement) {
    this.label = root.querySelector<HTMLElement>('#boot-label')!
    this.stages = root.querySelector<HTMLElement>('#boot-stages')!
    this.detail = root.querySelector<HTMLElement>('#boot-detail')!
    this.progress = root.querySelector<HTMLProgressElement>('#boot-progress')!
    for (const row of this.stages.querySelectorAll<HTMLElement>('[data-stage]')) {
      this.rows.set(row.dataset.stage as Stage, {
        row,
        mark: row.querySelector('.boot-mark')!,
        detail: row.querySelector('.boot-detail')!,
      })
    }
  }

  reset() {
    this.transfers.clear()
    this.linuxStartedAt = undefined
    this.stage('kernel', 'waiting', 'WebAssembly')
    this.stage('disk', 'waiting', 'Alpine Linux')
    this.stage('linux', 'waiting', 'Kernel and init')
    this.stage('shell', 'waiting', 'Zsh and Jovial')
    this.progress.value = 0
    this.show()
  }

  show() {
    delete this.root.dataset.error
    if (this.label.textContent !== 'Booting Linux…') this.label.textContent = 'Booting Linux…'
    this.stages.hidden = false
    this.progress.hidden = false
    this.detail.hidden = true
    this.root.hidden = false
  }

  message(title: string, detail: string, error = false) {
    this.root.toggleAttribute('data-error', error)
    this.label.textContent = title
    this.detail.textContent = detail
    this.stages.hidden = true
    this.progress.hidden = true
    this.detail.hidden = false
    this.root.hidden = false
  }

  // unkernel@0.1.0-261117-0e4b2ec reports kernel and initrd independently.
  // https://github.com/pithings/unkernel/blob/0e4b2ec/js/core/instance.ts#L37
  update(event: EnvironmentProgress) {
    if (event.stage === 'download') {
      if (event.what !== 'kernel' && event.what !== 'initrd') return
      const name = event.what === 'kernel' ? 'kernel' : 'disk'
      this.transfers.set(name, { loaded: event.loaded, total: event.total, done: event.done })
      const detail = event.done ? `${size(event.loaded)} MiB`
        : event.total ? `${size(event.loaded)} / ${size(event.total)} MiB`
          : `${size(event.loaded)} MiB received`
      this.stage(name, event.done ? 'done' : 'active', detail)
      this.updateProgress()
    } else if (event.stage === 'memory' || event.stage === 'instantiate' || event.stage === 'start') {
      this.linuxStartedAt ??= performance.now()
      this.stage('linux', 'active', 'Kernel and init')
    } else if (event.stage === 'pty') {
      this.linuxReady()
      this.stage('shell', 'active', 'Zsh and Jovial')
    }
  }

  private linuxReady() {
    if (this.rows.get('linux')?.row.dataset.state === 'done') return
    this.stage('kernel', 'done', this.transferSize('kernel', 'WebAssembly'))
    this.stage('disk', 'done', this.transferSize('disk', 'Alpine Linux'))
    const elapsed = this.linuxStartedAt === undefined ? '' : ` · ${((performance.now() - this.linuxStartedAt) / 1000).toFixed(2)} s`
    this.stage('linux', 'done', `Kernel and init${elapsed}`)
    this.progress.value = 1
  }

  private transferSize(name: Download, fallback: string) {
    const transfer = this.transfers.get(name)
    return transfer ? `${size(transfer.loaded)} MiB` : fallback
  }

  private updateProgress() {
    const kernel = this.transfers.get('kernel')
    const disk = this.transfers.get('disk')
    if (kernel?.done && disk?.done) {
      this.progress.value = 1
      return
    }
    const kernelTotal = kernel?.done ? kernel.loaded : kernel?.total
    const diskTotal = disk?.done ? disk.loaded : disk?.total
    if (kernel && disk && kernelTotal && diskTotal) {
      this.progress.value = Math.min(1, (kernel.loaded + disk.loaded) / (kernelTotal + diskTotal))
    } else {
      this.progress.removeAttribute('value')
    }
  }

  private stage(name: Stage, state: State, detail: string) {
    const stage = this.rows.get(name)!
    if (stage.row.dataset.state !== state) {
      stage.row.dataset.state = state
      stage.mark.textContent = marks[state]
    }
    if (stage.detail.textContent !== detail) stage.detail.textContent = detail
  }
}
