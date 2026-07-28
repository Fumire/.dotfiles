# prevent accident
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Python3
alias py="python3"

# PIP update
alias pipUpdate="pip3 freeze --local | grep -v '^\-e' | grep -v '@' | cut -d = -f 1 | xargs -n1 pip3 install -U"

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
    function copyssh() {
        local key_path

        for key_path in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
            if [[ -f "$key_path" ]]; then
                pbcopy < "$key_path"
                return
            fi
        done

        printf '%s\n' "copyssh: no public SSH key found at ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub" >&2
        return 1
    }
fi

function weather() {
    local location="${*:-seoul}"
    local pattern="^[A-Za-z0-9._+-]+$"

    location="${location// /+}"

    if [[ -z "$location" ]]; then
        echo "weather: location argument cannot be empty" >&2
        return 1
    fi

    if [[ ! "$location" =~ $pattern ]]; then
        echo "weather: location has invalid characters" >&2
        return 1
    fi

    curl --proto '=https' --tlsv1.2 --silent --show-error --location --connect-timeout 5 --max-time 15 --fail \
         "https://wttr.in/${location}?m"
}

# Make .gitignore
function gi() {
    local template
    local templates=""
    local pattern='^[A-Za-z0-9.,_+-]+$'

    if (( $# == 0 )); then
        echo "gi: usage: gi <template>[,<template> ...]" >&2
        return 1
    fi

    for template in "$@"; do
        if [[ ! "$template" =~ $pattern ]]; then
            echo "gi: template contains invalid characters: $template" >&2
            return 1
        fi

        if [[ -n "$templates" ]]; then
            templates+=","
        fi
        templates+="$template"
    done

    curl --proto '=https' --tlsv1.2 --silent --show-error --location --connect-timeout 5 --max-time 15 --fail \
         "https://www.gitignore.io/api/${templates}"
}

# Background execute
function bkr() { (nohup "$@" 1>"$(uuid)" 2>&1 &) ;}

# Count files & directories
function count() { printf '%s\n' "$#" ;}
