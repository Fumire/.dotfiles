#!/bin/sh
if [ "$(echo $SHELL)" != "$(which zsh)" ]; then
    chsh -s `which zsh`
    echo "change SHELL to zsh"
fi

if [ ! -d ~/.oh-my-zsh ]; then
    echo "download oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if [ -e ~/.zshrc ]; then
    mv -f ~/.zshrc ~/.dotfiles/_old/zshrc
    echo "move zshrc"
fi
ln -s ~/.dotfiles/zshrc ~/.zshrc

if [ -e ~/.oh-my-zsh/themes/custom.zsh-theme ]; then
    mv -f ~/.oh-my-zsh/themes/custom.zsh-theme ~/.dotfiles/_old/custom.zsh-theme
    echo "move custom theme"
fi
ln -s ~/.dotfiles/oh-my-zsh/themes/custom.zsh-theme ~/.oh-my-zsh/themes/custom.zsh-theme
