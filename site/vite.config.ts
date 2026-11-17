import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    target: 'esnext',
    rolldownOptions: {
      output: {
        // unkernel's default kernel URL and the image builder share this artifact.
        assetFileNames: (asset) => asset.names.includes('unkernel-alpine.wasm')
          ? 'runtime/unkernel.wasm'
          : 'assets/[name]-[hash][extname]',
      },
    },
  },
})
