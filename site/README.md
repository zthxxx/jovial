# Jovial playground

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
| `src/main.ts` | Terminal display, page state and controls |
| `src/runtime.ts` | Kernel lifecycle and the guest PTY boundary |
| `src/demos.ts` | Commands offered by the project shortcuts |
| `image/` | Guest configuration and sample projects |
| `image/sources.json` | Pinned kernel and plugin sources with SHA-256 checksums |
| `scripts/build-image.ts` | Source downloads and build orchestration in Bun |
| `scripts/image-worker.ts` | Provisioning, image export and verification through Node's JSPI runtime |
| `scripts/verify-image.ts` | Offline guest verification entry point |
| `public/runtime/` | Generated kernel, compressed root filesystem, manifest and notices |
| `.cache/` | Local source cache and complete build logs |

`public/runtime/`, `.cache/` and `dist/` are ignored by Git. CI prepares a new image for each source build.

## Guest environment

The hostname is `unkernel`. The terminal starts as `zthxxx` in `/home/zthxxx/Project`, with the following environment:

- Zsh and Jovial, initialized through the repository's `examples/zinit.zshrc`
- Zinit, Oh My Zsh libraries and plugins, fast-syntax-highlighting, zsh-completions and zsh-autosuggestions
- curl, Git, Node.js 24, Python 3.14, tmux and zoxide
- `node-demo`, a Git repository with a modified file on `feat/greeting`
- `python-demo`, a Git repository with an untracked file and a ready-to-use Python virtual environment

The image excludes zsh-history-enquirer. Bun 1.4 has no Linux riscv64 release binary, so Bun is used on the build host and is unavailable inside the guest. Exact installed versions and source revisions are recorded in `runtime/manifest.json`.

The build copies Jovial from the current checkout and prepares the plugin cache ahead of time. Updating the theme or example configuration therefore updates the next deployed image. Plugin revisions and checksums are maintained in `image/sources.json`; after changing them, rebuild and run `pnpm verify:image`.

## Deployment

`.github/workflows/build.yml` installs the locked workspace, builds the image and site, and verifies the guest. Pushes to `master` publish `site/dist/` to the `gh-pages` branch and explicitly request a GitHub Pages build. The Pages source is `gh-pages` at `/`, with `jovial.zthxxx.me` as its custom domain.

The deployment branch contains the generated site and its `CNAME`. It keeps only the current deployment commit. Browser traffic downloads static assets from Pages; guest execution runs on the visitor's device.

Kernel and SDK attribution and source links are distributed with the runtime assets. The unkernel kernel is GPL-2.0-only and its JavaScript SDK is MIT; see its [pinned source](https://github.com/pithings/unkernel/tree/0e4b2ec) and the generated `runtime/NOTICE.txt`.
