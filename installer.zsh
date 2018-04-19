#!/usr/bin/env zsh

is_command() { command -v $@ > /dev/null; }

install_via_manager() {
    local packages=( $@ )
    brew install $packages || \
        apt install -y $packages || \
        apt-get install -y $packages || \
        yum -y install $packages || \
        pacman -S --noconfirm $packages
}

install_zsh() {
    # other ref: https://unix.stackexchange.com/questions/136423/making-zsh-default-shell-without-root-access?answertab=active#tab-top
    local UNAME="$1"
    if [ -z "${ZSH_VERSION}" ]; then
        if is_command zsh || install_via_manager zsh; then
            chsh $UNAME -s `command -v zsh`
            return 0
        else
            echo "ERROR, plz install zsh manual."
            return 1
        fi
    fi
}

install_ohmyzsh() {
    if [[ ! -d "${HOME}/.oh-my-zsh" && (-z "${ZSH}" || -z "${ZSH_CUSTOM}") ]]; then
        echo "this theme base on oh-my-zsh, now will install it!" >&2
        curl -fsSL http://install.ohmyz.sh | sh
    fi
}

(install_zsh "$1" && install_ohmyzsh) || exit 1

install_zsh_plugins() {
    install_via_manager git autojump
    local plugins=(
        git
        autojump
        urltools
    )
    local plugin_str="${plugins[@]}"
    sed "-i" "
        /^plugins=(/ \
        { \
            :n; \
                /plugins=(.*)/ \
            ! { N; bn }; \
            s/(.*)/(\n  ${plugin_str// /\n  }\n)/ \
        } \
    " ~/.zshrc
}

preference_zsh() {
    if is_command brew; then
        sed "-i" "s/HOMEBREW_NO_AUTO_UPDATE/d" ~/.zshrc
        echo "export HOMEBREW_NO_AUTO_UPDATE=true" >> ~/.zshrc
    fi
    install_zsh_plugins
}

install_theme() {
    local ZTHEME="jovial"
    local theme_path="github.com/zthxxx/${ZTHEME}/raw/master/${ZTHEME}.zsh-theme"
    local theme_file="${ZSH_CUSTOM:-"${HOME}/.oh-my-zsh/custom"}/${ZTHEME}.zsh-theme"
    curl -sSL "$theme_path" -o "$theme_file"
    sed "-i" "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" ~/.zshrc
}

install_theme
preference_zsh
