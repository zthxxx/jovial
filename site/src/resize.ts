import './resize.css'

export interface TerminalResizeOptions {
  element: HTMLElement
  container: HTMLElement
  getMinimumHeight(): number
  /** The rendered proportion includes the current minimum-width constraint. */
  onResize?(size: { widthRatio: number }): void
}

export interface TerminalResizeHandle {
  reset(): void
  refresh(): void
  setWidthRatio(ratio: number): void
  /** User intent survives temporary minimum-width constraints on narrow screens. */
  getWidthRatio(): number
  destroy(): void
}

type Axis = 'both' | 'width' | 'height'
interface Size { widthRatio: number; heightRatio: number }
interface Drag {
  original: Size
  width: number
  height: number
  pointer: number
  x: number
  y: number
  target: HTMLElement
}

export function attachTerminalResize(options: TerminalResizeOptions): TerminalResizeHandle {
  const { element, container, getMinimumHeight, onResize } = options
  const original = { width: element.style.width, minHeight: element.style.minHeight, heightRatio: element.style.getPropertyValue('--terminal-height-ratio') }
  const body = element.querySelector<HTMLElement>('.terminal-body')!
  const listeners = new AbortController()
  let drag: Drag | undefined

  const corner = document.createElement('button')
  corner.type = 'button'
  corner.className = 'terminal-resize-corner'
  corner.setAttribute('aria-label', 'Resize terminal')
  corner.title = 'Drag to resize. Arrow keys resize; Home resets.'
  corner.innerHTML = '<svg aria-hidden="true" viewBox="0 0 24 24"><path d="m7 19 12-12M13 19l6-6M19 19h.01" /></svg>'
  const right = document.createElement('div')
  right.className = 'terminal-resize-edge terminal-resize-right'
  right.setAttribute('aria-hidden', 'true')
  const bottom = document.createElement('div')
  bottom.className = 'terminal-resize-edge terminal-resize-bottom'
  bottom.setAttribute('aria-hidden', 'true')
  // Resolve the responsive CSS height without duplicating its breakpoints in JavaScript.
  const reference = document.createElement('div')
  reference.className = 'terminal-resize-height-reference'
  reference.setAttribute('aria-hidden', 'true')
  element.append(corner, right, bottom, reference)

  let size: Size = { widthRatio: 1, heightRatio: 1 }
  element.dataset.resizable = ''

  function availableWidth() {
    const style = getComputedStyle(container)
    return container.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight)
  }
  function apply(next: Size) {
    if (document.fullscreenElement === element) return
    const maximumWidth = availableWidth()
    if (maximumWidth <= 0) return
    size = { widthRatio: Math.max(1 / 3, Math.min(1, next.widthRatio)), heightRatio: Math.max(0, next.heightRatio) }
    // A narrow viewport may clamp the rendered width without changing the user's proportion.
    const widthRatio = Math.max(size.widthRatio, Math.min(288, maximumWidth) / maximumWidth)
    element.style.width = `${widthRatio * 100}%`
    element.style.setProperty('--terminal-height-ratio', String(size.heightRatio))
    element.style.minHeight = `${getMinimumHeight()}px`
    const rect = element.getBoundingClientRect()
    corner.setAttribute('aria-label', `Resize terminal, ${Math.round(rect.width)} by ${Math.round(rect.height)} pixels`)
    onResize?.({ widthRatio })
  }
  function finish(cancel = false) {
    const ended = drag
    if (!ended) return
    drag = undefined
    delete element.dataset.resizing
    if (cancel) apply(ended.original)
    if (ended.target.hasPointerCapture(ended.pointer)) ended.target.releasePointerCapture(ended.pointer)
  }
  function bind(target: HTMLElement, axis: Axis) {
    target.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 || document.fullscreenElement === element) return
      event.preventDefault()
      finish()
      const rect = element.getBoundingClientRect()
      drag = { original: { ...size }, width: rect.width, height: body.getBoundingClientRect().height, x: event.clientX, y: event.clientY, pointer: event.pointerId, target }
      element.dataset.resizing = axis
      target.setPointerCapture(event.pointerId)
      corner.focus({ preventScroll: true })
    }, { signal: listeners.signal })
    target.addEventListener('pointermove', (event) => {
      if (!drag || drag.pointer !== event.pointerId || drag.target !== target) return
      event.preventDefault()
      const dx = event.clientX - drag.x
      const dy = event.clientY - drag.y
      apply({
        widthRatio: axis === 'height' || dx === 0 ? drag.original.widthRatio : (drag.width + dx) / availableWidth(),
        heightRatio: axis === 'width' || dy === 0 ? drag.original.heightRatio : (drag.height + dy) / reference.getBoundingClientRect().height,
      })
    }, { signal: listeners.signal })
    for (const name of ['pointerup', 'pointercancel', 'lostpointercapture']) {
      target.addEventListener(name, () => finish(), { signal: listeners.signal })
    }
  }
  bind(corner, 'both')
  bind(right, 'width')
  bind(bottom, 'height')
  corner.addEventListener('keydown', (event) => {
    if (document.fullscreenElement === element) return
    const step = event.shiftKey ? 64 : 16
    const direction: Record<string, { width: number; height: number }> = {
      ArrowLeft: { width: -step, height: 0 }, ArrowRight: { width: step, height: 0 },
      ArrowUp: { width: 0, height: -step }, ArrowDown: { width: 0, height: step },
    }
    if (event.key === 'Home') { event.preventDefault(); apply({ widthRatio: 1, heightRatio: 1 }) }
    else if (direction[event.key]) {
      event.preventDefault()
      const delta = direction[event.key]!
      apply({
        widthRatio: delta.width ? (element.getBoundingClientRect().width + delta.width) / availableWidth() : size.widthRatio,
        heightRatio: delta.height ? (body.getBoundingClientRect().height + delta.height) / reference.getBoundingClientRect().height : size.heightRatio,
      })
    }
  }, { signal: listeners.signal })
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && drag) { event.preventDefault(); finish(true) }
  }, { signal: listeners.signal })
  document.addEventListener('fullscreenchange', () => { finish(); apply(size) }, { signal: listeners.signal })
  window.addEventListener('blur', () => finish(), { signal: listeners.signal })
  window.addEventListener('resize', () => apply(size), { signal: listeners.signal })
  let previousWidth = availableWidth()
  const observer = new ResizeObserver(() => {
    const width = availableWidth()
    if (width !== previousWidth) { previousWidth = width; apply(size) }
  })
  observer.observe(container)
  apply(size)

  return {
    reset() { finish(); apply({ widthRatio: 1, heightRatio: 1 }) },
    refresh() { apply(size) },
    setWidthRatio(widthRatio) { finish(); apply({ ...size, widthRatio }) },
    getWidthRatio() { return size.widthRatio },
    destroy() {
      finish()
      listeners.abort()
      observer.disconnect()
      corner.remove()
      right.remove()
      bottom.remove()
      reference.remove()
      delete element.dataset.resizable
      element.style.width = original.width
      element.style.minHeight = original.minHeight
      if (original.heightRatio) element.style.setProperty('--terminal-height-ratio', original.heightRatio)
      else element.style.removeProperty('--terminal-height-ratio')
    },
  }
}
