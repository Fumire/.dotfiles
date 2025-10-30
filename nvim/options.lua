-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local g = vim.g
local opt = vim.opt

-- Autoformat
g.autoformat = false
g.formatdef_my_astyle = "'astyle --style=bsd --indent=spaces=4 --indent-preproc-block --indent-preproc-define --indent-col1-comments --pad-oper --pad-comma --unpad-paren --break-closing-braces --add-braces --attach-return-type --align-pointer=type --delete-empty-lines --add-one-line-braces --align-reference=type --break-blocks'"
g.formatters_java = { "my_astyle" }
g.formmaters_cpp = { "my_astyle" }
g.formatters_c = { "my_astyle" }
g.formatdef_my_js = "'js-beautify --space-in-paren --space-after-anon-function --space-after-named-function --brace-style none';"
g.formatters_js = { "my_js" }
g.formatdef_my_autopep8 = "'autopep8 --ignore E501 --aggressive --aggressive -'"
g.formatters_python = { "my_autopep8" }

-- IndentLine settings
g.indentLine_char_list = { "|", "¦", "┆", "┊" }

-- General settings
g.mapleader = " "
g.maplocalleader = "\\"
opt.encoding = "utf-8"

-- Clipboard
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

-- Indent and tab settings
opt.autoindent = true
opt.smartindent = true
opt.shiftwidth = 4
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4

opt.wrap = true
opt.linebreak = true
opt.showbreak = "·····"
opt.ruler = true
opt.cursorline = true
opt.laststatus = 2
opt.showcmd = true
opt.showmatch = true
opt.autoread = true
opt.scrolloff = 3
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.showmode = false
opt.relativenumber = true
opt.number = true
opt.hidden = true
opt.backspace = "indent,eol,start"
opt.list = true
opt.listchars = "tab:⇥ ,trail:·,precedes:«,extends:»,eol:¶,nbsp:_"
opt.background = "dark"
opt.title = true
opt.eol = false
opt.fillchars = {
    foldopen = "",
    foldclose = "",
    fold = " ",
    foldsep = " ",
    diff = "╱",
    eob = " ",
}

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Backup settings
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Status line settings
opt.statusline = "\\ %<%l:%v\\ [%P]%=%a\\ %h%m%r\\ %F\\"
