import './terminal.css'
import type { ITerminalOptions } from '@xterm/xterm'

// @xterm/xterm@6.0.0 src/browser/renderer/dom/DomRenderer.ts uses the font's
// box-drawing glyphs; extra line height separates Jovial's connected prompt.
// https://github.com/xtermjs/xterm.js/blob/6.0.0/src/browser/renderer/dom/DomRenderer.ts
export const terminalOptions = {
  fontFamily: '"Hack Nerd Font Mono", monospace',
  fontSize: 14,
  lineHeight: 1,
  letterSpacing: 0,
  fontWeight: 'normal',
  fontWeightBold: 'bold',
  // @xterm/xterm@6.0.0 Viewport.ts and @xterm/addon-fit@0.11.0 FitAddon.ts
  // both use this width for the custom scrollbar and the space reserved for it.
  // https://github.com/xtermjs/xterm.js/blob/6.0.0/src/browser/Viewport.ts#L138
  overviewRuler: { width: 7, showTopBorder: false, showBottomBorder: false },
} satisfies ITerminalOptions

export async function loadTerminalFonts(): Promise<void> {
  const sample = 'Jovial ╭─╰──➤ (๑˃̵ᴗ˂̵)و'
  const faces = await Promise.all([
    document.fonts.load('400 14px "Hack Nerd Font Mono"', sample),
    document.fonts.load('700 14px "Hack Nerd Font Mono"', sample),
  ])
  if (faces.some((loaded) => loaded.length === 0)) throw new Error('Hack Nerd Font Mono could not be loaded')
}
