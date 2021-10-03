#!/usr/bin/env bash

# Usage
#   $ cat installer.sh | sudo -E bash -s $USER
#
# use sudo to make this script has access, and use '-E' for preserve most env variables;
# use '-s $USER' to pass "real target user" to this install script

COLOR_RED=`tput setaf 9`
COLOR_GREEN=`tput setaf 10`
COLOR_YELLOW=`tput setaf 11`
SGR_RESET=`tput sgr 0`

# bash strict mode (https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425)
set -xo pipefail

S_USER="$USER"
S_HOME="$HOME"

# set the real target user by params
if [[ -n $1 ]]; then 
    S_USER="$1"
    S_HOME=`sudo -u "${S_USER}" -i echo '$HOME'`
fi

# setup oh-my-zsh env variables
if [[ -z "${ZSH}" ]]; then
    # If ZSH is not defined, use the current script's directory.
    ZSH="${S_HOME}/.oh-my-zsh"
fi

# Set ZSH_CUSTOM to the path where your custom config files
ZSH_CUSTOM="${ZSH}/custom"

log.info() {
    set +x
    echo -e "\n${COLOR_YELLOW} $@ ${SGR_RESET}\n"
    set -x
}

log.success() {
    set +x
    echo -e "\n${COLOR_GREEN} $@ ${SGR_RESET}\n"
    set -x
}

log.error() {
    set +x
    echo -e "\n${COLOR_RED} $@ ${SGR_RESET}\n" >&2
    set -x
}

is-command() { command -v $@ &> /dev/null; }

# it's same as `realpath <file>`, but `realpath` is GNU only and not builtin
prel-realpath() {
  perl -MCwd -e 'print Cwd::realpath($ARGV[0]),qq<\n>' $1
}

install-via-manager() {
    local package="$1"
    log.info "[jovial] install package: ${package}"

    if is-command brew; then
        sudo -Eu ${S_USER} brew install ${package}

    elif is-command apt; then
        apt install -y ${package}

    elif is-command apt-get; then
        apt-get install -y ${package}

    elif is-command yum; then
        yum install -y ${package}

    elif is-command pacman; then
        pacman -S --noconfirm --needed ${package}
    fi
}

install.packages() {
    local packages=( $@ )
    log.info "[jovial] install packages: ${packages[@]}"

    local package

    for package in ${packages[@]}; do
        install-via-manager ${package}
    done
}

install.zsh() {
    log.info "[jovial] detect whether installed zsh"

    if [[ "${SHELL}" =~ '/zsh$' ]]; then
        log.success "[jovial] default shell is zsh, skip to install"
        return 0
    fi

    if is-command zsh || install.packages zsh; then
        log.info "[jovial] switch default login shell to zsh"
        chsh -s `command -v zsh` ${S_USER}
        return 0
    else
        log.error "[ERROR][jovial] cannot find or install zsh, please install zsh manually"
        return 1
    fi
}

install.ohmyzsh() {
    log.info "[jovial] detect whether installed oh-my-zsh"

    if [[ -d ${ZSH} && -d ${ZSH_CUSTOM} ]]; then
        log.success "[jovial] oh-my-zsh detected, skip to install"
        return 0
    fi

    log.info "[jovial] this theme base on oh-my-zsh, now will install it"

    if ! is-command git; then
        install.packages git
    fi
    
    # https://ohmyz.sh/#install
    curl -sSL -H 'Cache-Control: no-cache' https://github.com/ohmyzsh/ohmyzsh/raw/master/tools/install.sh | sudo -Eu ${S_USER} sh    
}


install.zsh-plugins() {
    log.info "[jovial] install zsh plugins"

    local plugin_dir="${ZSH_CUSTOM}/plugins"

    if ! is-command git; then
        install.packages git
    fi

    install.packages autojump terminal-notifier source-highlight

    if [[ ! -d ${plugin_dir}/zsh-autosuggestions ]]; then
        log.info "[jovial] install plugin zsh-autosuggestions"
        sudo -Eu ${S_USER} git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${plugin_dir}/zsh-autosuggestions"
    fi

    if [[ ! -d ${plugin_dir}/zsh-syntax-highlighting ]]; then
        log.info "[jovial] install plugin zsh-syntax-highlighting"
        sudo -Eu ${S_USER} git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${plugin_dir}/zsh-syntax-highlighting"
    fi

    log.info "[jovial] install plugin zsh-history-enquirer"
    curl -sSL -H 'Cache-Control: no-cache' https://github.com/zthxxx/zsh-history-enquirer/raw/master/scripts/installer.zsh | sudo -Eu ${S_USER} zsh

    log.info "[jovial] setup oh-my-zsh plugins in ~/.zshrc"
    local plugins=(
        git
        autojump
        urltools
        bgnotify
        zsh-autosuggestions
        zsh-syntax-highlighting
        zsh-history-enquirer
        jovial
    )

    local plugin_str="${plugins[@]}"
    plugin_str="\n  ${plugin_str// /\\n  }\n"
    perl -0i -pe "s/^plugins=\(.*?\) *$/plugins=(${plugin_str})/gms" $(prel-realpath "${S_HOME}/.zshrc")
}

preference-zsh() {
    log.info "[jovial] preference zsh in ~/.zshrc"

    if is-command brew; then
        perl -i -pe "s/.*HOMEBREW_NO_AUTO_UPDATE.*//gms" $(prel-realpath "${S_HOME}/.zshrc")
        echo "export HOMEBREW_NO_AUTO_UPDATE=true" >> "${S_HOME}/.zshrc"
    fi

    install.zsh-plugins
}

install.theme() {
    log.info "[jovial] install theme 'jovial'"

    local theme_name="jovial"
    local git_prefix="https://github.com/zthxxx/${theme_name}/raw/master"

    local theme_remote="${git_prefix}/${theme_name}.zsh-theme"
    local plugin_remote="${git_prefix}/${theme_name}.plugin.zsh"

    local custom_dir="${ZSH_CUSTOM:-"${S_HOME}/.oh-my-zsh/custom"}"

    sudo -Eu ${S_USER} mkdir -p "${custom_dir}/themes" "${custom_dir}/plugins/${theme_name}"
    local theme_local="${custom_dir}/themes/${theme_name}.zsh-theme"
    local plugin_local="${custom_dir}/plugins/${theme_name}/${theme_name}.plugin.zsh"

    sudo -Eu ${S_USER} curl -sSL -H 'Cache-Control: no-cache' "${theme_remote}" -o "${theme_local}"
    sudo -Eu ${S_USER} curl -sSL -H 'Cache-Control: no-cache' "${plugin_remote}" -o "${plugin_local}"
    perl -i -pe "s/^ZSH_THEME=.*/ZSH_THEME=\"${theme_name}\"/g" $(prel-realpath "${S_HOME}/.zshrc")
}


(install.zsh && install.ohmyzsh) || exit 1

install.theme
preference-zsh


log.success "[jovial] installed"
