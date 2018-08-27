#!/bin/sh
if [ -e ~/.vimrc ]; then
    mv -f ~/.vimrc ~/.dotfiles/_old/vimrc
    echo "move vimrc"
fi
ln -s ~/.dotfiles/vimrc ~/.vimrc
