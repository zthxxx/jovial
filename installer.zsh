#!/usr/bin/env zsh

is_command() { command -v $@ &> /dev/null; }

install_via_manager() {
    local packages=( $@ )
    brew install ${packages[@]} || \
        apt install -y ${packages[@]} || \
        apt-get install -y ${packages[@]} || \
        yum -y install ${packages[@]} || \
        pacman -S --noconfirm ${packages[@]}
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
        install_via_manager git
        curl -fsSL install.ohmyz.sh | sh
    fi
}

(install_zsh "$1" && install_ohmyzsh) || exit 1

install_zsh_plugins() {
    install_via_manager git autojump terminal-notifier
    local plugins=(
        git
        autojump
        urltools
        bgnotify
        jovial
    )
    local plugin_str="${plugins[@]}"
    sed "-i" "
        /^plugins=(/ \
        { \
            :n; \
                /plugins=(.*)/ \
            ! { N; bn }; \
            s/(.*)/(\n  ${plugin_str// /"\n"  }\n)/ \
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
    local git_prefix="github.com/zthxxx/${ZTHEME}/raw/master"

    local theme_remote="${git_prefix}/${ZTHEME}.zsh-theme"
    local plugin_remote="${git_prefix}/${ZTHEME}.plugin.zsh"

    local custom_dir="${ZSH_CUSTOM:-"${HOME}/.oh-my-zsh/custom"}"

    mkdir -p "${custom_dir}/themes" "${custom_dir}/plugins/${ZTHEME}"
    local theme_local="${custom_dir}/themes/${ZTHEME}.zsh-theme"
    local plugin_local="${custom_dir}/plugins/${ZTHEME}/${ZTHEME}.plugin.zsh"

    curl -sSL "$theme_remote" -o "$theme_local"
    curl -sSL "$plugin_remote" -o "$plugin_local"
    sed "-i" "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" ~/.zshrc
}

install_theme
preference_zsh
