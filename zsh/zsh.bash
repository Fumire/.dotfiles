#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [[ -e ${HOME}/.zshenv ]]; then
    mv -vf "${HOME}/.zshenv" "${HOME}/.zshenv.bak"
fi
ln -sv "$(realpath ./zshenv)" "${HOME}/.zshenv"

if [[ -e ${HOME}/.zshrc ]]; then
    mv -vf "${HOME}/.zshrc" "${HOME}/.zshrc.bak"
fi
ln -sv "$(realpath ./zshrc)" "${HOME}/.zshrc"

if [[ -e ${HOME}/.alias.zsh ]]; then
    mv -vf "${HOME}/.alias.zsh" "${HOME}/.alias.zsh.bak"
fi
ln -sv "$(realpath ./alias.zsh)" "${HOME}/.alias.zsh"
