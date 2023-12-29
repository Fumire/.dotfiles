# common typos
alias claer="clear"
alias clera="clear"
alias celar="clear"

# prevent accident
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Python3
alias py="python3"

# PIP update
alias pipUpdate="pip3 install -U pip wheel && pip3 freeze --local | grep -v "^\-e" | grep -v "@" | cut -d = -f 1 | xargs -n1 pip3 install -U"

# Neovim
if [[ $(uname) == "Darwin" ]]; then
    alias vim="nvim"
    alias vi="nvim"
    alias vimdiff="nvim -d"
fi

# Shortcuts
if [[ $(uname) == "Darwin" ]]; then
    alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
fi

function weather() { curl "https://wttr.in/${@:-seoul}?m" ;}

function gi() { curl -sL "https://www.gitignore.io/api/$@" ;}

function cheat() { curl "https://cheat.sh/$@" ;}
