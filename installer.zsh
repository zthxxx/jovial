#!/usr/bin/env zsh

S_USER=root
S_HOME="$HOME"
# cat install.zsh  | bash -s $USER
if [[ -n $1 ]]; then 
    S_USER="$1"
    S_HOME=`sudo -u "$S_USER" -i echo '$HOME'`
fi

is_command() { command -v $@ &> /dev/null; }

install_via_manager() {
    echo "+ install_via_manager $@"

    local packages=( $@ )
    local package

    for package in ${packages[@]}; do
        (sudo -u $S_USER -i brew install ${package}) || \
            apt install -y ${package} || \
            apt-get install -y ${package} || \
            yum -y install ${package} || \
            pacman -S --noconfirm --needed ${package}
    done
}

install_zsh() {
    echo '+ install_zsh'

    # other ref: https://unix.stackexchange.com/questions/136423/making-zsh-default-shell-without-root-access?answertab=active#tab-top
    if [[ -z ${ZSH_VERSION} ]]; then
        if is_command zsh || install_via_manager zsh; then
            echo "+ chsh to zsh"
            chsh -s `command -v zsh` $S_USER
            return 0
        else
            echo "ERROR, plz install zsh manual."
            return 1
        fi
    fi
}

install_ohmyzsh() {
    echo '+ install_ohmyzsh'

    if [[ ! -d ${S_HOME}/.oh-my-zsh && (-z ${ZSH} || -z ${ZSH_CUSTOM}) ]]; then
        echo "this theme base on oh-my-zsh, now will install it!" >&2
        install_via_manager git
        curl -fsSL -H 'Cache-Control: no-cache' install.ohmyz.sh | sudo -u $S_USER -i sh
    fi
}


install_zsh_plugins() {
    echo '+ install_zsh_plugins'

    local plugin_dir="${ZSH_CUSTOM:-"${S_HOME}/.oh-my-zsh/custom"}/plugins"

    install_via_manager git autojump terminal-notifier source-highlight

    if [[ ! -e ${plugin_dir}/zsh-autosuggestions ]]; then
        echo '+ install zsh-autosuggestions'
        sudo -u $S_USER -i git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${plugin_dir}/zsh-autosuggestions"
    fi

    if [[ ! -e ${plugin_dir}/zsh-syntax-highlighting ]]; then
        echo '+ install zsh-syntax-highlighting'
        sudo -u $S_USER -i git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugin_dir}/zsh-syntax-highlighting"
    fi

    if [[ ! -e ${plugin_dir}/zsh-history-enquirer ]]; then
        echo '+ install zsh-history-enquirer'
        curl -sSL -H 'Cache-Control: no-cache' https://github.com/zthxxx/zsh-history-enquirer/raw/master/scripts/installer.zsh | sudo -u $S_USER -i zsh
    fi

    local plugins=(
        git
        autojump
        urltools
        bgnotify
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-history-enquirer
        jovial

        # TODO: case "$OSTYPE" in (darwin*)
        osx
    )

    local plugin_str="${plugins[@]}"
    plugin_str="\n  ${plugin_str// /\\n  }\n"
    perl -0i -pe "s/^plugins=\(.*?\) *$/plugins=(${plugin_str})/gms" ${S_HOME}/.zshrc
}

preference_zsh() {
    echo '+ preference_zsh'

    if is_command brew; then
        perl -i -pe "s/.*HOMEBREW_NO_AUTO_UPDATE.*//gms" ${S_HOME}/.zshrc
        echo "export HOMEBREW_NO_AUTO_UPDATE=true" >> ${S_HOME}/.zshrc
    fi
    install_zsh_plugins
}

install_theme() {
    echo '+ install_theme'

    local ZTHEME="jovial"
    local git_prefix="https://github.com/zthxxx/${ZTHEME}/raw/master"

    local theme_remote="${git_prefix}/${ZTHEME}.zsh-theme"
    local plugin_remote="${git_prefix}/${ZTHEME}.plugin.zsh"

    local custom_dir="${ZSH_CUSTOM:-"${S_HOME}/.oh-my-zsh/custom"}"

    sudo -u $S_USER -i mkdir -p "${custom_dir}/themes" "${custom_dir}/plugins/${ZTHEME}"
    local theme_local="${custom_dir}/themes/${ZTHEME}.zsh-theme"
    local plugin_local="${custom_dir}/plugins/${ZTHEME}/${ZTHEME}.plugin.zsh"

    sudo -u $S_USER -i curl -sSL -H 'Cache-Control: no-cache' "$theme_remote" -o "$theme_local"
    sudo -u $S_USER -i curl -sSL -H 'Cache-Control: no-cache' "$plugin_remote" -o "$plugin_local"
    perl -i -pe "s/^ZSH_THEME=.*/ZSH_THEME=\"${ZTHEME}\"/g" ${S_HOME}/.zshrc
}


(install_zsh && install_ohmyzsh) || exit 1

install_theme
preference_zsh


echo '+ jovial installed'
