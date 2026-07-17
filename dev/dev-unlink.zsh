#!/usr/bin/env zsh

# usage: zsh dev/dev-unlink.zsh
#
# Reverse of dev/dev-link.zsh: remove the dev symlinks of jovial.zsh-theme
# and jovial.plugin.zsh, and restore the originally installed files.
#
# Detects oh-my-zsh and zinit, and unlinks whichever is present:
#   - zinit installs are git clones, so the release files are restored
#     via `git checkout`
#   - oh-my-zsh installs were plain downloaded files: the symlinks are
#     removed, re-run the installer (or zinit) to fetch the release files
#
# Only symlinks are ever touched -- a non-linked install is left as-is.

set -e

restored=0


# oh-my-zsh: ~/.oh-my-zsh/custom/{themes,plugins/jovial}/
omz_dir="${ZSH:-${HOME}/.oh-my-zsh}"
for file in \
    "${omz_dir}/custom/themes/jovial.zsh-theme" \
    "${omz_dir}/custom/plugins/jovial/jovial.plugin.zsh"
do
    if [[ -L ${file} ]]; then
        rm -f "${file}"
        print "removed  ${file} (re-run the installer to restore the release file)"
        restored=1
    fi
done


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

if [[ -n ${zinit_plugins_dir} && -d ${zinit_plugins_dir}/zthxxx---jovial ]]; then
    zinit_jovial="${zinit_plugins_dir}/zthxxx---jovial"
    for name in jovial.zsh-theme jovial.plugin.zsh; do
        if [[ -L ${zinit_jovial}/${name} ]]; then
            rm -f "${zinit_jovial}/${name}"
            if git -C "${zinit_jovial}" checkout -- "${name}" 2>/dev/null; then
                print "restored ${zinit_jovial}/${name} (via git checkout)"
            else
                print "removed  ${zinit_jovial}/${name} (not a git clone -- reinstall via zinit)"
            fi
            restored=1
        fi
    done
fi


if (( ! restored )); then
    print "nothing linked, nothing to restore"
fi
