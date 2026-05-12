#!/usr/bin/env zsh

# usage: zsh dev/dev-link.zsh
#
# Symlink the local jovial.zsh-theme and jovial.plugin.zsh into the
# active plugin manager's directory, so local edits take effect on the
# next shell reload.
#
# Detects oh-my-zsh and zinit, and links into whichever is present
# (both, if both are installed).

set -e

repo_dir=${0:A:h:h}
theme_src="${repo_dir}/jovial.zsh-theme"
plugin_src="${repo_dir}/jovial.plugin.zsh"

linked=0


# oh-my-zsh: ~/.oh-my-zsh/custom/{themes,plugins/jovial}/
omz_dir="${ZSH:-${HOME}/.oh-my-zsh}"
if [[ -d ${omz_dir} ]]; then
    mkdir -p "${omz_dir}/custom/themes" "${omz_dir}/custom/plugins/jovial"
    ln -fs "${theme_src}"  "${omz_dir}/custom/themes/jovial.zsh-theme"
    ln -fs "${plugin_src}" "${omz_dir}/custom/plugins/jovial/jovial.plugin.zsh"
    print "linked into oh-my-zsh: ${omz_dir}/custom/"
    linked=1
fi


# zinit: <plugins-dir>/zthxxx---jovial/
# resolution order: ZINIT[PLUGINS_DIR] (set by a sourced zinit) → XDG default → legacy ~/.zinit
zinit_plugins_dir=
if [[ -n ${ZINIT[PLUGINS_DIR]} && -d ${ZINIT[PLUGINS_DIR]} ]]; then
    zinit_plugins_dir=${ZINIT[PLUGINS_DIR]}
elif [[ -d ${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/plugins ]]; then
    zinit_plugins_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/plugins"
elif [[ -d ${HOME}/.zinit/plugins ]]; then
    zinit_plugins_dir="${HOME}/.zinit/plugins"
fi

if [[ -n ${zinit_plugins_dir} ]]; then
    zinit_jovial="${zinit_plugins_dir}/zthxxx---jovial"
    mkdir -p "${zinit_jovial}"
    ln -fs "${theme_src}"  "${zinit_jovial}/jovial.zsh-theme"
    ln -fs "${plugin_src}" "${zinit_jovial}/jovial.plugin.zsh"
    # drop stale compiled cache, otherwise zsh keeps loading the old bytecode
    # instead of the freshly-symlinked source
    print "linked into zinit: ${zinit_jovial}/"
    linked=1
fi


if (( ! linked )); then
    print -u2 "no oh-my-zsh or zinit installation found; nothing linked"
    exit 1
fi
