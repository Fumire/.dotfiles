" plug settings
if empty(glob("~/.vim/autoload/plug.vim"))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall | source $MYVIMRC
endif
call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'tpope/vim-fugitive'
Plug 'bling/vim-bufferline'
Plug 'airblade/vim-gitgutter'
Plug 'Chiel92/vim-autoformat'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
"Plug 'int3/vim-taglist-plus'
Plug 'johngrib/vim-game-code-break'
Plug 'vim-scripts/AutoComplPop'
call plug#end()

" START - Setting up Vundle - the vim plugin bundler
"let iCanHazVundle=1
"let vundle_readme=expand('~/.vim/bundle/Vundle.vim/README.md')
"if !filereadable(vundle_readme)
"    echo "Installing Vundle.."
"    echo ""
"    silent !mkdir -p ~/.vim/bundle
"    silent !git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
"    let iCanHazVundle=0
"endif
"set rtp+=~/.vim/bundle/Vundle.vim/
"call vundle#rc()
" let Vundle manage Vundle, required
"Plugin 'VundleVim/Vundle.vim'
"if iCanHazVundle == 0
"    echo "Installing Bundles, please ignore key map error messages"
"    echo ""
"    :PluginInstall
"endif
" END - Setting up Vundle - the vim plugin bundler
"call vundle#begin()
"call vundle#end()
"filetype plugin indent on

" syntax highlight
if empty(glob("~/.vim/colors/jellybeans.vim"))
    silent !curl -fLo ~/.vim/colors/jellybeans.vim --create-dirs https://raw.githubusercontent.com/nanotech/jellybeans.vim/master/colors/jellybeans.vim
endif
syntax on
colorscheme jellybeans

" Nerdtree settings
map <F9> :NERDTreeToggle<cr>
let NERDTreeQuitOnOpen=1
let NERDTreeShowHidden=1
let NERDTreeWinPos = "left"
let NERDTreeIgnore = ['\.pyc$']

" TagList settings
map <F10> :TlistToggle<cr>

" airline settings

" autoformat settings
let g:formatdef_astyle = '"astyle -A2SLYMpHjoxC200"'
let g:formatters_java = ['astyle']
let g:formatters_cpp = ['astyle']
let g:formatters_c = ['astyle']
let g:formatters_python = ['autopep8']

" indent and tab settings
filetype indent plugin on
set autoindent
set smartindent
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab

" change Tab to Space
autocmd FileType c retab
autocmd FileType py retab
autocmd FileType java retab
autocmd FileType clojure retab

" general settings
set nowrap
set ruler
set laststatus=2
set showcmd
set showmatch
set showmode
set autoread
set scrolloff=3
set wildmenu
set wildmode=longest:full,full
set noshowmode
set relativenumber
set number
set hidden
set wildignore+=*.swp,*.pyc,*.zip,venv,.git
set backspace=indent,eol,start
set wmnu
set wrap

" search settings
set ignorecase
set smartcase
set hlsearch
set incsearch

set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\

if has('mouse')
    set mouse=a
endif

" autocmd settings
" autocmd BufWrite * :Autoformat

" keymap
let mapleader=','
noremap <silent> <SPACE> :nohl<CR>
nmap <silent> <leader>af :Autoformat<CR>

" fugitive
nmap <silent> <leader>gs :Gstatus<CR>
nmap <silent> <leader>gc :Gcommit<CR>
nmap <silent> <leader>gw :Gwrite<CR>
nmap <silent> <leader>gd :Gdiff<CR>
nmap <silent> <leader>ge :Gedit<CR>
nmap <silent> <leader>gb :Gblame<CR>
nmap <silent> <leader>gp :Gpush<CR>
nmap <silent> <leader>gl :Gpull<CR>
