#!/usr/bin/env zsh

if [ -z "${ZSH_VERSION:-}" ]; then
    echo "this theme base on zsh, trying to install it!" >&2
    if brew install zsh || \
        apt install -y zsh || \
        apt-get install -y zsh || \
        yum -y install zsh; then
        return 0
    else
        echo "ERROR, plz install zsh manual."
        exit 1
    fi
fi

if [ -z "${ZSH:-}" -o -z "${ZSH_CUSTOM:-}" ]; then
    echo this theme base on oh-my-zsh, now will install it! >&2
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

local ZTHEME="jovial"
local theme_path="github.com/zthxxx/${ZTHEME}/raw/master/installer.zsh"
local theme_file="${ZSH_CUSTOM:-"~/.oh-my-zsh/custom"}/themes/${ZTHEME}.zsh-theme"
curl -sSL "$theme_path" -o "$theme_file"
sed  -i '' "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" .zshrc
