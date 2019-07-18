#!/bin/sh
if [ -e /bin/zsh ]; then
    if [ "${echo $SHELL}" != "${which zsh}" ]; then
        chsh -s `which zsh`
        echo "change SHELL to zsh"
    fi
elif [ -e /usr/local/bin/zsh ]; then
    echo "export SHELL=/usr/local/bin/zsh\nexec /usr/local/bin/zsh -l" >> ~/.bash_profile
    source ~/.bash_profile
else
    if [ ! -e ~/bin/zsh ]; then
        curl --output ~/zsh.tar.xz -L https://sourceforge.net/projects/zsh/files/latest/download
        cd ~ && mkdir zsh && unxz zsh.tar.xz && tar -xvf zsh.tar -C zsh --strip-components 1
        cd ~/zsh && ./configure --prefix $HOME && make && make install
    fi
    echo "export SHELL=~/bin/zsh" >> ~/.bash_profile
    echo "[ -z \"\$ZSH_VERSION\" ] && exec \"\$SHELL\" -l" >> ~/.bash_profile
    source ~/.bash_profile
fi

if [ ! -d ~/.oh-my-zsh ]; then
    echo "download oh-my-zsh"
    sh -c "${curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh}"
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

