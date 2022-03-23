# common typos
alias claer='clear'
alias clera='clear'
alias celar='clear'

# prevent accident
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Python3
alias py='python3'

# PIP update
alias pipUpdate="pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"

# Shortcuts
if [[ $(uname) == "Darwin" ]]; then
    alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
fi
weather() { curl -4 wttr.in/${1:-seoul} }
function gi() { curl -sLw n https://www.gitignore.io/api/$@ ;}
