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
set clipboard+=unnamedplus
set signcolumn=yes
set termguicolors
set scrolloff=8
set completeopt=menuone,noselect,noinsert
set updatetime=300
set cursorline
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
Plug 'tinted-theming/base16-vim'

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

" base16 colorscheme settings
colorscheme base16-gruvbox-dark-medium
let base16_colorspace=256 " Access colors present in 256 colorspaceet noemoji
let base16_background_transparent=1 " Make vim background transparent to work alongside transparent terminal backgrounds
highlight Comment cterm=None " fix up comments

" airline
let g:airline_theme = 'base16_gruvbox_dark_medium'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gh :CocCommand clangd.switchSourceHeader<CR>

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
"inoremap <silent><expr> <TAB>
"      \ pumvisible() ? "\<C-n>" :
"      \ <SID>check_back_space() ? "\<TAB>" :
"      \ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
"function! s:check_back_space() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Make <CR> auto-select the first completion item and notify coc.nvim to
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" buffers
" on mac escape sequence ^[[1;7D
nmap <silent> <C-M-right> :bnext <CR>
" on mac escape sequence ^[[1;7C
nmap <silent> <C-M-left> :bprev <CR>
nmap <silent> <C-w> :bp <BAR> bd! #<CR>

"" netrw
"let g:netrw_banner = 0
"let g:netrw_liststyle = 3
"let g:netrw_browse_split = 4
"let g:netrw_altv = 1
"let g:netrw_winsize = 20
"let g:netrw_keepdir = 0
"let g:NetrwIsOpen=0
"
"function! ToggleNetrw()
"    if g:NetrwIsOpen
"        let i = bufnr("$")
"        while (i >= 1)
"            if (getbufvar(i, "&filetype") == "netrw")
"                silent exe "bwipeout " . i
"            endif
"            let i-=1
"        endwhile
"        let g:NetrwIsOpen=0
"    else
"        let g:NetrwIsOpen=1
"        " reveal file
"        " https://superuser.com/a/1536118
"        silent let @/=expand("%:t") | execute 'Lexplore' expand("%:h") | normal n
"    endif
"endfunction
"
"" Add your own mapping. For example:
"noremap <C-b> :call ToggleNetrw()<CR>

" coc-explorer
nmap <C-b> :CocCommand explorer<CR>

" fzf
nmap <C-p> :Files<CR>
nmap <C-A-p> :Buffers<CR>
nmap <C-f> :Rg<CR>

" clear selection
nmap <Esc><Esc> :noh<CR>:redraw!<CR>

" saving
nmap <F2> :w<CR>
nmap <F3> :mks! ~/develop/*.vim

" auto formatting using the clang-format tooling
function FormatSources()
  let l:pos = getpos('.')
  let l:view = winsaveview()
  let l:path = expand('%:p')

  echo 'Formatting ' . path

  silent! undojoin
  silent! execute '!clang-format -i ' . path

  if v:shell_error != 0
   undo
  endif

  call setpos('.', pos)
  call winrestview(view)
endfunction

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

function FormatPython()
  let l:pos = getpos('.')
  let l:view = winsaveview()
  let l:path = expand('%:p')

  echo 'Formatting ' . path

  silent! undojoin
  silent! execute '!isort --profile black --quiet ' . path

  if v:shell_error != 0
   undo
  endif

  silent! execute '!black --quiet ' . path

  if v:shell_error != 0
   undo
  endif

  call setpos('.', pos)
  call winrestview(view)
endfunction

highlight ExtraWhitespace ctermbg=red guibg=red

augroup develop
  autocmd!

  " custom file types
  autocmd BufEnter *.qml :setlocal filetype=qml

  " apply autoformat
  autocmd BufWritePost *.h,*.hh,*.inl,*.cc,*.hpp,*.cpp call FormatSources()
  autocmd BufWritePost *.bzl,WORKSPACE,BUILD,*.BUILD,BUILD.bazel call FormatBazel()
  autocmd BufWritePost *.py call FormatPython()

  " trim whitespaces
  autocmd BufWritePre * :%s/\s\+$//e

  " highlight whitespaces
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
augroup END
