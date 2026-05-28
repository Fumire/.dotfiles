# .dotfiles

Personal dotfiles for setting up a familiar shell, editor, Git, tmux, and macOS/Ubuntu development environment. The Makefile symlinks tracked configuration files into the home directory so a new machine can be brought up quickly.

## Table of Contents

* [Required](#required)
* [Installation](#installation)
* [Optional Components](#optional-components)
* [macOS](#macos)
* [Ubuntu](#ubuntu)
* [Acknowledgement](#acknowledgement)

## Required
* make
* git
* curl
* zsh
* (neo)vim

## Installation

Clone this repository and run the Makefile from the repository root.

```sh
git clone https://github.com/Fumire/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make
```

The default `make` target installs the core shell and Vim configuration:

* Symlinks `zsh/zshenv` to `~/.zshenv`
* Symlinks `zsh/zshrc` to `~/.zshrc`
* Symlinks `zsh/alias.zsh` to `~/.alias.zsh`
* Installs oh-my-zsh if `~/.oh-my-zsh` is missing
* Installs the `zsh-syntax-highlighting` oh-my-zsh plugin
* Symlinks local oh-my-zsh themes into `~/.oh-my-zsh/themes`
* Symlinks `vim/vimrc` to `~/.vimrc`

The installer uses symbolic links, so changes in this repository are reflected in your home directory. When a target file already exists and is not a symlink, the Makefiles back it up with a `.bak.YYYYmmddHHMMSS` suffix before linking.

## Optional Components

Install additional configuration targets as needed:

```sh
make tmux_run
make git_run
make gnupg_run
make -C nvim
make -C vim
make -C zsh
```

These commands install the following files:

* `make tmux_run`: symlinks `~/.tmux.conf` and `~/.tmux.conf.local`
* `make git_run`: symlinks `~/.gitconfig` and `~/.gitignore_global`
* `make gnupg_run`: symlinks GnuPG config files and restarts `gpg-agent`
* `make -C nvim`: symlinks Neovim config files under `~/.config/nvim`
* `make -C vim`: symlinks Vim-related tooling config such as YAPF and TabNine files
* `make -C zsh`: symlinks `~/.zlogout`

### macOS

On macOS, install Homebrew first if it is not already available, then run:

```sh
make mac_run
```

This runs `brew bundle` with `mac/Brewfile.free` to install the free Homebrew packages listed there. The macOS CI workflow checks the latest macOS environment:
[![macOS CI](https://github.com/Fumire/.dotfiles/actions/workflows/mac.yml/badge.svg)](https://github.com/Fumire/.dotfiles/actions/workflows/mac.yml)

### Ubuntu

On Ubuntu, install the required packages first, then run the default target:

```sh
make
```

The Ubuntu CI workflow checks the latest Ubuntu environment:
[![Ubuntu CI](https://github.com/Fumire/.dotfiles/actions/workflows/ubuntu.yml/badge.svg?branch=master)](https://github.com/Fumire/.dotfiles/actions/workflows/ubuntu.yml)

## Acknowledgement
[Kojandy/.dotfiles](https://github.com/kojandy/.dotfiles)
