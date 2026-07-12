#!/usr/bin/env bash
#
# Build the preview container and render jovial's light & dark palettes to PNG/GIF
# under dev/e2e/output/. Requires only Docker on the host.
#
# Usage:
#   dev/e2e/render.sh            # render light, dark, and the detect check
#   dev/e2e/render.sh light      # render a single tape
#
# The `detect` tape doubles as a true end-to-end assertion (real OSC 11
# round-trip through xterm.js + stderr canary + typeahead replay): its
# `Wait+Screen` calls make vhs exit non-zero when detection misbehaves.
#
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "${here}/../.." && pwd)"
image='jovial-preview'

modes=("$@")
if [[ ${#modes[@]} -eq 0 ]]; then modes=(light dark detect); fi

echo "==> building preview image (${image})"
docker build -t "${image}" -f "${here}/Dockerfile" "${repo}"

mkdir -p "${here}/output"

for mode in light dark detect; do
    if [[ " ${modes[*]} " != *" ${mode} "* ]]; then continue; fi
    echo "==> rendering ${mode} -> dev/e2e/output/${mode}.{gif,png}"
    # render the animated GIF (vhs `Screenshot` is unreliable, so we don't use it)
    docker run --rm -v "${repo}:/work" -w /work --entrypoint vhs "${image}" \
        "/work/dev/e2e/${mode}.tape"
    # grab the final frame as a still PNG for quick visual review
    docker run --rm -v "${repo}:/work" -w /work --entrypoint bash "${image}" -c \
        "ffmpeg -y -sseof -0.1 -i '/work/dev/e2e/output/${mode}.gif' -update 1 -frames:v 1 '/work/dev/e2e/output/${mode}.png' 2>/dev/null"
done

echo "==> done. see dev/e2e/output/"
