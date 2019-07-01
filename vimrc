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

if v:version < 705
    Plug 'vim-scripts/AutoComplPop'
else
    Plug 'Valloric/YouCompleteMe'
endif
Plug 'tmux-plugins/vim-tmux'
Plug 'StanAngeloff/php.vim', {'for': 'php'}
Plug 'jalvesaq/Nvim-R', {'for': ['r', 'R']}
Plug 'plasticboy/vim-markdown', {'for': ['md', 'markdown']}
Plug 'pangloss/vim-javascript', {'for': 'js'}

Plug 'johngrib/vim-game-code-break'
call plug#end()

if empty(glob("~/.vim/colors/jellybeans.vim"))
    silent !curl --form --location --output ~/.vim/colors/jellybeans.vim --create-dirs https://raw.githubusercontent.com/nanotech/jellybeans.vim/master/colors/jellybeans.vim
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
map <silent> <F9> :NERDTreeToggle <Return>
let NERDTreeQuitOnOpen = 1
let NERDTreeShowHidden = 1
let NERDTreeWinPos = "left"
let NERDTreeIgnore = ['\.pyc$', '\.swp$', '\.git$']
let NERDTreeShowLineNumbers = 1

" Tagbar settings
map <silent> <F10> :TagbarToggle <Return>

" autoformat settings
nnoremap <silent> <leader>af :Autoformat <Return>
let g:formatdef_my_astyle = '"astyle --style=bsd --indent=spaces=4 --indent-preproc-block --indent-preproc-define --indent-col1-comments --pad-oper --pad-comma --unpad-paren --break-closing-braces --add-braces --attach-return-type --align-pointer=type --delete-empty-lines --add-one-line-braces --align-reference=type --break-blocks"'
let g:formatters_java = ['my_astyle']
let g:formatters_cpp = ['my_astyle']
let g:formatters_c = ['my_astyle']
let g:formatdef_my_autopep8 = '"autopep8 --ignore E501"'
let g:formatters_python = ['my_autopep8']
let g:syntastic_python_flake8_args = "--ignore=E501"
let g:formatters_perl = ['perltidy']
autocmd FileType vim,tex let g:autoformat_autoindent=0

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
set matchtime=3
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
set list
set background=dark
set title

" bakcup settings
set nobackup
set nowritebackup
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
nnoremap <C-t> :enew <Return>
nnoremap <silent> <C-h> :bprevious <Return>
nnoremap <silent> <C-l> :bnext <Return>
nnoremap <silent> <C-q> :bprevious <BAR> bdelete #<Return>

" keymap
nnoremap <silent> <SPACE> :nohl <Return>
nnoremap <C-w>m :split 
nnoremap <C-w>l :vsplit 
