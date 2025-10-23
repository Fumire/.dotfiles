#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

mv -fv ~/.config/nvim ~/.config/nvim.bak
mv -fv ~/.local/share/nvim ~/.local/share/nvim.bak
mv -fv ~/.local/state/nvim ~/.local/state/nvim.bak
mv -fv ~/.cache/nvim ~/.cache/nvim.bak

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

