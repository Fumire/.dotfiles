#!/bin/sh
if [ -e $HOME/.gitconfig ]; then
    mv -f $HOME/.gitconfig $HOME/.dotfiles/_old/gitconfig
    echo  "move gitconfig"
fi
ln -s -f $HOME/.dotfiles/git/gitconfig $HOME/.gitconfig

if [ -e $HOME/.gitignore_global ]; then
    mv -f $HOME/.gitignore_global $HOME/.dotfiles/_old/gitignore_global
    echo "move gitignore_global"
fi
ln -s -f $HOME/.dotfiles/git/gitignore_global $HOME/.gitignore_global

git config --global core.excludesfile $HOME/.gitignore_global
