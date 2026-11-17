#!/usr/bin/env bun
import { $ } from 'bun'
import { mkdir, readFile, copyFile, writeFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import { createShellConfigs, instrumentShellConfig, bindProfileCompletionCache } from './shell-config.ts'

const site = resolve(import.meta.dir, '..')
const input = join(site, '.cache/profile-input')
const logs = join(site, '.cache/logs')
await mkdir(input, { recursive: true })
await mkdir(logs, { recursive: true })
const configs = createShellConfigs(await readFile(join(site, '../examples/zinit.zshrc'), 'utf8'))
const cases = {
  ...configs,
  'cached-full': configs.full
    .replace('autoload -Uz compinit && compinit', 'autoload -Uz compinit && compinit -C')
    .replace('ZINIT[COMPINIT_OPTS]=', 'ZINIT[COMPINIT_OPTS]=-C'),
  'uncached-lean': configs.lean.replace('autoload -Uz compinit && compinit -C', 'autoload -Uz compinit && compinit'),
}
for (const [mode, config] of Object.entries(cases)) {
  await writeFile(join(input, `${mode}.zsh`), instrumentShellConfig(config))
  await writeFile(join(input, `${mode}-plain.zsh`), bindProfileCompletionCache(config))
}
for (const file of ['profile.zsh', 'profile.zshenv', 'profile.zshrc', 'profile-shell', 'terminal-ready.zsh']) {
  await copyFile(join(site, 'image', file), join(input, file))
}
const node = process.env.JOVIAL_NODE ?? Bun.which('node')
if (!node) throw new Error('Node.js with WebAssembly JSPI is required')
await $`${node} ${join(site, 'scripts/profile-worker.ts')} ${process.argv.slice(2)}`.cwd(site)
