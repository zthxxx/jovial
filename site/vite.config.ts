import { existsSync, readFileSync, statSync } from 'node:fs'
import { resolve } from 'node:path'
import { defineConfig, type Plugin } from 'vite'

function prepareBootAssets(): Plugin {
  let preloads: string[] = []
  return {
    name: 'jovial:boot-assets',
    config(config, { command }) {
      const publicDir = resolve(config.root ?? '.', typeof config.publicDir === 'string' ? config.publicDir : 'public')
      const manifestPath = resolve(publicDir, 'runtime/manifest.json')
      const production = command === 'build'
      const manifest = production && existsSync(manifestPath)
        ? JSON.parse(readFileSync(manifestPath, 'utf8')) as { unkernel: { sha256: string }; image: { sha256: string } }
        : undefined
      const asset = (file: string, hash: string | undefined) => {
        const path = resolve(publicDir, 'runtime', file)
        const bytes = production && existsSync(path) ? statSync(path).size : 0
        const url = `${config.base ?? '/'}runtime/${file}${hash ? `?v=${hash}` : ''}`
        return { url, bytes }
      }
      const kernel = asset('unkernel.wasm', manifest?.unkernel.sha256)
      const initrd = asset('jovial.cpio.gz', manifest?.image.sha256)
      preloads = [kernel, initrd].filter(({ bytes }) => bytes > 0).map(({ url }) => url)
      return { define: { __JOVIAL_BOOT_ASSETS__: JSON.stringify({ kernel, initrd }) } }
    },
    transformIndexHtml: {
      order: 'post',
      handler() {
        if (!preloads.length) return
        // Like terminal-glance/vite.config.ts, match the runtime fetch's preload key.
        // Skip the large downloads when WebAssembly JSPI is unavailable.
        return [{
          tag: 'script',
          children: `if (typeof WebAssembly === 'object' && typeof WebAssembly.Suspending === 'function' && typeof WebAssembly.promising === 'function') {
  for (const href of ${JSON.stringify(preloads)}) {
    const preload = document.createElement('link')
    preload.rel = 'preload'
    preload.as = 'fetch'
    preload.crossOrigin = 'anonymous'
    preload.fetchPriority = 'low'
    preload.href = href
    document.head.append(preload)
  }
}`,
          injectTo: 'head',
        }]
      },
    },
  }
}

export default defineConfig({
  plugins: [prepareBootAssets()],
  build: {
    target: 'esnext',
    cssCodeSplit: false,
    rolldownOptions: {
      output: {
        // Rolldown 1.2.19 codeSplitting groups stable dependencies for browser caching.
        // Vite adds modulepreload tags for the entry's static chunk imports.
        codeSplitting: {
          groups: [{ name: 'terminal', test: /[\\/]node_modules[\\/](?:@xterm|unkernel)[\\/]/ }],
        },
        // unkernel's default kernel URL and the image builder share this artifact.
        assetFileNames: (asset) => asset.names.includes('unkernel-alpine.wasm')
          ? 'runtime/unkernel.wasm'
          : 'assets/[name]-[hash][extname]',
      },
    },
  },
})
