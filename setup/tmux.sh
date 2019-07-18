#!/bin/sh
if [ -e $HOME/.tmux.conf ]; then
    mv -f $HOME/.tmux.conf $HOME/.dotfiles/_old/tmux.conf
    echo "move tmux.conf"
fi
ln -s -f $HOME/.dotfiles/tmux/tmux.conf $HOME/.tmux.conf

if [ -e $HOME/.tmux.conf.local ]; then
    mv -f $HOME/.tmux.conf.local $HOME/.dotfiles/_old/tmux.conf.local
    echo "move tmux.conf.local"
fi
ln -s -f $HOME/.dotfiles/tmux/tmux.conf.local $HOME/.tmux.conf.local
