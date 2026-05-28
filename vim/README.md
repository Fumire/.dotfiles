# Vim and Neovim Configuration

This directory contains the Vim configuration and shared editor tooling files. The Neovim Lua configuration lives in the sibling `nvim` directory, but both setups follow the same general editing preferences: 4-space indentation, relative line numbers, dark color schemes, OS clipboard integration, search highlighting, and no swap or backup files.

## Vim

The main Vim configuration is `vimrc`. It bootstraps `vim-plug`, installs the Jellybeans color scheme, and configures plugins for navigation, linting, formatting, buffers, comments, undo history, indentation guides, tags, CSV editing, and Python completion.

### `vimrc` Contents

| Area | Behavior |
| --- | --- |
| Encoding | Uses UTF-8 script and file encoding with `nobomb`. |
| Plugin bootstrap | Downloads `vim-plug` to `~/.vim/autoload/plug.vim` if it is missing, then attempts to install plugins and reload the Vim config. |
| Plugin list | Declares editor UI, navigation, Git, linting, formatting, completion, CSV, tag, and utility plugins through `plug#begin()` and `plug#end()`. |
| Color scheme | Downloads `jellybeans.vim` if it is missing, enables syntax highlighting, and sets `colorscheme jellybeans`. |
| CSV editing | Maps `<C-d>` to `:NewDelimiter` for `csv.vim`. |
| Compile command | Maps `<F12>` to `:SingleCompile` when that command is available. |
| Undotree | Maps `<F8>` to toggle the undo history tree. |
| NERDTree | Maps `<F9>` to toggle the file tree, opens it on the left, shows hidden files and line numbers, and ignores common generated files and folders. |
| Tagbar | Maps `<F10>` to toggle the tag sidebar. |
| Autoformat | Maps `<leader>af` to `:Autoformat` and defines formatter commands for C, C++, Java, JavaScript, Python, and Perl. |
| ALE linting | Configures ALE linters for Makefiles, Python, shell, R, and Vim script. Python uses `ruff` and `mypy`; ALE LSP and completion are disabled. |
| Indentation | Enables filetype plugins and indentation, uses smart indentation, and sets tabs to 4 spaces. |
| Retab rules | Converts tabs to spaces automatically for C, C++, and Python filetypes. |
| General editor UI | Enables wrapping, relative and absolute line numbers, command display, match highlighting, autoread, scroll offset, wildmenu completion, hidden buffers, visible whitespace, dark background, and terminal/window title updates. |
| File handling | Disables backup files, write backups, and swap files. Also sets binary mode and `noeol`. |
| Search | Enables case-insensitive search with smart-case behavior, highlighted matches, and incremental search. |
| Status line | Defines a compact status line showing cursor position, percent through file, flags, and full file path. |
| Clipboard and mouse | Uses the OS clipboard with `clipboard=unnamed` and enables mouse support when available. |
| Airline | Enables the airline tab line and configures buffer number display and separators. |
| Jedi | Disables rope integration and removes preview windows from Python completion options. |
| Buffers | Maps `<C-t>` to a new buffer, `<C-h>` and `<C-l>` to previous/next buffer navigation, and `<C-q>` to delete the previous buffer. |
| Extra commands | Adds `<Space>` to toggle search highlighting, split shortcuts under `<C-w>`, and a `:GetPDF` command that prints to PostScript and converts it to PDF with `ps2pdf`. |

### Vim Settings

The `set` commands in `vimrc` tune the default editing behavior:

| Setting | Meaning |
| --- | --- |
| `scriptencoding utf-8` and `set encoding=utf-8 nobomb` | Treats the Vim script and buffers as UTF-8 and avoids writing a byte-order mark. |
| `filetype indent plugin on` | Enables filetype detection, filetype-specific indentation, and filetype-specific plugin behavior. |
| `set autoindent` | Starts a new line with the same indentation as the previous line. |
| `set smartindent` | Adds basic language-aware indentation, especially for C-like blocks. |
| `set shiftwidth=4` | Uses 4 spaces for indentation commands such as `>>`, `<<`, and autoindent. |
| `set expandtab` | Inserts spaces when pressing Tab instead of literal tab characters. |
| `set tabstop=4` | Displays literal tab characters as 4 columns wide. |
| `set softtabstop=4` | Makes Tab and Backspace behave as if a tab is 4 spaces while editing. |
| `autocmd FileType c/cpp/py retab` | Converts existing tabs to spaces automatically for C, C++, and Python files. |
| `set wrap` and `set linebreak` | Wraps long visual lines at sensible break points instead of cutting words in the middle. |
| `set showbreak=...` | Shows a visible prefix on wrapped continuation lines. |
| `set ruler` | Shows the cursor position in the command area. |
| `set cursorline` for MacVim | Highlights the current line only when running GUI MacVim. |
| `set laststatus=2` | Always shows a status line. |
| `set showcmd` | Displays partially typed normal-mode commands. |
| `set showmatch` and `set matchtime=3` | Briefly highlights the matching bracket when typing a bracket. |
| `set autoread` | Reloads a file when it changes outside Vim, when Vim can do so safely. |
| `set scrolloff=3` | Keeps at least 3 screen lines visible above and below the cursor. |
| `set wildmenu` and `set wildmode=longest:full,full` | Improves command-line completion by showing a menu and completing to the longest shared match first. |
| `set noshowmode` | Hides the default mode text because the status line/plugin UI handles mode display. |
| `set relativenumber` and `set number` | Shows both relative line numbers and the absolute number for the current line. |
| `set hidden` | Allows switching away from modified buffers without writing them immediately. |
| `set wildignore+=...` | Excludes swap files, bytecode, cache folders, Git folders, and macOS metadata from command completion. |
| `set backspace=indent,eol,start` | Makes Backspace work across indentation, line breaks, and insertion start points. |
| `set list` and `set listchars=...` | Shows invisible characters such as tabs, trailing spaces, end-of-line markers, and non-breaking spaces. |
| `set background=dark` | Tells Vim to use dark-background color assumptions. |
| `set title` | Updates the terminal or GUI window title with the current file context. |
| `set binary` and `set noeol` | Avoids automatically adding an end-of-line marker, useful for preserving exact file endings. |
| `set nobackup`, `set nowritebackup`, and `set noswapfile` | Disables backup and swap files to avoid extra local files. |
| `set ignorecase` and `set smartcase` | Searches case-insensitively unless the search pattern includes uppercase letters. |
| `set hlsearch` and `set incsearch` | Highlights all search matches and updates search results while typing. |
| `set statusline=...` | Defines a compact status line with cursor position, file progress, file flags, and full path. |
| `set clipboard=unnamed` | Uses the operating system clipboard for yank, delete, change, and put operations. |
| `set mouse=a` | Enables mouse support in all modes when the Vim build supports mouse input. |

Notable Vim plugins include:

* [`airblade/vim-gitgutter`](https://github.com/airblade/vim-gitgutter) for Git change markers
* [`bling/vim-bufferline`](https://github.com/bling/vim-bufferline) for buffer display
* [`chrisbra/csv.vim`](https://github.com/chrisbra/csv.vim) for CSV editing
* [`Chiel92/vim-autoformat`](https://github.com/Chiel92/vim-autoformat) for code formatting
* [`ctrlpvim/ctrlp.vim`](https://github.com/ctrlpvim/ctrlp.vim) for fuzzy file navigation
* [`davidhalter/jedi-vim`](https://github.com/davidhalter/jedi-vim) for Python completion
* [`dense-analysis/ale`](https://github.com/dense-analysis/ale) for linting
* [`johngrib/vim-game-code-break`](https://github.com/johngrib/vim-game-code-break) for the Code Break Vim game
* [`majutsushi/tagbar`](https://github.com/majutsushi/tagbar) for tag navigation
* [`mbbill/undotree`](https://github.com/mbbill/undotree) for undo history
* [`scrooloose/nerdtree`](https://github.com/scrooloose/nerdtree) for file tree navigation
* [`tpope/vim-commentary`](https://github.com/tpope/vim-commentary) for comments
* [`vim-airline/vim-airline`](https://github.com/vim-airline/vim-airline) for the status line and tab line
* [`Yggdroot/indentLine`](https://github.com/Yggdroot/indentLine) for indentation guides

Common Vim key bindings:

* `<F8>` toggles Undotree
* `<F9>` toggles NERDTree
* `<F10>` toggles Tagbar
* `<F12>` runs SingleCompile when available
* `<C-d>` starts CSV delimiter selection
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

Package purpose:

| Package | Purpose |
| --- | --- |
| `autopep8` | Python formatter that applies PEP 8 style fixes. This is used by the Vim autoformat configuration. |
| `curl_cffi` | HTTP client package using libcurl bindings, useful when Python scripts need curl-like request behavior. |
| `flake8` | Python style and error checker. Useful as a general-purpose linting backend. |
| `matplotlib` | Plotting library for Python scripts and notebooks. |
| `mypy` | Static type checker for Python. This is configured in `vimrc` through ALE. |
| `neovim` | Python client package for Neovim integration. Useful for Python-based Neovim plugins/providers. |
| `numpy` | Core numerical array library used by many scientific Python packages. |
| `pandas` | Data analysis library for tabular data. |
| `python-language-server` | Legacy Python language server package. Kept for editor/language-server compatibility. |
| `ruff` | Fast Python linter. This is configured in `vimrc` through ALE with selected rule families. |
| `scikit-learn` | Machine learning library built on NumPy and SciPy. |
| `scipy` | Scientific computing library for numerical routines, optimization, statistics, and linear algebra. |
| `seaborn` | Statistical plotting library built on matplotlib. |
| `tqdm` | Progress bar utility for Python scripts. |
| `vim-vint` | Vim script linter. This is configured in `vimrc` through ALE for Vim files. |
