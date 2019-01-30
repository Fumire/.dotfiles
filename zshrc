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

export TERM='screen-256color'
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

PATH=~/.dotfiles/bin:$PATH

stty -ixon

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
alias mv='mv -i'
alias cp='cp -i'

# multiple line command
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
