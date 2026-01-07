# prevent accident
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Python3
alias py="python3"

# PIP update
alias pipUpdate="pip3 install -U pip wheel && pip3 freeze --local | grep -v '^\-e' | grep -v '@' | cut -d = -f 1 | xargs -n1 pip3 install -U"

# yt-dlp
if [[ $(uname) == "Darwin" ]]; then
    alias yt-dlp="python3 -m yt_dlp"
fi

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

# Make .gitignore
function gi() { curl -sL "https://www.gitignore.io/api/$@" ;}

# Background execute
function bkr() { (nohup "$@" 1>"$(uuid)" 2>&1 &) ;}

# Count files & directories
function count() { printf '%s\n' "$#" ;}
