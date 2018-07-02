#!/bin/sh
if [ "$(echo $SHELL)" != "$(which zsh)" ]; then
    chsh -s `which zsh`
fi

if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if [ -e ~/.zshrc ]; then
    mv -f ~/.zshrc ~/.dotfiles/_old/zshrc
    ln -s ~/.dotfiles/zshrc ~/.zshrc
fi

if [ -e ~/.oh-my-zsh/themes/custom.zsh-theme ]; then
    mv -f ~/.oh-my-zsh/themes/custom.zsh-theme ~/.dotfiles/_old/custom.zsh-theme
    ln -s ~/.dotfiles/oh-my-zsh/themes/custom.zsh-theme ~/.oh-my-zsh/themes/custom.zsh-theme
fi
