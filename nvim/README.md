# Neovim Configuration

LazyVim-based Neovim configuration for this dotfiles repository. This folder stores local configuration overrides and plugin specs; it expects the standard LazyVim starter layout under `~/.config/nvim`.

## Files

* `lazy.lua`: bootstraps `lazy.nvim`, loads LazyVim, imports local plugin specs, and enables periodic plugin update checks.
* `plugin.lua`: custom plugin list and overrides, including Gruvbox, Telescope settings, Pyright, Treesitter parsers, Mason tools, ALE, NERDTree, Vim Autoformat, bufferline, indent guides, Tagbar, and CSV support.
* `options.lua`: editor preferences for indentation, clipboard, wrapping, line numbers, search, backup behavior, list characters, and status line formatting.
* `keymaps.lua`: custom key bindings for splits and buffer navigation.
* `autocmds.lua`: automatic file reload checks and split resizing after window size changes.
* `stylua.toml`: Lua formatting rules for Neovim config files.
* `lazyvim.bash`: helper script for bootstrapping a LazyVim starter configuration.

## Requirements

* Neovim
* git
* make
* Internet access on first launch so `lazy.nvim`, LazyVim, and plugins can be downloaded

Some language tools are managed by Mason after Neovim starts. This config asks Mason to install `stylua`, `shellcheck`, `shfmt`, and `flake8`.

## Installation

For a fresh LazyVim setup, install the LazyVim starter first, then link this repository's overrides:

```sh
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
make -C nvim
```

Run the commands from the repository root. The `make -C nvim` command creates these symbolic links:

* `nvim/stylua.toml` -> `~/.config/nvim/stylua.toml`
* `nvim/autocmds.lua` -> `~/.config/nvim/lua/config/autocmds.lua`
* `nvim/keymaps.lua` -> `~/.config/nvim/lua/config/keymaps.lua`
* `nvim/lazy.lua` -> `~/.config/nvim/lua/config/lazy.lua`
* `nvim/options.lua` -> `~/.config/nvim/lua/config/options.lua`
* `nvim/plugin.lua` -> `~/.config/nvim/lua/plugins/plugin.lua`

The Makefile creates parent directories as needed. If a target file already exists and is not a symlink, it is backed up with a `.bak.YYYYmmddHHMMSS` suffix before linking.

If `~/.config/nvim` already exists as a full configuration tree, review it before cloning the LazyVim starter. The backup behavior applies to individual linked files, not to the whole configuration directory.

## First Launch

After installation, start Neovim:

```sh
nvim
```

On first launch, `lazy.lua` downloads `lazy.nvim` if needed, then LazyVim installs the configured plugins. Use `:Lazy` to inspect plugin status and `:Mason` to inspect external tools.

## Key Bindings

Custom key bindings added by this config:

* `<C-w>m`: horizontal split
* `<C-w>l`: vertical split
* `<C-t>`: new buffer
* `<C-h>`: previous buffer
* `<C-l>`: next buffer
* `<C-q>`: delete buffer
* `<F2>`: run Autoformat
* `<F9>`: toggle NERDTree
* `<F10>`: toggle Tagbar
* `<C-d>`: start CSV delimiter selection
* `<leader>fp`: find plugin files with Telescope

## Notes

This directory does not include a standalone `init.lua`. The LazyVim starter provides the entry point that loads `lua/config/lazy.lua`, so use the starter layout for new machines.
