# Vim and Neovim Configuration

This directory contains the Vim configuration and shared editor tooling files. The Neovim Lua configuration lives in the sibling `nvim` directory, but both setups follow the same general editing preferences: 4-space indentation, relative line numbers, dark color schemes, OS clipboard integration, search highlighting, and no swap or backup files.

## Vim

The main Vim configuration is `vimrc`. It bootstraps `vim-plug`, installs the Jellybeans color scheme, and configures plugins for navigation, linting, formatting, buffers, comments, undo history, indentation guides, tags, CSV editing, and Python completion.

Notable Vim plugins include:

* `vim-airline/vim-airline` for the status line and tab line
* `scrooloose/nerdtree` for file tree navigation
* `airblade/vim-gitgutter` for Git change markers
* `Chiel92/vim-autoformat` for code formatting
* `dense-analysis/ale` for linting
* `tpope/vim-commentary` for comments
* `mbbill/undotree` for undo history
* `majutsushi/tagbar` for tag navigation
* `chrisbra/csv.vim` for CSV editing
* `davidhalter/jedi-vim` for Python completion

Common Vim key bindings:

* `<F8>` toggles Undotree
* `<F9>` toggles NERDTree
* `<F10>` toggles Tagbar
* `<leader>af` runs Autoformat
* `<C-t>` opens a new buffer
* `<C-h>` and `<C-l>` move between buffers
* `<C-q>` deletes the previous buffer
* `<Space>` toggles search highlighting
* `<C-w>m` creates a horizontal split
* `<C-w>l` creates a vertical split

## Neovim

Neovim configuration is maintained in `../nvim`.

The Neovim setup uses `lazy.nvim` and LazyVim. The main files are:

* `../nvim/lazy.lua`: bootstraps `lazy.nvim` and loads LazyVim
* `../nvim/plugin.lua`: adds or overrides plugins, including Gruvbox, Telescope, Pyright, Treesitter parsers, Mason tools, ALE, NERDTree, Tagbar, CSV support, and Vim Autoformat
* `../nvim/options.lua`: editor options such as indentation, clipboard, line numbers, wrapping, search, backup, and status line settings
* `../nvim/keymaps.lua`: custom key bindings for splits and buffer navigation
* `../nvim/autocmds.lua`: automatic reload and split-resize behavior
* `../nvim/stylua.toml`: formatting rules for Lua configuration files

The `init.vim` file in this directory is a compatibility entry point for Neovim setups that want to reuse `~/.vimrc`. It extends the runtime path to Vim directories, sources `~/.vimrc`, and configures TabNine.

## Installation

From the repository root, run the default target to install the main Vim configuration:

```sh
make
```

Or install only the Vim config:

```sh
make vim_run
```

This symlinks:

* `vim/vimrc` -> `~/.vimrc`

To install additional Vim-related tooling configuration, run:

```sh
make -C vim
```

This symlinks:

* `vim/style.yapf` -> `~/.style.yapf`
* `vim/TabNine.toml` -> `~/Library/Preferences/TabNine/TabNine.toml`
* `vim/tabnine_config.json` -> `~/Library/Preferences/TabNine/tabnine_config.json`

To install the Neovim Lua configuration, create the expected config directories and run the Neovim Makefile:

```sh
mkdir -p ~/.config/nvim/lua/config ~/.config/nvim/lua/plugins
make -C nvim
```

This symlinks the files in `nvim` into `~/.config/nvim`.

## Optional Python Tools

The `requirements.txt` file lists Python packages used by the Vim and Neovim linting, formatting, and data-science workflow. Install them only when you need those integrations:

```sh
pip install -r vim/requirements.txt
```
