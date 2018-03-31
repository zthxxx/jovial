#!/usr/bin/env zsh

install_zsh() {
    if [ -z "${ZSH_VERSION:-}" ]; then
        if command -v zsh 2> /dev/null; then 
            chsh -s `command -v zsh`
        fi
        echo "this theme base on zsh, trying to install it!" >&2
        if brew install zsh || \
            apt install -y zsh || \
            apt-get install -y zsh || \
            yum -y install zsh ; then
            chsh -s `command -v zsh`
        else
            echo "ERROR, plz install zsh manual."
            return 1
        fi
    fi
}

install_ohmyzsh() {
    if [ -z "${ZSH:-}" -o -z "${ZSH_CUSTOM:-}" ]; then
        echo "this theme base on oh-my-zsh, now will install it!" >&2
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
}

(install_zsh && install_ohmyzsh) || exit 1

local ZTHEME="jovial"
local theme_path="github.com/zthxxx/${ZTHEME}/raw/master/${ZTHEME}.zsh-theme"
local theme_file="${ZSH_CUSTOM:-"${HOME}/.oh-my-zsh/custom"}/${ZTHEME}.zsh-theme"
curl -sSL "$theme_path" -o "$theme_file"
sed  "-i''" "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" ~/.zshrc
