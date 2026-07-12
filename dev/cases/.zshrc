# e2e preview `~/.zshrc` -- based on examples/zinit.zshrc, but with ALL third-party
# plugins removed: it bootstraps zinit and loads ONLY jovial (from the live-mounted
# repo at /work), so the preview reflects local theme changes with nothing else in
# the prompt path. Loaded via ZDOTDIR (see the *.tape files).


# ----------------------------------------------- #
#                  Common Config                  #
# ----------------------------------------------- #
# write the compdump to /tmp so the bind-mounted cases/ dir stays clean
autoload -Uz compinit && compinit -d /tmp/zcompdump

# https://wiki.archlinux.org/title/XDG_Base_Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"


# ----------------------------------------------- #
#                     Zinit                       #
# ----------------------------------------------- #
# https://zdharma-continuum.github.io/zinit/wiki/
#
# zinit is pre-installed in the image (see dev/e2e/Dockerfile); the clone below is
# only a fallback so this config also works on a bare environment.
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"
if [[ ! -f ${ZINIT_HOME}/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220} Installing %F{33}zdharma-continuum/zinit%F{220}…%f"
    command mkdir -p "${XDG_DATA_HOME}/zinit" && command chmod g-rwX "${XDG_DATA_HOME}/zinit"
    command git clone --filter=tree:0 https://github.com/zdharma-continuum/zinit "${ZINIT_HOME}"
fi

# keep zinit's compdump out of the bind-mounted cases/ dir (declare before source,
# so zinit picks it up instead of defaulting to ${ZDOTDIR}/.zcompdump)
typeset -gA ZINIT
ZINIT[ZCOMPDUMP_PATH]=/tmp/zcompdump

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


# load jovial only (plugin + theme) from the live-mounted repo -- no other plugins
zinit light-mode depth=1 multisrc='{jovial.plugin.zsh,jovial.zsh-theme}' for "${JOVIAL_REPO_DIR:-/work}"
