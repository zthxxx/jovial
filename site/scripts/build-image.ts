#!/usr/bin/env bun
import { $ } from 'bun';
import { openSync, closeSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createShellConfigs, instrumentShellConfig } from './shell-config.ts';

const site = resolve(import.meta.dir, '..');
const root = resolve(site, '..');
const cache = join(site, '.cache');
const input = join(cache, 'input');
const output = join(site, 'public/runtime');
const lock = JSON.parse(await readFile(join(site, 'image/sources.json'), 'utf8'));
const sha256 = (bytes: Uint8Array) => createHash('sha256').update(bytes).digest('hex');

await mkdir(join(cache, 'sources'), { recursive: true });
await mkdir(join(cache, 'logs'), { recursive: true });
await mkdir(output, { recursive: true });
await rm(input, { recursive: true, force: true });
await mkdir(join(input, 'sources'), { recursive: true });

const wasm = fileURLToPath(import.meta.resolve('unkernel/alpine.wasm'));
const bytes = await readFile(wasm);
if (sha256(bytes) !== lock.unkernel.wasmSha256) throw new Error('The unkernel package does not match image/sources.json');
await writeFile(join(output, 'unkernel.wasm'), bytes);
const packageRoot = resolve(dirname(wasm), '..');
for (const license of ['LICENSE', 'LICENSE-MIT']) await cp(join(packageRoot, license), join(output, `unkernel-${license}`));
const fontPackage = dirname(fileURLToPath(import.meta.resolve('@fontsource-variable/jetbrains-mono/package.json')));
await cp(join(fontPackage, 'LICENSE'), join(output, 'font-LICENSE'));

await writeFile(join(output, 'NOTICE.txt'), `Jovial browser preview\n\nLinux kernel and SDK: unkernel ${lock.unkernel.version}\nSource and build scripts: https://github.com/pithings/unkernel/tree/v${lock.unkernel.version}\nKernel license: ./unkernel-LICENSE (GPL-2.0)\nSDK license: ./unkernel-LICENSE-MIT (MIT)\n\nGuest packages: Alpine Linux v3.24 riscv64, https://alpinelinux.org\nInstalled package versions: /etc/jovial-packages.txt inside the guest.\nPackage metadata and licenses: /lib/apk/db/installed inside the guest.\nPackage sources: https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.24-stable\n\nZinit and plugin source revisions: ./manifest.json\nPlugin licenses are retained in /home/zthxxx/.local/share/zinit inside the guest.\nJovial source: https://github.com/zthxxx/jovial\n\nJetBrains Mono variable font (Fontsource package): ./font-LICENSE\nFont source: https://github.com/JetBrains/JetBrainsMono\nHack Nerd Font Mono source and license: ../fonts/NOTICE.txt\n`);

for (const source of lock.sources) {
  const name = source.repository.replace('/', '---');
  const archive = join(cache, 'sources', `${name}.tgz`);
  let compressed = await readFile(archive).catch(() => undefined);
  if (!compressed || sha256(compressed) !== source.sha256) {
    console.log(`Downloading ${source.repository}@${source.revision}`);
    const response = await fetch(`https://codeload.github.com/${source.repository}/tar.gz/${source.revision}`);
    if (!response.ok) throw new Error(`${response.status}: ${source.repository}`);
    compressed = Buffer.from(await response.arrayBuffer());
    if (sha256(compressed) !== source.sha256) throw new Error(`Source checksum mismatch: ${source.repository}`);
    await writeFile(archive, compressed);
  }
  const target = join(input, 'sources', source.repository.endsWith('/zinit') ? 'zinit' : name);
  await mkdir(target, { recursive: true });
  await $`tar -xzf ${archive} --strip-components=1 -C ${target}`.quiet();
}

await mkdir(join(input, 'theme'), { recursive: true });
for (const name of ['jovial.plugin.zsh', 'jovial.zsh-theme', 'LICENSE']) await cp(join(root, name), join(input, 'theme', name));
const example = await readFile(join(root, 'examples/zinit.zshrc'), 'utf8');
// The image's completion cache is prepared after every plugin is registered.
const shells = createShellConfigs(example);
await writeFile(join(input, 'zshrc'), shells.lean);
for (const [mode, config] of Object.entries(shells)) {
  await writeFile(join(input, `zshrc-${mode}`), instrumentShellConfig(config));
}
await writeFile(join(input, 'revision'), (await $`git -C ${root} rev-parse HEAD`.text()).trim());

// unkernel's JSPI runtime requires Node >=24; Bun orchestrates downloads and the child process.
const node = process.env.JOVIAL_NODE ?? Bun.which('node');
if (!node) throw new Error('Node.js >=24 is required for the image build');
const supported = await $`${node} -e ${"process.exit(typeof WebAssembly.Suspending === 'function' ? 0 : 1)"}`.quiet().nothrow();
if (supported.exitCode !== 0) throw new Error('Node.js >=24 with JSPI is required; set JOVIAL_NODE to its executable');
console.log('Provisioning the Alpine guest; full output: site/.cache/logs/image-build.log');
const log = Bun.file(join(cache, 'logs/image-build.log'));
const fd = openSync(log.name!, 'w');
const child = Bun.spawn([node, join(site, 'scripts/image-worker.ts'), 'build'], { cwd: site, stdout: fd, stderr: fd });
const exitCode = await child.exited;
closeSync(fd);
if (exitCode !== 0) throw new Error(`Image build failed (${exitCode}); see ${log.name}`);
console.log(`Built ${join(output, 'jovial.cpio.gz')}`);
