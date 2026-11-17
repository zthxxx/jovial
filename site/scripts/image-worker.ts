#!/usr/bin/env bun
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
// unkernel@0.1.0-261117-0e4b2ec: createKernel/exec and host mounts follow the pinned SDK contract.
// https://github.com/pithings/unkernel/blob/v0.1.0-261117-0e4b2ec/js/core/instance.ts
import { createKernel, directBackend, nodeFs, type KernelInstance } from 'unkernel/node';

const site = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const runtime = join(site, 'public/runtime');
const imageFile = join(runtime, 'jovial.cpio.gz');
const mode = process.argv[2];
const lock = JSON.parse(await readFile(join(site, 'image/sources.json'), 'utf8'));

async function command(vm: KernelInstance, script: string, timeout = 900_000): Promise<string> {
  console.log(`> ${script}`);
  const result = await vm.exec('/bin/sh', ['-eu', '-c', script], { signal: AbortSignal.timeout(timeout) });
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
  if (result.exitCode !== 0) throw new Error(`Guest command exited ${result.exitCode}`);
  return result.stdout;
}

if (mode !== 'build' && mode !== 'verify') throw new Error('Expected build or verify');
const building = mode === 'build';
const vm = await createKernel({
  kernel: join(runtime, 'unkernel.wasm'),
  ...(building ? {
    net: directBackend(),
    mounts: {
      '/mnt/input': { fs: nodeFs(join(site, '.cache/input')), readOnly: true },
      '/mnt/image': { fs: nodeFs(join(site, 'image')), readOnly: true },
    },
  } : { initrd: imageFile }),
  memoryMiB: 1024,
  onOutput: bytes => process.stdout.write(bytes),
});
try {
  if (building) {
    await command(vm, '/bin/sh /mnt/image/provision.sh');
    const tools: Record<string, unknown> = {};
    for (const [name, script] of Object.entries({
      node: 'node --version', python: 'python3 --version', zsh: 'zsh --version',
      git: 'git --version', curl: 'curl --version', tmux: 'tmux -V', zoxide: 'zoxide --version',
    })) tools[name] = (await command(vm, script)).trim().split('\n')[0];
    tools.bun = { available: false, reason: 'Bun 1.4 does not publish a Linux riscv64 binary.' };
    console.log('Exporting the guest root file system');
    // Keep pseudo file-system mount points, but never archive their live contents or the host mounts.
    const exported = await vm.exec('/bin/sh', ['-eu', '-c',
      "cd /; find . -xdev ! -path './mnt/input*' ! -path './mnt/image*' ! -path './tmp/*' ! -path './proc/*' ! -path './sys/*' ! -path './dev/*' ! -path './run/*' | cpio -o -H newc"],
      { encoding: 'buffer', maxBuffer: 512 * 1024 * 1024, signal: AbortSignal.timeout(900_000) });
    process.stderr.write(exported.stderr);
    if (exported.exitCode !== 0) throw new Error(`Export exited ${exported.exitCode}`);
    const compressed = gzipSync(exported.stdout, { level: 9 });
    await writeFile(imageFile, compressed);
    const sha256 = createHash('sha256').update(compressed).digest('hex');
    await writeFile(join(runtime, 'manifest.json'), JSON.stringify({
      schemaVersion: 1,
      sourceRevision: (await readFile(join(site, '.cache/input/revision'), 'utf8')).trim(),
      builtAt: new Date().toISOString(),
      unkernel: { version: lock.unkernel.version, sha256: lock.unkernel.wasmSha256 },
      image: { file: 'jovial.cpio.gz', sha256, bytes: compressed.length },
      tools,
      plugins: [...lock.sources, { repository: 'zthxxx/jovial', revision: (await readFile(join(site, '.cache/input/revision'), 'utf8')).trim() }],
      defaults: { hostname: 'unkernel', user: 'zthxxx', cwd: '/home/zthxxx/Project', shell: '/usr/local/bin/jovial-shell' },
      projects: [{ name: 'node-demo', branch: 'feat/greeting' }, { name: 'python-demo', branch: 'main', venv: 'venv' }],
    }, null, 2) + '\n');
  } else {
    await command(vm, 'test "$(hostname)" = unkernel; test "$(uname -m)" = riscv64; test ! -e /sys/class/net/eth0; node --version | grep "^v24\\."; python3 --version | grep "^Python 3\\.14\\."; for tool in curl zsh git tmux zoxide; do command -v "$tool"; done');
    await command(vm, "su -l zthxxx -c 'set -e; test \"$(id -un)\" = zthxxx; test \"$PWD\" = /home/zthxxx/Project; test -f node-demo/package.json; test -x python-demo/venv/bin/python; node node-demo/index.js; python-demo/venv/bin/python python-demo/hello.py'");
    const pluginCheck = 'set -e; test -n "$JOVIAL_VERSION"; (( ${+functions[zinit]} )); (( ${+functions[_zsh_autosuggest_start]} )); (( ${+functions[_zsh_highlight]} )); (( ${+functions[gfco]} )); (( ${+aliases[g]} )); [[ ${_comps[ab]} = _ab ]]; print -r -- JOVIAL_OFFLINE_READY';
    const shellQuote = (value: string) => "'" + value.replaceAll("'", "'\\''") + "'";
    const checked = await vm.exec('/bin/su', ['-l', 'zthxxx', '-c', `zsh -ic ${shellQuote(pluginCheck)}`], { signal: AbortSignal.timeout(120_000) });
    process.stdout.write(checked.stdout);
    process.stderr.write(checked.stderr);
    if (checked.exitCode !== 0 || !checked.stdout.includes('JOVIAL_OFFLINE_READY')) throw new Error('Cached plugins failed to load offline');
    const theme = await command(vm, 'cat /home/zthxxx/.zshrc');
    if (theme.includes('zthxxx/zsh-history-enquirer')) throw new Error('history-enquirer is present');
    console.log('JOVIAL_IMAGE_VERIFIED_OFFLINE');
  }
} finally {
  await vm.stop();
}
