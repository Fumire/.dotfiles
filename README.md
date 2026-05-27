# .dotfiles

Personal dotfiles for setting up a familiar shell, editor, Git, tmux, and macOS/Ubuntu development environment. The Makefile symlinks tracked configuration files into the home directory so a new machine can be brought up quickly.

## Required
* make
* zsh & oh-my-zsh
* (neo)vim

## Usage
### Ubuntu
I tested on Ubuntu (latest):
[![Ubuntu CI](https://github.com/Fumire/.dotfiles/actions/workflows/ubuntu.yml/badge.svg?branch=master)](https://github.com/Fumire/.dotfiles/actions/workflows/ubuntu.yml)

In Ubuntu, you can start my .dotfiles with `make` command.

### macOS
Also, on macOS (latest):
[![macOS CI](https://github.com/Fumire/.dotfiles/actions/workflows/mac.yml/badge.svg)](https://github.com/Fumire/.dotfiles/actions/workflows/mac.yml)

In macOS, you can start my .dotfiles with `make mac_run` command.

## Acknowledgement
[Kojandy/.dotfiles](https://github.com/kojandy/.dotfiles)
