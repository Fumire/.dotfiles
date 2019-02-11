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
Plug 'mbbill/undotree'
Plug 'Yggdroot/indentLine'
Plug 'scrooloose/nerdcommenter'
Plug 'majutsushi/tagbar'
Plug 'xuhdev/SingleCompile'

Plug 'mtth/scratch.vim'
Plug 'chrisbra/csv.vim'
Plug 'tmux-plugins/vim-tmux'

Plug 'Valloric/YouCompleteMe'
Plug 'StanAngeloff/php.vim', {'for': 'php'}

Plug 'johngrib/vim-game-code-break'
call plug#end()

if empty(glob("~/.vim/colors/jellybeans.vim"))
    silent !curl -fLo ~/.vim/colors/jellybeans.vim --create-dirs https://raw.githubusercontent.com/nanotech/jellybeans.vim/master/colors/jellybeans.vim
endif
if has('syntax')
    syntax on
endif
colorscheme jellybeans

" CSV settings
map <C-d> :NewDelimiter 

" YouCompleteMe settings
let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
let g:ycm_key_list_stop_completion = ['<C-y>', '<Return>']
let g:ycm_collect_identifiers_from_tags_files = 1

" SingleCompile settings
map <F12> :SingleCompile <Return>

" scratch settings
let g:scratch_persistence_file = '/tmp/scratch_persistence_file.txt'
let g:scratch_autohide = 0

" Nerdtree settings
map <F9> :NERDTreeToggle <Return>
let NERDTreeQuitOnOpen = 1
let NERDTreeShowHidden = 1
let NERDTreeWinPos = "left"
let NERDTreeIgnore = ['\.pyc$', '\.swp$', '\.git$']
let NERDTreeShowLineNumbers = 1

" Tagbar settings
map <F10> :TagbarToggle <Return>

" autoformat settings
let g:formatdef_astyle = '"astyle -A2SLYMpHjoxC200"'
let g:formatters_java = ['astyle']
let g:formatters_cpp = ['astyle']
let g:formatters_c = ['astyle']
let g:formatters_python = ['autopep8']
let g:syntastic_python_flake8_args = "--ignore=E501"

" indent and tab settings
filetype indent plugin on
set autoindent
set smartindent
set shiftwidth=4
set expandtab
set tabstop=4
set softtabstop=4

" change Tab to Space
autocmd FileType c retab
autocmd FileType cpp retab
autocmd FileType py retab

" general settings
set wrap
set linebreak
set showbreak=·····
set ruler
set cursorline
set laststatus=2
set showcmd
set showmatch
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
set list
set noswapfile

set listchars=tab:⇥\ ,trail:·,precedes:«,extends:»,eol:¶

" search settings
set ignorecase
set smartcase
set hlsearch
set incsearch
set showcmd
set mps+=<:>

" status line settings
set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\

" use OS clipboard
set clipboard=unnamed

if has('mouse')
    set mouse=a
endif

" airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'
nnoremap <C-t> :enew<Return>
nnoremap <C-h> :bprevious<Return>
nnoremap <C-l> :bnext<Return>
nnoremap <C-q> :bprevious <BAR> bdelete #<Return>

" keymap
nnoremap <silent> <SPACE> :nohl<Return>
nnoremap <silent> <leader>af :Autoformat<Return>
nnoremap <C-w>m :split
nnoremap <C-w>l :vsplit
