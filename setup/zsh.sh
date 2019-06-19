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
ln -s -f ~/.dotfiles/zshrc ~/.zshrc

if [ -e ~/.oh-my-zsh/themes/local.zsh-theme ]; then
    mv -f ~/.oh-my-zsh/themes/local.zsh-theme ~/.dotfiles/_old/local.zsh-theme
    echo "move local theme"
fi
ln -s -f ~/.dotfiles/oh-my-zsh/themes/local.zsh-theme ~/.oh-my-zsh/themes/local.zsh-theme

if [ -e ~/.oh-my-zsh/themes/remote.zsh-theme ]; then
    mv -f ~/.oh-my-zsh/themes/remote.zsh-theme ~/.dotfiles/_old/remote.zsh-theme
    echo "move local theme"
fi
ln -s -f ~/.dotfiles/oh-my-zsh/themes/remote.zsh-theme ~/.oh-my-zsh/themes/remote.zsh-theme
