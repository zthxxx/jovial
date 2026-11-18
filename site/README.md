# Jovial website and playground

[Open the playground](https://jovial.zthxxx.me) to use Jovial in a real Zsh shell. The static site runs an Alpine Linux riscv64 guest through [unkernel](https://github.com/pithings/unkernel), entirely in the visitor's browser.

Tools, Zinit, plugins and sample projects are installed when the image is built. The guest starts without a network device. Each page load or restart creates a fresh environment in memory.

## Development

Use Node.js 24 or newer with WebAssembly JSPI, Bun 1.4.2 and pnpm 9.6.0. Package versions are maintained in the root `pnpm-workspace.yaml` catalog.

```sh
pnpm install --frozen-lockfile
pnpm build:image
pnpm dev
```

Open the local URL printed by Vite. `pnpm check` checks TypeScript; `pnpm verify:image` boots the generated image without networking and checks its installed environment. `pnpm build` builds a new image and the production site in `site/dist/`.

If the default `node` executable is older than 24, set `JOVIAL_NODE` to a compatible executable for image commands:

```sh
JOVIAL_NODE=/path/to/node pnpm build:image
```

The browser must support WebAssembly JSPI. The page checks support before downloading the environment and explains how to proceed when it is unavailable.

## Project structure

| Path | Responsibility |
| --- | --- |
| `src/main.ts` | Terminal tabs, active commands, appearance switching and environment lifecycle |
| `src/theme.ts` | Remembered appearance preference and the xterm palette |
| `src/landing.css` | Landing page layout and light/dark page palettes |
| `src/landing-assets.ts` | README screenshots and responsive demonstration video |
| `src/github.ts` | Public GitHub Star count |
| `src/terminal-tab.ts` | Per-tab Zsh, output, first-prompt readiness and disposal |
| `src/resize.ts` | Pointer, touch and keyboard terminal resizing |
| `src/runtime.ts` | Shared kernel lifecycle and independent guest PTYs |
| `src/shell-ready.ts` | First-prompt handshake with the guest shell |
| `src/terminal.ts` | Terminal font loading and character metrics |
| `src/demos.ts` | Initial directories and each tab's preset commands |
| `image/` | Guest configuration and sample projects |
| `image/sources.json` | Pinned kernel and plugin sources with SHA-256 checksums |
| `fonts/sources.json` | Pinned Hack Nerd Font Mono release and checksum |
| `scripts/prepare-fonts.ts` | Preparation of self-hosted font files in `public/fonts/` |
| `scripts/build-image.ts` | Source downloads and build orchestration in Bun |
| `scripts/image-worker.ts` | Provisioning, image export and verification through Node's JSPI runtime |
| `scripts/verify-image.ts` | Offline guest verification entry point |
| `public/runtime/` | Generated kernel, compressed root filesystem, manifest and notices |
| `.cache/` | Local source cache and complete build logs |

`public/runtime/`, `public/fonts/`, `.cache/` and `dist/` are ignored by Git. CI prepares a new image for each source build.

The loading screen stays visible until Zsh has drawn its first prompt and xterm has processed the shell's readiness signal. Hack Nerd Font Mono is loaded before measuring the terminal, with a line height of 1 to keep the prompt's box-drawing lines connected. Font preparation runs automatically for development and website builds.

## Guest environment

The hostname is `unkernel` and every terminal runs as `zthxxx`. Each page load restores four tabs: `~/Project`, `~/Project/python-demo`, `~/Project/node-demo` and `~/Project/git-demo`. New tabs start in `~/Project`; tab labels show their sequence number and initial directory. Tab selection, extra tabs and window dimensions remain local to the current page.

The appearance button switches the page and terminal together, then restarts the entire demo with four fresh tabs. Jovial reads the terminal background through OSC 11 and selects its own light or dark prompt palette. The selected appearance is remembered in the browser.

The tabs share one Linux filesystem and have independent Zsh sessions, working directories, environment variables and output. The selected tab is displayed alone. Its preset buttons send commands to that session. Closing a tab closes its PTY; Restart all creates a fresh environment.

The terminal can be resized from its edges or corner, with a minimum of ten rows and approximately one third of the initial desktop width. The resize corner also supports arrow keys and Home to restore its initial size.

The environment includes:

- Zsh and Jovial, initialized through the repository's `examples/zinit.zshrc`
- Zinit, Oh My Zsh libraries and plugins, and zsh-completions
- curl, Git, Node.js 24, Python 3.14, tmux and zoxide
- `node-demo`, a Git repository with a modified file on `feat/greeting`
- `python-demo`, a Git repository with an untracked file and a ready-to-use Python virtual environment
- `git-demo`, a Git repository on `feat/preview` with a modified greeting file

The image excludes zsh-history-enquirer. Bun 1.4 has no Linux riscv64 release binary, so Bun is used on the build host and is unavailable inside the guest. Exact installed versions and source revisions are recorded in `runtime/manifest.json`.

The build copies Jovial from the current checkout and prepares the plugin cache ahead of time. Updating the theme or example configuration therefore updates the next deployed image. Plugin revisions and checksums are maintained in `image/sources.json`; after changing them, rebuild and run `pnpm verify:image`.

## Local terminal profiling

Run `pnpm dev` and open <http://127.0.0.1:5173/playground/terminal/> to compare full, lean and minimal shell configurations. The page shows browser and guest startup timings, raw Zsh function profiles, run history and JSON export. It is excluded from the production build.

The default preview uses the lean configuration with prebuilt completion caches. The full configuration, including syntax highlighting and history suggestions, remains available in the local profiler. See [Terminal startup performance](./PERFORMANCE.md) for measurements and command-line reproduction.

## Deployment

`.github/workflows/build.yml` installs the locked workspace, builds the image and site, and verifies the guest. Pushes to `master` publish `site/dist/` to the `gh-pages` branch and explicitly request a GitHub Pages build. The Pages source is `gh-pages` at `/`, with `jovial.zthxxx.me` as its custom domain.

The deployment branch contains the generated site and its `CNAME`. It keeps only the current deployment commit. Browser traffic downloads static assets from Pages; guest execution runs on the visitor's device.

Kernel and SDK attribution and source links are distributed with the runtime assets. The unkernel kernel is GPL-2.0-only and its JavaScript SDK is MIT; see its [pinned source](https://github.com/pithings/unkernel/tree/0e4b2ec) and the generated `runtime/NOTICE.txt`.
