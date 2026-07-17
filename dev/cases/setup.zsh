#!/usr/bin/env zsh
#
# Prepare the demo workspace at container runtime from the mounted case files.
# Lives in the mounted cases/ dir (not baked into the image), so editing the
# example projects or this script takes effect on the next render -- no rebuild.
#
# Runtime-only steps (git repos, python venv) live here rather than in the
# example files because they can't be committed portably.
set -e

cases_dir="${0:A:h}"
workspace="${HOME}/Project"

# copy the example projects into a writable workspace
rm -rf "${workspace}"
mkdir -p "${workspace}"
cp -R "${cases_dir}/projects/." "${workspace}/"

# move out of the mounted repo before running git: when the host checkout is a
# git worktree, its `.git` file points at a path that doesn't exist inside the
# container, so any git command discovered from there would fail. also drop any
# inherited git env that could redirect discovery.
unset GIT_DIR GIT_WORK_TREE
cd "${workspace}"

# git identity comes from the mounted cases/gitconfig via GIT_CONFIG_GLOBAL
# (set in the Dockerfile), so it isn't generated here.

# node-demo + golang-demo: clean git repos (exercise the git "clean" state)
local proj
for proj in node-demo golang-demo; do
    git -C "${workspace}/${proj}" init -q
    git -C "${workspace}/${proj}" add -A
    git -C "${workspace}/${proj}" commit -qm init
done

# python-demo: a venv to activate (exercises the venv segment)
python3 -m venv "${workspace}/python-demo/venv"
