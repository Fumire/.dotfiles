#!/bin/sh
if [ ! -e $HOME/.dotfiles/_old/ ]; then
    mkdir $HOME/.dotfiles/_old
fi
. setup/vim.sh
. setup/zsh.sh
. setup/tmux.sh
. setup/git.sh
