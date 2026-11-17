# Terminal startup performance

The default preview uses the lean shell: Jovial, Zinit, Oh My Zsh helpers, Git aliases and Zsh completions. Its completion dump is generated during the image build. Syntax highlighting and automatic history suggestions are disabled.

The browser keeps the loading screen visible until the shell's first prompt has been drawn, its readiness signal has been parsed, and xterm has rendered the viewport. Terminal fonts are loaded before measuring character cells.

## Local playground

```sh
pnpm build:image
pnpm dev
```

Open <http://127.0.0.1:5173/playground/terminal/>. Each measurement starts a new VM. The page records browser download, compilation, kernel, PTY and prompt milestones separately from guest Zsh stages. It supports full, lean and minimal configurations, raw `zprof` output, run history and JSON export.

The debug HTML is a separate Vite development entry. It is absent from `site/dist/`, and the production entry does not import its modules.

For a repeatable offline guest comparison:

```sh
pnpm profile:shell 4
pnpm profile:shell 2 lean
```

The first command runs four rounds of the five configurations below in alternating order. The second starts a new VM and measures the lean configuration twice. Complete results and output are saved under `site/.cache/logs/`.

## Measurements

Measured on 2026-11-18 on an Apple M5 Pro, using Node.js 25.9.0 and unkernel `0.1.0-261117-0e4b2ec`. The offline Alpine riscv64 guest had 768 MiB of memory and one CPU.

These timings run from the PTY spawn request to the first prompt's readiness marker. They exclude downloading and booting the VM. Each configuration has its own completion cache seeded from the image; medians use rounds 2–4. Browser end-to-end timings are measured separately by the local playground.

| Configuration | Completion initialization | Highlighting and suggestions | Median to first prompt |
| --- | --- | --- | ---: |
| Full example | Checks and rebuilds | Enabled | 6,916 ms |
| Cached full | Uses prebuilt dump | Enabled | 1,716 ms |
| Uncached lean | Checks the dump | Disabled | 866 ms |
| Lean, default | Uses prebuilt dump | Disabled | 790 ms |
| Minimal | Zinit and Jovial only | Disabled | 435 ms |

A separate Chrome run against the local Vite server measured 7.76 s from starting a full VM to its visible prompt, 1.27 s for lean, and 0.88 s for minimal. These are single end-to-end browser samples with cached static assets, including VM loading and boot. A fresh offline Node VM using the final image reached the default lean prompt in 753 ms and 758 ms on consecutive shell launches; actual Tab path completion was also verified.

The full configuration initializes completion before Zinit extends `fpath`, then initializes it again through the autosuggestions `atload` hook. The different completion paths invalidate the same dump, causing repeated scanning, `compdef` registration and `compdump` writes. A recorded full run spent about 5.1 seconds inside the two `compinit` calls; `compdump` accounted for about 2.7 seconds of self time.

In the lean configuration, median guest stages included approximately 80 ms for loading the completion dump, 196 ms for Zinit, 99 ms for the theme, 245 ms for Oh My Zsh libraries and plugins, and 99 ms for the first `precmd`. `zprof` report generation is measured after the first prompt and reported separately as `zprofMs`.

The background console uses Alpine's original shell. The visible PTY is the sole automatic Jovial shell started by the preview.

## Rendering

The terminal uses self-hosted Hack Nerd Font Mono 3.5.1, with `lineHeight: 1` and `letterSpacing: 0`. Regular and bold faces load before `term.open()`, so xterm measures the intended font. This keeps the `╭`, `╰`, `─` and `➤` glyphs in the same font and removes the extra vertical spacing between prompt lines.
