#!/bin/sh
if [ -e ~/.tmux.conf ]; then
    mv -f ~/.tmux.conf ~/.dotfiles/_old/tmux.conf
    echo "move tmux.conf"
fi
ln -s -f ~/.dotfiles/tmux.conf ~/.tmux.conf

if [ -e ~/.tmux.conf.local ]; then
    mv -f ~/.tmux.conf.local ~/.dotfiles/_old/tmux.conf.local
    echo "move tmux.conf.local"
fi
ln -s -f ~/.dotfiles/tmux.conf.local ~/.tmux.conf.local
