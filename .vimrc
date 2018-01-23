" Felipe "Valdes' .vimrc

set nocompatible
filetype on

set encoding=utf-8

"Force Vim to source .vimrc if present:
set exrc
"Since Vim will source .vimrc from any directory you run Vim from, this is a
"potential security hole; the following command will oimpose restrictions:
set secure
"Enable syntax highlighting:
syntax enable
"Column @ 100 characters:
set colorcolumn=100
highlight ColorColumn ctermbg=White


set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
set splitbelow
set splitright
set backspace=2		" Backspace deletes like most programs in insert mode
set updatetime=250

"Split navigations:
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"Enable folding:
set foldmethod=indent
set foldlevel=99
set foldenable
set autoindent
set confirm

" Enable mouse in all modes
set mouse=a
" Disable error bells
set noerrorbells
" Don’t reset cursor to start of line when moving around.
set nostartofline
" Don’t show the intro message when starting Vim
set shortmess=atI
" Show the (partial) command as it’s being typed
set showcmd
" Allow mouse to work properly with tmux:
set ttymouse=xterm2

" Show line number
set number
"set relativenumber
set numberwidth=5

" Start scrolling three lines before the horizontal window border
set scrolloff=3
" Set ruler:
if has('cmdline_info')
  set ruler        " Show the ruler
  set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " A ruler on steroids
endif

" Better command-line completion
set wildmenu

" Highlight searches:
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,
  \.sass-cache,*.class,*.scssc,*.cssc,sprockets%*,*.lessc
set ignorecase
set smartcase
set showmatch

" Backgound color fix for tmux + vim:
if &term =~ '256color'
    " disable Background Color Erase (BCE) so that color schemes
    " render properly when inside 256-color tmux and GNU screen.
    " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
    set t_ut=
endif

" Centralize backups, swapfiles and undo history
set backupdir=~/.vim/backups
set directory=~/.vim/swaps
if exists("&undodir")
	set undodir=~/.vim/undo
endif

" Switch between buffers:
nnoremap <F5> :buffers<CR>:buffer<Space> 


"=============================================================================
" Plugins managed by vundle:
"=============================================================================
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Let Vundle manage Vundle (required):
Plugin 'VundleVim/Vundle.vim'

" Colors :
Plugin 'altercation/vim-colors-solarized'
set background=dark
let g:solarized_termcolors = 256
let g:solarized_visibility = "high"
let g:solarized_contrast = "high"
"--------------------------------------
Plugin 'nanotech/jellybeans.vim'
let g:jellybeans_overrides = {
\    'background': { 'ctermbg': 'none', '256ctermbg': 'none' },
\}
"--------------------------------------
Plugin 'tomasr/molokai'
let g:rehash256 = 1
"--------------------------------------
Plugin 'tomasiser/vim-code-dark'
"-------------------------------------

"File-tree :
Plugin 'The-NERD-tree', { 'on':'NERDTreeToggle' }
map <C-n> :NERDTreeToggle<CR>
let NERDTreeIgnore=['\.pyc$', '\.swp$', '\~$']
let g:NERDTreeMouseMode = 2  " Single-click to expand the directory, double-click to open the file

"Git in File-tree:
Plugin 'Xuyuanp/nerdtree-git-plugin'

"Fold code by indentation:
Plugin 'tmhedberg/SimpylFold'

"Indentation marker (vertical lines):
Plugin 'Yggdroot/indentLine'
let g:indentLine_char = '┊'
let g:indentLine_showFirstIndentLevel = 1

"Git Integration : 
Plugin 'tpope/vim-fugitive'

"Show git diff in the gutter (sign column):
Plugin 'airblade/vim-gitgutter'

"Lean & mean status/tabline
Plugin 'vim-airline/vim-airline'
let g:airline_powerline_fonts = 1
let g:airline_inactive_collapse = 0 		 " Do not collapse the status line while having multiple windows
let g:airline#extensions#whitespace#enabled = 0	 " Do not check for whitespaces
let g:airline#extensions#tabline#enabled = 1     " Display tab bar with buffers
let g:airline#extensions#branch#enabled = 1      " Enable Git client integration
let g:airline#extensions#tagbar#enabled = 1      " Enable Tagbar integration
let g:airline#extensions#hunks#enabled = 1       " Enable Git hunks integration

"C/C++ completion:
Plugin 'Valloric/YouCompleteMe'
let g:ycm_confirm_extra_conf = 0
let g:ycm_min_num_of_chars_for_completion = 99 " Keeps the as-you-type pop-up silent
" let s:omnifunc_mode = 0
let g:ycm_error_symbol = 'E>'
let g:ycm_warning_symbol = 'W>'
"nnoremap <silent> <C-]> :YcmCompleter GoTo<CR>
"nnoremap <Leader>c :YcmForceCompileAndDiagnostics<CR>

"Run linters and display errors:
Plugin 'scrooloose/syntastic'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Super_ Searching :
Plugin 'kien/ctrlp.vim'

" Source code navigator (files in buffer):
Plugin 'majutsushi/tagbar'
nnoremap <silent> <F9> :TagbarToggle<CR>

" GDB integration:
Plugin 'vim-scripts/Conque-GDB'
let g:ConqueTerm_Color = 2         " 1: strip color after 200 lines, 2: always with color
let g:ConqueTerm_CloseOnEnd = 1    " close conque when program ends running
let g:ConqueTerm_StartMessages = 0 " show warning messages if conqueTerm is configured incorrectly

"Adds diff option when Vim finds a swap file:
Plugin 'chrisbra/Recover.vim'

"Delete buffers and close files withour loosing windows:
Plugin 'moll/vim-bbye'
nnoremap <Leader>q :Bdelete<CR>

Plugin 'grep.vim'
Plugin 'yssl/QFEnter'

" Comment stuff out:
Plugin 'tpope/vim-commentary'
autocmd FileType python setlocal commentstring=#\ %s

"Remote tags -> Source code navigator:
Plugin 'lyuts/vim-rtags'

" Vim-tmux navigation:
"Plugin 'christoomey/vim-tmux-navigator'

" Automatic session saver:
Plugin 'tpope/vim-obsession'


call vundle#end()
filetype plugin indent on
"=============================================================================

colorscheme codedark
let g:airline_theme='codedark'

