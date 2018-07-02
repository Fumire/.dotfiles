#!/bin/sh
if [ -e ~/.tmux.conf ]; then
    mv -f ~/.tmux.conf ~/.dotfiles/_old/tmux.conf
    ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
fi
