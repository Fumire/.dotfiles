#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
if [ $(which zsh > /dev/null; echo $?) = 0 ]; then
    which $SHELL | grep "zsh" > /dev/null || chsh -s $(which zsh)
else
    if [ $(uname) = "Darwin" ]; then
        brew install zsh
        chsh -s $(which zsh)
    elif [ $(uname) = "Linux" -a $(whoami) = "root" ]; then
        apt-get update && apt-get install zsh -y
        chsh -s $(which zsh)
    else
        curl --silent --output $HOME/zsh.tar.xz --location https://sourceforge.net/projects/zsh/files/latest/download
        cd $HOME && mkdir zsh && unxz zsh.tar.xz && tar -xf zsh.tar -C zsh --strip-components 1
        cd $HOME/zsh && ./configure --without-tcsetpgrp --prefix $HOME && make -j && make -j install
        chsh -s $HOME/bin/zsh
    fi
fi
