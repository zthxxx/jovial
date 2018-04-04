#!/usr/bin/env zsh

install_zsh() {
    # other ref: https://unix.stackexchange.com/questions/136423/making-zsh-default-shell-without-root-access?answertab=active#tab-top
    local UNAME="$1"
    if [ -z "${ZSH_VERSION}" ]; then
        if command -v zsh > /dev/null; then 
            chsh $UNAME -s `command -v zsh`
            return 0
        fi
        echo "this theme base on zsh, trying to install it!" >&2
        if brew install zsh || \
            apt install -y zsh || \
            apt-get install -y zsh || \
            yum -y install zsh ; then
            chsh $UNAME -s `command -v zsh`
        else
            echo "ERROR, plz install zsh manual."
            return 1
        fi
    fi
}

install_ohmyzsh() {
    if [ -z "${ZSH:-}" -o -z "${ZSH_CUSTOM:-}" ]; then
        echo "this theme base on oh-my-zsh, now will install it!" >&2
        curl -fsSL http://install.ohmyz.sh | sh
    fi
}

(install_zsh "$1" && install_ohmyzsh) || exit 1

install_theme() {
    local ZTHEME="jovial"
    local theme_path="github.com/zthxxx/${ZTHEME}/raw/master/${ZTHEME}.zsh-theme"
    local theme_file="${ZSH_CUSTOM:-"${HOME}/.oh-my-zsh/custom"}/${ZTHEME}.zsh-theme"
    curl -sSL "$theme_path" -o "$theme_file"
    sed  "-i''" "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" ~/.zshrc
}

install_theme

