#!/usr/bin/env bun
import { $ } from 'bun'
import { createHash } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'

const site = resolve(import.meta.dir, '..')
const source = JSON.parse(await readFile(join(site, 'fonts/sources.json'), 'utf8')) as {
  version: string
  url: string
  sha256: string
  files: string[]
}
const cache = join(site, '.cache/fonts')
const output = join(site, 'public/fonts')
const archive = join(cache, `Hack-v${source.version}.tar.xz`)
const sha256 = (bytes: Uint8Array) => createHash('sha256').update(bytes).digest('hex')

await mkdir(cache, { recursive: true })
await mkdir(output, { recursive: true })
let bytes = await readFile(archive).catch(() => undefined)
if (!bytes || sha256(bytes) !== source.sha256) {
  const response = await fetch(source.url)
  if (!response.ok) throw new Error(`Could not download Hack Nerd Font Mono: HTTP ${response.status}`)
  bytes = Buffer.from(await response.arrayBuffer())
  if (sha256(bytes) !== source.sha256) throw new Error('Hack Nerd Font Mono archive checksum mismatch')
  await writeFile(archive, bytes)
}
await $`tar -xJf ${archive} -C ${output} ${source.files}`.quiet()
await writeFile(join(output, 'NOTICE.txt'), `Hack Nerd Font Mono ${source.version}\nSource: ${source.url}\nArchive SHA-256: ${source.sha256}\nLicense: ./LICENSE.md\n`)
console.log(`Prepared self-hosted Hack Nerd Font Mono ${source.version}`)
