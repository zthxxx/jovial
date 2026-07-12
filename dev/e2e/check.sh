#!/usr/bin/env bash
#
# Run the detection test suite in full isolation from the host environment:
# docker compose builds a slim zsh+python image, mounts the repo read-only,
# and runs with no network. See compose.yaml for the isolation properties.
#
# Usage:
#   dev/e2e/check.sh                       # whole suite
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
exec docker compose -f "${here}/compose.yaml" run --build --rm check
