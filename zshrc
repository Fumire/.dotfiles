# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="custom"

plugins=(
git vi-mode sudo
)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='mvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

PATH=~/.dotfiles/bin:$PATH

stty -ixon

#if command -v tmux>/dev/null; then
#    if [[ ! $TERM =~ screen ]] && [ -z $TMUX ]; then
#        if tmux ls&>/dev/null; then
#            exec tmux attach-session -t $(tmux ls | tail -n 1 | awk '{ print $1 }')
#        else
#            exec tmux
#        fi
#    fi
#fi

# Python3
alias py='python3'

# PIP update
alias pip3Update="pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias pip2Update="pip2 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip2 install -U"

# common typos
alias claer='clear'
alias clera='clear'
alias celar='clear'
# prevent accident
alias rm='rm -i'
