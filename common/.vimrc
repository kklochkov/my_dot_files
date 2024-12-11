set nocompatible " https://askubuntu.com/a/353944
syntax on
set encoding=utf-8
set noerrorbells
set tabstop=2 softtabstop=2
set shiftwidth=2
set expandtab
set smartindent
set nu
set relativenumber
set nowrap
set smartcase
" disable backups, because everything is under git anyways
set noswapfile
set nobackup
"set undodir=~/.vim/undodir
"set undofile
set nowritebackup
set incsearch
set hidden
set guicursor=
set mouse=a
set cmdheight=2
set shortmess+=c
set colorcolumn=120
set clipboard=unnamedplus,unnamed " https://vi.stackexchange.com/a/96
set signcolumn=yes
set termguicolors
set scrolloff=8
set completeopt=menuone,noselect,noinsert
set updatetime=300
set cursorline
" set background=light
set background=dark
set list
set listchars=tab:→\ ,nbsp:␣,space:·,trail:·,extends:⟩,precedes:⟨
set noendofline
set noemoji
set hlsearch

" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin('~/.vim/plugged')

" coc
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" better cpp syntax
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'bfrg/vim-cpp-modern'

" colorschemes
Plug 'rafi/awesome-vim-colorschemes'

" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" powerline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" fonts support
" Droid Sans Mono for Powerline Nerd Font Complete.otf looks the best.
" In order to apply this font, one needs to put in in ~/.local/share/fonts,
" then select it in gnome-tweaks under 'Fonts->Monospace text'.
Plug 'ryanoasis/vim-devicons'

" Copilot
Plug 'github/copilot.vim'

" A Vim plugin to copy text through SSH with OSC52
Plug 'ojroques/vim-oscyank', {'branch': 'main'}

call plug#end()

" Run PlugInstall if there are missing plugins
autocmd VimEnter *
      \ if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \| PlugInstall --sync | q | source $MYVIMRC
      \| endif

" cpp, more info here https://github.com/bfrg/vim-cpp-modern
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_attributes_highlight = 1
let g:cpp_member_highlight = 1
let g:cpp_simple_highlight = 1

" gruvbox
colorscheme gruvbox

" airline
let g:airline_theme = 'gruvbox'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'

" copilot
let g:copilot_filetypes = { 'markdown': v:true, 'gitcommit': v:true }

" GoTo code navigation.
nnoremap <silent> gd <Plug>(coc-definition)
nnoremap <silent> gy <Plug>(coc-type-definition)
nnoremap <silent> gi <Plug>(coc-implementation)
nnoremap <silent> gr <Plug>(coc-references)
nnoremap <silent> gh :CocCommand clangd.switchSourceHeader<CR>

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Make <CR> auto-select the first completion item and notify coc.nvim to
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" buffers
" on mac escape sequence ^[[1;7D
nnoremap <silent> <C-M-right> :bnext <CR>
" on mac escape sequence ^[[1;7C
nnoremap <silent> <C-M-left> :bprev <CR>
nnoremap <silent> <C-w> :bp <BAR> bd! #<CR>

" coc-explorer
nnoremap <C-b> :CocCommand explorer<CR>

" fzf
nnoremap <C-p> :Files<CR>
nnoremap <C-A-p> :Buffers<CR>
nnoremap <C-f> :RG<CR>

" clear selection
nnoremap <Esc><Esc> :noh<CR>:redraw!<CR>

" saving
nnoremap <F2> :w<CR>
nnoremap <F3> :mks! ~/develop/*.vim

function FormatBazel()
  let l:pos = getpos('.')
  let l:view = winsaveview()
  let l:path = expand('%:p')

  echo 'Formatting ' . path

  silent! undojoin
  silent! execute '!~/go/bin/buildifier --lint=fix --mode=fix -warnings all ' . path

  if v:shell_error != 0
   undo
  endif

  call setpos('.', pos)
  call winrestview(view)
endfunction

highlight ExtraWhitespace ctermbg=red guibg=red

function OSC52yank()
  if v:event.operator is 'y'
      execute 'OSCYankRegister ' . v:event.regname
  endif
endfunction

augroup develop
  autocmd!

  " custom file types
  autocmd BufEnter *.qml :setlocal filetype=qml

  " apply autoformat
  autocmd BufWritePost *.h,*.hh,*.inl,*.cc,*.hpp,*.cpp,*py call CocAction('format')
  autocmd BufWritePost *.bzl,WORKSPACE,BUILD,*.BUILD,BUILD.bazel call FormatBazel()

  " trim whitespaces
  autocmd BufWritePre * :%s/\s\+$//e

  " highlight whitespaces
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/

  " yank to OSC52
  autocmd TextYankPost * call OSC52yank()
augroup END
