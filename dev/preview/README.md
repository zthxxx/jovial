# Preview tooling

Helpers for previewing the jovial prompt while developing the theme.

## Palette preview (browser)

[`palette-preview.zsh`](./palette-preview.zsh) renders both color palettes —
`JOVIAL_PALETTE_DARK` and `JOVIAL_PALETTE_LIGHT` — into a single HTML page, so
you can compare them in a browser without flipping your terminal between its
light and dark profiles.

```sh
# generate dev/preview/palette-preview.html
zsh dev/preview/palette-preview.zsh

# generate then open it in the default browser
zsh dev/preview/palette-preview.zsh --open

# write to a custom path
zsh dev/preview/palette-preview.zsh /tmp/jovial-palette.html
```

The page shows, for each variant:

- a few representative mock prompt lines that exercise every palette color, on
  both a plain and a tinted background (to sanity-check contrast on each);
- a swatch grid listing every palette key with its resolved hex value (a `B`
  tag marks bold entries).

How it works: the script sources `jovial.zsh-theme`, reads the two palette
arrays directly, and converts each `%F{N}` 256-color index to its xterm hex
value (computed from the standard 6×6×6 cube + grayscale ramp, not hard-coded).
Because the values are read live from the theme, the preview never drifts out
of sync with the source. The generated `.html` is a build artifact and is
git-ignored.

This previews **colors only** — it composes a mock prompt from the palette keys
rather than driving the real responsive/async renderer. For faithful
full-prompt captures, use the scripts below.

## Full-prompt screenshots (iTerm2)

The `*.zsh` scripts here drive the real renderer (`print -P "${PROMPT}"`) after
setting up throwaway demo repositories. They are run inside iTerm2 with
[`iterm2-jovial-preview-prefile.json`](./iterm2-jovial-preview-prefile.json)
imported as the profile, to produce the consistent screenshots used in the
top-level `docs/`.

| script                | scenario                                             |
| --------------------- | ---------------------------------------------------- |
| `full-prompts.zsh`    | a complete prompt with venv + pinned execution info  |
| `develop-detect.zsh`  | per-language dev-env detection (node / go / python)  |
| `git.zsh`             | git status / branch / in-progress action states      |

> Each script notes the terminal size it expects in a `# terminal size: WxH`
> comment, and creates demo repos under `~/Project/*-demo` (remove them when
> you are done).
