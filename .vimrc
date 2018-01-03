" Felipe "Valdes' .vimrc

set nocompatible
filetype off

set encoding=utf-8

" Force Vim to source .vimrc if present:
set exrc
" Since Vim will source .vimrc from any directory you run Vim from, this is a
" potential security hole; the following command will oimpose restrictions:
set secure

" Enable syntax highlighting:
syntax on

set colorcolumn=100
highlight ColorColumn ctermbg=White

set number
set numberwidth=5
set tabstop=4
set shiftwidth=4
set expandtab
set cursorline
set splitbelow
set splitright
set backspace=2		" Backspace deletes like most programs in insert mode
set updatetime=250

" Split navigations:
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Enable folding:
set foldmethod=indent
set foldlevel=99
set foldenable
set autoindent
set confirm
"set visualbell
set mouse=a
set cmdheight=2

" Backgound color fix for tmux + vim:
if &term =~ '256color'
    " disable Background Color Erase (BCE) so that color schemes
    " render properly when inside 256-color tmux and GNU screen.
    " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
    set t_ut=
endif


"=============================================================================
" Plugins managed by vundle:
"=============================================================================
set rtp+=~/.vim/bundle/vundle
call vundle#begin()

" Let Vundle manage Vundle (required):
Plugin 'VundleVim/Vundle.vim'

" Colors :
Plugin 'altercation/vim-colors-solarized'
Plugin 'nanotech/jellybeans.vim'

" File-tree :
Plugin 'The-NERD-tree', { 'on':'NERDTreeToggle' }

Plugin 'tmhedberg/SimpylFold'

" Indentation marker (vertical lines):
Plugin 'Yggdroot/indentLine'

" Git Integration : 
Plugin 'tpope/vim-fugitive'
Plugin 'vim-airline/vim-airline'
Plugin 'airblade/vim-gitgutter'

" C/C++ completion:
"Plugin 'Valloric/YouCompleteMe'

" Run linters and display errors:
Plugin 'scrooloose/syntastic'

" Super_ Searching :
Plugin 'kien/ctrlp.vim'

" Source code navigator:
Plugin 'Tagbar'

" GDB integration:
Plugin 'vim-scripts/Conque-GDB'

Plugin 'grep.vim'
Plugin 'yssl/QFEnter'

" Comment stuff out:
Plugin 'tpope/vim-commentary'

" Remote tags -> Source code navigator:
"Plugin 'lyuts/vim-rtags'

" Vim-tmux navigation:
Plugin 'christoomey/vim-tmux-navigator'

" Automatic session saver:
Plugin 'tpope/vim-obsession'


call vundle#end()
"=============================================================================

"=============================================================================
" Plugin-related options:
"=============================================================================

" YouCompleteMe options:
let g:ycm_confirm_extra_conf = 0
" let g:ycm_auto_trigger = 0
" let g:ycm_min_num_of_chars_for_completion = 99
" let s:omnifunc_mode = 0
" let g:ycm_show_diagnostics_ui = 0
nnoremap <silent> <C-]> :YcmCompleter GoTo<CR>
nnoremap <Leader>c :YcmForceCompileAndDiagnostics<CR>

" Solarized colors' options:
syntax enable
set background=dark
let g:solarized_termcolors = 256
let g:solarized_visibility = "high"
let g:solarized_contrast = "high"
colorscheme solarized

" Jellybeans colors' options:
let g:jellybeans_overrides = {
\    'background': { 'ctermbg': 'none', '256ctermbg': 'none' },
\}
colorscheme jellybeans

" NERD-Tree options:
map <C-n> :NERDTreeToggle<CR>
let NERDTreeIgnore=['\.pyc$', '\.swp$', '\~$']
let g:NERDTreeMouseMode = 2  " Single-click to expand the directory, double-click to open the file

" indentLine options:
let g:indentLine_char = '┊'
let g:indentLine_showFirstIndentLevel = 1

" Conque-GDB options:
let g:ConqueTerm_Color = 2         " 1: strip color after 200 lines, 2: always with color
let g:ConqueTerm_CloseOnEnd = 1    " close conque when program ends running
let g:ConqueTerm_StartMessages = 0 " display warning messages if conqueTerm is configured incorrectly

" tagbar options:
nnoremap <silent> <F9> :TagbarToggle<CR>

" vim-commentary options:
autocmd FileType python setlocal commentstring=#\ %s

" airline options:
let g:airline_powerline_fonts = 1
let g:airline_inactive_collapse = 0 		 " Do not collapse the status line while having multiple windows
let g:airline#extensions#whitespace#enabled = 0	 " Do not check for whitespaces
let g:airline#extensions#tabline#enabled = 1     " Display tab bar with buffers
let g:airline#extensions#branch#enabled = 1      " Enable Git client integration
let g:airline#extensions#tagbar#enabled = 1      " Enable Tagbar integration
let g:airline#extensions#hunks#enabled = 1       " Enable Git hunks integration
"=============================================================================


" Misc. options:
if has('cmdline_info')
  set ruler                   " Show the ruler
  set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " A ruler on steroids
endif


" Better command-line completion
set wildmenu

" Show partial commands in the last line of the screen
set showcmd

" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
set wildignore+=*.o,*.obj,*.exe,*.so,*.dll,*.pyc,.svn,.hg,.bzr,.git,
  \.sass-cache,*.class,*.scssc,*.cssc,sprockets%*,*.lessc
set ignorecase
set smartcase
set showmatch

