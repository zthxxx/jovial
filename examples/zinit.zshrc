# the example `~/.zshrc` for jovial + zinit
#
# Usage:
# 
#    curl -SL https://github.com/zthxxx/jovial/raw/master/examples/zinit.zshrc -o ~/.zshrc
#


# ----------------------------------------------- #
#                  Common Config                  #
# ----------------------------------------------- #
autoload -Uz compinit && compinit

# https://wiki.archlinux.org/title/XDG_Base_Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"



# ----------------------------------------------- #
#                     PATH                        #
# ----------------------------------------------- #



# ----------------------------------------------- #
#                  ZSH Config                     #
# ----------------------------------------------- #


# Zinit
#
# https://zdharma-continuum.github.io/zinit/wiki/
#
### Added by Zinit's installer
#
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"
if [[ ! -f ${ZINIT_HOME}/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220} Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "${XDG_DATA_HOME}/zinit" && command chmod g-rwX "${XDG_DATA_HOME}/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "${ZINIT_HOME}" && \
        print -P "%F{33}▓▒░ %F{34} Installation successful.%f%b" || \
        print -P "%F{160}▓▒░  The clone has failed.%f%b"
fi

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


zinit light-mode depth=1 multisrc='*.plugin.zsh' for zthxxx/jovial


# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/
local zinit_omz_libs=(
  history
  key-bindings
  functions
  directories
  completion
  git
)


# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/
local zinit_omz_plugins=(
  git
  autojump
  macos
  extract
  colored-man-pages
  urltools
  bgnotify
)


# https://zdharma-continuum.github.io/zinit
# https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/
zinit light-mode depth=1 wait lucid as=null for \
    multisrc="lib/{${(j:,:)zinit_omz_libs}}.zsh" \
        ohmyzsh/ohmyzsh \
    multisrc="plugins/{${(j:,:)zinit_omz_plugins}}/*.plugin.zsh" \
        ohmyzsh/ohmyzsh


## https://github.com/zthxxx/zsh-history-enquirer
## https://github.com/zdharma-continuum/fast-syntax-highlighting
zinit light-mode depth=1 wait lucid for \
    multisrc='*.plugin.zsh' \
        zthxxx/zsh-history-enquirer \
    atinit="ZINIT[COMPINIT_OPTS]=-C" \
        zdharma-continuum/fast-syntax-highlighting \
    blockf \
        zsh-users/zsh-completions \
    atload="_zsh_autosuggest_start; zicompinit; zicdreplay" \
        zsh-users/zsh-autosuggestions


# ----------------------------------------------- #
#                  Custom Config                  #
# ----------------------------------------------- #

