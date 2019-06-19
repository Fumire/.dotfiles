#!/bin/sh
if [ -e ~/.gitconfig ]; then
    mv -f ~/.gitconfig ~/.dotfiles/_old/gitconfig
    echo  "move gitconfig"
fi
ln -s -f ~/.dotfiles/gitconfig ~/.gitconfig

if [ -e ~/.gitignore_global ]; then
    mv -f ~/.gitignore_global ~/.dotfiles/_old/gitignore_global
    echo "move gitignore_global"
fi
ln -s -f ~/.dotfiles/gitignore_global ~/.gitignore_global

git config --global core.excludesfile ~/.gitignore_global
