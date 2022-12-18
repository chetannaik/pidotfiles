"         _
"  __   _(_)_ __ ___  _ __ ___
"  \ \ / / | '_ ` _ \| '__/ __|
"   \ V /| | | | | | | | | (__
"    \_/ |_|_| |_| |_|_|  \___|


let mapleader = " "

" " === PLUGINS
call plug#begin('~/.vim/plugged')
    Plug 'scrooloose/nerdtree',
    Plug 'tpope/vim-sensible',
    Plug 'tpope/vim-commentary',
    Plug 'tpope/vim-fugitive',
    Plug 'tpope/vim-surround',
    Plug 'tpope/vim-unimpaired',
    Plug 'chriskempson/base16-vim',
    Plug 'vim-airline/vim-airline',
    Plug 'vim-airline/vim-airline-themes',
    Plug 'terryma/vim-multiple-cursors',
    Plug 'joshdick/onedark.vim',
    " Plug 'easymotion/vim-easymotion',
    Plug 'ntpeters/vim-better-whitespace',
    Plug 'w0rp/ale',
    " Plug 'Yggdroot/indentLine'
call plug#end()


" " === OPTIONS
    set nocompatible
    filetype plugin on
    syntax on
    set encoding=utf-8
    set number relativenumber
    set cursorline
    set ignorecase smartcase
    set expandtab ts=4 sw=3 ai
    set foldmethod=syntax
    set wildmode=longest,list,full
    set noswapfile
    set undofile undolevels=3000 undoreload=10000
    set undodir=~/.vim/undodir
    set splitright splitbelow
    set nopaste
    set nowrap linebreak nolist
    set viewoptions=folds,cursor,slash,unix


" " === UI
   set background=dark


" " === PLUGIN SETUP
" base16
   let base16colorspace=256

" onedark
   let g:onedark_termcolors=256
   let g:onedark_terminal_italics=0
   colorscheme onedark

" airline
   let g:airline#extensions#tabline#formatter = 'default'
   let g:airline_theme = 'onedark'

" " easy motion
"    map / <Plug>(easymotion-sn)
"    map / <Plug>(easymotion-tn)
"    map n <Plug>(easymotion-next)
"    map N <Plug>(easymotion-prev)
"    let g:EasyMotion_smartcase = 1

" ale linters
   let b:ale_linters = ['pylint']

" indent guides
   " let g:indentLine_char_list = ['|', '¦', '┆', '┊']



" " === KEY MAPPINGS
" Vim Better Whitespace
   nmap <leader>as :StripWhitespace<CR>

" NERD Tree Toggle
   map <C-a> :NERDTreeToggle<CR>

" Spel
   map <leader>o :setlocal spell! spelllang=en_us<CR>

" Kitty Vim BG Color
  " vim hardcodes background color erase even if the terminfo file does
  " not contain bce (not to mention that libvte based terminals
  " incorrectly contain bce in their terminfo files). This causes
  " incorrect background rendering when using a color theme with a
  " background color.
  let &t_ut=''

" fzf
  set rtp+=/usr/local/opt/fzf