import type { ITheme } from '@xterm/xterm'

export type ColorScheme = 'dark' | 'light'
// site/index.html reads the same preference before the first page paint.
const preferenceKey = 'jovial-color-scheme'

export function getColorScheme(): ColorScheme {
  return document.documentElement.dataset.theme === 'light' ? 'light' : 'dark'
}

export function restoreColorScheme() {
  let scheme = getColorScheme()
  try {
    const saved = localStorage.getItem(preferenceKey)
    if (saved === 'light' || saved === 'dark') scheme = saved
  } catch { /* The selected theme still works when browser storage is unavailable. */ }
  applyColorScheme(scheme)
}

export function applyColorScheme(scheme: ColorScheme, remember = false) {
  const root = document.documentElement
  root.dataset.theme = scheme
  if (remember) {
    try { localStorage.setItem(preferenceKey, scheme) } catch { /* The current page keeps the selected theme. */ }
  }
  const next = scheme === 'dark' ? 'light' : 'dark'
  const button = document.getElementById('theme-toggle')
  button?.setAttribute('aria-label', `Switch to ${next} theme`)
  button?.setAttribute('title', `Switch to ${next} theme and restart all terminals`)
  document.getElementById('guide-colors')?.setAttribute('title', `Switch to ${next} theme to see Jovial adapt; restarts all terminals`)
  const label = document.getElementById('theme-toggle-label')
  if (label) label.textContent = `${next === 'dark' ? 'Dark' : 'Light'} theme`
  const pageColor = getComputedStyle(root).getPropertyValue('--page-bg').trim()
  if (pageColor) document.querySelector('meta[name="theme-color"]')?.setAttribute('content', pageColor)
}

// xterm@6.0.0 answers OSC 11 from its theme. Read the same background token that
// paints the viewport so Jovial detects the displayed color, rather than a preset.
// https://github.com/xtermjs/xterm.js/blob/6.0.0/src/browser/CoreBrowserTerminal.ts#L201
export function terminalTheme(): ITheme {
  const css = getComputedStyle(document.documentElement)
  const value = (name: string) => css.getPropertyValue(name).trim()
  const light = getColorScheme() === 'light'
  return {
    background: value('--terminal-bg'), foreground: value('--terminal-fg'),
    cursor: value('--terminal-fg'), selectionBackground: value('--terminal-selection'),
    ...(light ? {
      black: '#263b30', red: '#b43c3c', green: '#376a35', yellow: '#8d621e',
      blue: '#2f6093', magenta: '#85558a', cyan: '#167474', white: '#d6dfd3',
      brightBlack: '#647568', brightRed: '#c24949', brightGreen: '#437d37', brightYellow: '#9b6c16',
      brightBlue: '#386f9f', brightMagenta: '#96599b', brightCyan: '#127d7c', brightWhite: '#ffffff',
    } : {
      black: '#202020', red: '#ef7676', green: '#a3ce76', yellow: '#e8c47a',
      blue: '#83a9eb', magenta: '#c9a0dc', cyan: '#59d4e8', white: '#dedede',
      brightBlack: '#8c8c8c', brightRed: '#ff9696', brightGreen: '#b9e88c', brightYellow: '#ffdb91',
      brightBlue: '#a6c9ff', brightMagenta: '#e6bcf7', brightCyan: '#86e8f4', brightWhite: '#ffffff',
    }),
  }
}
