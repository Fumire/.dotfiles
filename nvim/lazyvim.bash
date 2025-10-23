#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

folders=("$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim")

for folder in ${folders["$@"]}; do
    if [[ -e ${folder} ]]; then
        mv -fv "${folder}" "${folder}.bak"
    fi
done

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

files=("$HOME/.config/nvim/stylua.toml" "$HOME/.config/nvim/lua/config/*.lua" "$HOME/.config/nvim/lua/plugins/plugin.lua")
for file in ${files["$@"]}; do
    rm -fv "${file}"
done

make all
