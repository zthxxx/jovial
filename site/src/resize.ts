import './resize.css'

export interface TerminalResizeOptions {
  element: HTMLElement
  container: HTMLElement
  getMinimumHeight(): number
  onResize?(): void
}

export interface TerminalResizeHandle {
  reset(): void
  refresh(): void
  destroy(): void
}

type Axis = 'both' | 'width' | 'height'
interface Size { width: number; height: number }
interface Drag extends Size { pointer: number; x: number; y: number; axis: Axis; target: HTMLElement }

export function attachTerminalResize(options: TerminalResizeOptions): TerminalResizeHandle {
  const { element, container, getMinimumHeight, onResize } = options
  const original = { width: element.style.width, height: element.style.height }
  const initialRect = element.getBoundingClientRect()
  const minimumWidth = Math.max(initialRect.width / 3, Math.min(360, initialRect.width))
  const listeners = new AbortController()
  let drag: Drag | undefined

  const bar = document.createElement('div')
  bar.className = 'terminal-resize-bar'
  const hint = document.createElement('span')
  hint.className = 'terminal-resize-hint'
  hint.textContent = 'Drag edges or corner to resize'
  const corner = document.createElement('button')
  corner.type = 'button'
  corner.className = 'terminal-resize-corner'
  corner.setAttribute('aria-label', 'Resize terminal')
  corner.title = 'Drag to resize. Arrow keys resize; Home resets.'
  corner.innerHTML = '<svg aria-hidden="true" viewBox="0 0 24 24"><path d="m7 19 12-12M13 19l6-6M19 19h.01" /></svg>'
  bar.append(hint, corner)
  const right = document.createElement('div')
  right.className = 'terminal-resize-edge terminal-resize-right'
  right.setAttribute('aria-hidden', 'true')
  const bottom = document.createElement('div')
  bottom.className = 'terminal-resize-edge terminal-resize-bottom'
  bottom.setAttribute('aria-hidden', 'true')
  element.append(bar, right, bottom)

  const initial = { width: initialRect.width, height: initialRect.height + bar.getBoundingClientRect().height }
  let size = { ...initial }
  element.style.width = `${initial.width}px`
  element.style.height = `${initial.height}px`
  element.dataset.resizable = ''

  function availableWidth() {
    const style = getComputedStyle(container)
    return container.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight)
  }
  function apply(next: Size) {
    if (document.fullscreenElement === element) return
    const maximumWidth = availableWidth()
    if (maximumWidth <= 0) return
    size = {
      width: Math.max(Math.min(minimumWidth, maximumWidth), Math.min(maximumWidth, next.width)),
      height: Math.max(getMinimumHeight(), next.height),
    }
    element.style.width = `${size.width}px`
    element.style.height = `${size.height}px`
    corner.setAttribute('aria-label', `Resize terminal, ${Math.round(size.width)} by ${Math.round(size.height)} pixels`)
    onResize?.()
  }
  function finish(cancel = false) {
    const ended = drag
    if (!ended) return
    drag = undefined
    delete element.dataset.resizing
    if (cancel) apply(ended)
    if (ended.target.hasPointerCapture(ended.pointer)) ended.target.releasePointerCapture(ended.pointer)
  }
  function bind(target: HTMLElement, axis: Axis) {
    target.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 || document.fullscreenElement === element) return
      event.preventDefault()
      finish()
      const rect = element.getBoundingClientRect()
      drag = { width: rect.width, height: rect.height, x: event.clientX, y: event.clientY, pointer: event.pointerId, axis, target }
      element.dataset.resizing = axis
      target.setPointerCapture(event.pointerId)
      corner.focus({ preventScroll: true })
    }, { signal: listeners.signal })
    target.addEventListener('pointermove', (event) => {
      if (!drag || drag.pointer !== event.pointerId || drag.target !== target) return
      event.preventDefault()
      apply({
        width: drag.width + (axis === 'height' ? 0 : event.clientX - drag.x),
        height: drag.height + (axis === 'width' ? 0 : event.clientY - drag.y),
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
    const direction: Record<string, Size> = {
      ArrowLeft: { width: -step, height: 0 }, ArrowRight: { width: step, height: 0 },
      ArrowUp: { width: 0, height: -step }, ArrowDown: { width: 0, height: step },
    }
    if (event.key === 'Home') { event.preventDefault(); apply(initial) }
    else if (direction[event.key]) {
      event.preventDefault()
      apply({ width: size.width + direction[event.key]!.width, height: size.height + direction[event.key]!.height })
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
  apply(initial)

  return {
    reset() { finish(); apply(initial) },
    refresh() { apply(size) },
    destroy() {
      finish()
      listeners.abort()
      observer.disconnect()
      bar.remove()
      right.remove()
      bottom.remove()
      delete element.dataset.resizable
      element.style.width = original.width
      element.style.height = original.height
    },
  }
}
