#!/bin/sh
if [ -e ~/.gitconfig ]; then
    mv -f ~/.gitconfig ~/.dotfiles/_old/gitconfig
    ln -s ~/.dotfiles/gitconfig ~/.gitconfig
fi

if [ -e ~/.gitignore_global ]; then
    mv -f ~/.gitignore_global ~/.dotfiles/_old/gitignore_global
    ln -s ~/.dotfiles/gitignore_global ~/.gitignore_global
fi

git config --global core.excludesfile ~/.gitignore_global
