# the example `~/.zshrc` for jovial + antigen
# 
#    curl -SL https://github.com/zthxxx/jovial/raw/master/examples/antigen.zshrc >> ~/.zshrc
#


# [Antigen](https://github.com/zsh-users/antigen), 
# a theme/plugin manager for zsh that uses simple declarative configuration.
# install antigen if not exists
if [[ ! -f ~/.antigen/antigen.zsh ]]; then
  set -e
  echo "Antigen not installed, downloading..."
  mkdir -p ~/.antigen
  curl -SL https://github.com/zsh-users/antigen/raw/develop/bin/antigen.zsh -o ~/.antigen/antigen.zsh
  set +e
fi

# Load Antigen
source ~/.antigen/antigen.zsh

# Basic recommended for antigen
antigen use oh-my-zsh
antigen bundle git
antigen bundle autojump
antigen bundle colored-man-pages
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the Jovial theme and plugins
antigen theme zthxxx/jovial
antigen bundle zthxxx/jovial
antigen bundle zthxxx/zsh-history-enquirer


# Any other plugins needs set before `antigen apply`

# After all, tell Antigen that you're done, then antigen will start
antigen apply
