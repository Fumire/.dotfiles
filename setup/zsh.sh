#!/bin/sh
if [ ! -d ~/.oh-my-zsh ]
then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if [ -e ~/.zshrc ]; then
    mv -f ~/.zshrc ~/.dotfiles/_old/zshrc
fi
ln -s ~/.dotfiles/zshrc ~/.zshrc

ln -s ~/.dotfiles/oh-my-zsh/themes/custom.zsh-theme ~/.oh-my-zsh/themes/custom.zsh-theme

if [ -e ~/.alias.zsh ]; then
    mv -f ~/.alias.zsh ~/.dotfiles/_old/alias.zsh
fi
ln -s ~/.dotfiles/oh-my-zsh/alias.zsh ~/.alias.zsh
source ~/.alias.zsh
