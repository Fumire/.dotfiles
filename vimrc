" plug settings
if empty(glob("~/.vim/autoload/plug.vim"))
	silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall | source $MYVIMRC
endif
call plug#begin()
Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'

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

Plug 'majutsushi/tagbar' " Replace right below
" Plug 'int3/vim-taglist-plus'

Plug 'vim-scripts/AutoComplPop'
Plug 'StanAngeloff/php.vim'
Plug 'johngrib/vim-game-code-break'
call plug#end()

if empty(glob("~/.vim/colors/jellybeans.vim"))
	silent !curl -fLo ~/.vim/colors/jellybeans.vim --create-dirs https://raw.githubusercontent.com/nanotech/jellybeans.vim/master/colors/jellybeans.vim
endif
syntax on
colorscheme jellybeans

" Nerdtree settings
map <F9> :NERDTreeToggle <Return>
let NERDTreeQuitOnOpen = 1
let NERDTreeShowHidden = 1
let NERDTreeWinPos = "left"
let NERDTreeIgnore = ['\.pyc$', '\.swp$', '\.git$']
let NERDTreeShowLineNumbers = 1

" Tag settings
map <F10> :TagbarToggle <Return>

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
set expandtab
set tabstop=4
set softtabstop=4

" change Tab to Space
autocmd FileType c retab
autocmd FileType cpp retab
autocmd FileType py retab
autocmd FileType java retab
autocmd FileType clojure retab

" general settings
set wrap
set linebreak
set showbreak=···
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

if has('macunix')
	set listchars=tab:⇥\ ,trail:·,precedes:«,extends:»,eol:¶
else
	set listchars=tab:-\ ,trail:_,precedes:<,extends:>,eol:$
endif

" search settings
set ignorecase
set smartcase
set hlsearch
set incsearch
set showcmd
set mps+=<:>

" status line settings
set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\

if has('mouse')
	set mouse=a
endif

" airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep =''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'
nnoremap <C-t> :enew<Return>
nnoremap <C-h> :bprevious<Return>
nnoremap <C-l> :bnext<Return>
nnoremap <C-q> :bp <BAR> bd #<Return>

" keymap
noremap <silent> <SPACE> :nohlsearch<Return>
nnoremap <silent> <leader>af :Autoformat<Return>
nnoremap <C-w>m :split 
nnoremap <C-w>l :vsplit 
