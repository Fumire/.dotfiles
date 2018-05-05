#!/bin/sh
if [ ! -e ~/.dotfiles/_old/ ]; then
    mkdir ~/.dotfiles/_old
fi
. setup/vim.sh
. setup/zsh.sh
. setup/tmux.sh
. setup/git.sh
