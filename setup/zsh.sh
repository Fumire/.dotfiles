#!/bin/sh
if [ -e /bin/zsh ]; then
    if [ "$(echo $SHELL)" != "$(which zsh)" ]; then
        chsh -s `which zsh`
        echo "change SHELL to zsh"
    fi
elif [ -e /usr/local/bin/zsh ]; then
    echo "export SHELL=/usr/local/bin/zsh\nexec /usr/local/bin/zsh -l" >> $HOME/.bash_profile
    source $HOME/.bash_profile
else
    if [ ! -e $HOME/bin/zsh ]; then
        curl --output $HOME/zsh.tar.xz -L https://sourceforge.net/projects/zsh/files/latest/download
        cd $HOME && mkdir zsh && unxz zsh.tar.xz && tar -xvf zsh.tar -C zsh --strip-components 1
        cd $HOME/zsh && ./configure --prefix $HOME && make && make install
    fi
    echo "export SHELL=$HOME/bin/zsh" >> $HOME/.bash_profile
    echo "[ -z \"\$ZSH_VERSION\" ] && exec \"\$SHELL\" -l" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "download oh-my-zsh"
    sh -c "${curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh}"
fi

if [ -e $HOME/.zshrc ]; then
    mv -f $HOME/.zshrc $HOME/.dotfiles/_old/zshrc
    echo "move zshrc"
fi
ln -s -f $HOME/.dotfiles/zsh/zshrc $HOME/.zshrc

if [ -e $HOME/.alias.zsh ]; then
    mv -f $HOME/.alias.zsh $HOME/.dotfiles/_old/alias.zsh
    echo "move alias.zsh"
fi
ln -s -f $HOME/.dotfiles/zsh/alias.zsh $HOME/.alias.zsh

if [ -e $HOME/.oh-my-zsh/themes/local.zsh-theme ]; then
    mv -f $HOME/.oh-my-zsh/themes/local.zsh-theme $HOME/.dotfiles/_old/local.zsh-theme
    echo "move local theme"
fi
ln -s -f $HOME/.dotfiles/oh-my-zsh/themes/local.zsh-theme $HOME/.oh-my-zsh/themes/local.zsh-theme

if [ -e $HOME/.oh-my-zsh/themes/remote.zsh-theme ]; then
    mv -f $HOME/.oh-my-zsh/themes/remote.zsh-theme $HOME/.dotfiles/_old/remote.zsh-theme
    echo "move local theme"
fi
ln -s -f $HOME/.dotfiles/oh-my-zsh/themes/remote.zsh-theme $HOME/.oh-my-zsh/themes/remote.zsh-theme

