#!/usr/bin/env zsh

# Usage:
#  zsh -il dev/benchmark.zsh
#  (absolute path is okay)

local self_path=`realpath $0`
local theme_dir="$(dirname $(dirname ${self_path}))"
local theme_file="${theme_dir}/jovial.zsh-theme"

source "${theme_file}"
@jov.prompt-prepare

theme.render() {
    @jov.prompt-prepare
    print -P "${PROMPT}"
}

time (
  for i in {1..10}; do
    theme.render
  done
)
