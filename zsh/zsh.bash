#!/usr/bin/env bash
if [ -e /bin/zsh ]; then
    if [ "$(echo $SHELL)" != "$(which zsh)" ]; then
        chsh -s $(which zsh)
        echo "change SHELL to zsh"
    fi
elif [ -e /usr/local/bin/zsh ]; then
    echo "export SHELL=/usr/local/bin/zsh\nexec /usr/local/bin/zsh -l" >> $HOME/.bash_profile
    source $HOME/.bash_profile
else
    if [ ! -e $HOME/bin/zsh ]; then
        curl --output $HOME/zsh.tar.xz -L https://sourceforge.net/projects/zsh/files/latest/download
        cd $HOME && mkdir zsh && unxz zsh.tar.xz && tar -xvf zsh.tar -C zsh --strip-components 1
        cd $HOME/zsh && ./configure --prefix $HOME && make -j && make -j install
    fi
    echo "export SHELL=$HOME/bin/zsh" >> $HOME/.bash_profile
    echo "[ -z \"\$ZSH_VERSION\" ] && exec \"\$SHELL\" -l" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
