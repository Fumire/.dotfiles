#!/bin/sh
if [ -e $HOME/.vimrc ]; then
    mv -f $HOME/.vimrc $HOME/.dotfiles/_old/vimrc
    echo "move vimrc"
fi
ln -s -f $HOME/.dotfiles/vim/vimrc $HOME/.vimrc

if [ -e $HOME/.ycm_extra_conf.py ]; then
    mv -f $HOME/.ycm_extra_conf.py $HOME/.dotfiles/_old/ycm_extra_conf.py
    echo "move ycm extra conf files"
fi
ln -s -f $HOME/.dotfiles/vim/ycm_extra_conf.py $HOME/.ycm_extra_conf.py

if [ -e $HOME/.style.yapf ]; then
    mv -f $HOME/.style.yapf $HOME/.dotfiles/_old/style.yapf
fi
ln -s -f $HOME/.dotfiles/vim/style.yapf $HOME/.style.yapf
