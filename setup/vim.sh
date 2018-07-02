#!/bin/sh
if [ -e ~/.vimrc ]; then
    mv -f ~/.vimrc ~/.dotfiles/_old/vimrc
    ln -s ~/.dotfiles/vimrc ~/.vimrc
fi
