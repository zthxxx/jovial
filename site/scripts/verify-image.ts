#!/usr/bin/env bun
import { $ } from 'bun';
import { openSync, closeSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const site = resolve(import.meta.dir, '..');
const node = process.env.JOVIAL_NODE ?? Bun.which('node');
if (!node) throw new Error('Node.js >=24 is required for guest verification');
const supported = await $`${node} -e ${"process.exit(typeof WebAssembly.Suspending === 'function' ? 0 : 1)"}`.quiet().nothrow();
if (supported.exitCode !== 0) throw new Error('Node.js >=24 with JSPI is required; set JOVIAL_NODE to its executable');
await mkdir(join(site, '.cache/logs'), { recursive: true });
const log = Bun.file(join(site, '.cache/logs/image-verify.log'));
const fd = openSync(log.name!, 'w');
const child = Bun.spawn([node, join(site, 'scripts/image-worker.ts'), 'verify'], { cwd: site, stdout: fd, stderr: fd });
const exitCode = await child.exited;
closeSync(fd);
if (exitCode !== 0) throw new Error(`Guest verification failed (${exitCode}); see ${log.name}`);
console.log('Verified hostname, user, working directory, tools, demos, and jovial without network access.');
