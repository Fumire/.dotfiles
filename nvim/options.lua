-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local keyset = vim.keymap.set
local opt = vim.opt

-- Autoformat
vim.g.autoformat = true
vim.g.formatdef_my_astyle =
    "'astyle --style=bsd --indent=spaces=4 --indent-preproc-block --indent-preproc-define --indent-col1-comments --pad-oper --pad-comma --unpad-paren --break-closing-braces --add-braces --attach-return-type --align-pointer=type --delete-empty-lines --add-one-line-braces --align-reference=type --break-blocks'"
vim.g.formatters_java = { "my_astyle" }
vim.g.formmaters_cpp = { "my_astyle" }
vim.g.formatters_c = { "my_astyle" }
vim.g.formatdef_my_js =
    "'js-beautify --space-in-paren --space-after-anon-function --space-after-named-function --brace-style none';"
vim.g.formatters_js = { "my_js" }
vim.g.formatdef_my_autopep8 = "'autopep8 --ignore E501 --aggressive --aggressive -'"
vim.g.formatters_python = { "my_autopep8" }

-- IndentLine settings
vim.g.indentLine_char_list = { "|", "¦", "┆", "┊" }

-- COC settings
local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }
keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)

-- ALE settings

-- General settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
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
