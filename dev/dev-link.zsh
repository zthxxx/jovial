#!/usr/bin/env zsh

# usage: ./dev/dev-link.zsh

## curl -sSL -H 'Cache-Control: no-cache' https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo bash -s $USER

ln -fs "$(pwd)/jovial.zsh-theme" ~/.oh-my-zsh/custom/themes/jovial.zsh-theme
ln -fs "$(pwd)/jovial.plugin.zsh" ~/.oh-my-zsh/custom/plugins/jovial/jovial.plugin.zsh
