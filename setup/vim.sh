#!/bin/sh
if [ -e ~/.vimrc ]; then
    mv -f ~/.vimrc ~/.dotfiles/_old/vimrc
    echo "move vimrc"
fi
ln -s -f ~/.dotfiles/vimrc ~/.vimrc

if [ -e ~/.ycm_extra_conf.py ]; then
    mv -f ~/.ycm_extra_conf.py ~/.dotfiles/_old/ycm_extra_conf.py
    echo "move ycm extra conf files"
fi
ln -s -f ~/.dotfiles/ycm_extra_conf.py ~/.ycm_extra_conf.py
