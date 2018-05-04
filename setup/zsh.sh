#!/bin/sh
if [ ! -d ~/.oh-my-zsh ]
then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/oh-my-zsh/themes/custom.zsh-theme ~/.oh-my-zsh/themes/custom.zsh-theme
