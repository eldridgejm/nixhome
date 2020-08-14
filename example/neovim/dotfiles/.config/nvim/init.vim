" vimrc
" =====
" Author: Justin Eldridge

" general settings
" ================

" tabs
set expandtab
set shiftwidth=4
set tabstop=4
set smarttab

" keep the cursor in the middle of the screen
set scrolloff=7

" numbering
set number

" searching
set ignorecase smartcase
set incsearch
set showmatch
set hlsearch

" whitespace to show when `list` is set
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<

" we use vim as the pager
let $PAGER=''

" keybindings
" ===========

let mapleader = "\\"

" window mappings
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" clear highlighting
nnoremap \q :noh<CR>

" file explorer
nnoremap <leader>e :e.<cr>
nnoremap <leader>E :Explore<cr>

" plugins
" =======
" plugins are managed in the nix file

" colors
" ======
set termguicolors
set cursorline
colorscheme dracula

" more visible popup menu
hi Pmenu ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#64666d gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=24 cterm=NONE guifg=NONE guibg=#204a87 gui=NONE

" status line
" ===========

" always show status
set laststatus=2

set statusline=%<\             " begins with whitespace
set statusline+=%t             " filename
set statusline+=\              " whitespace
set statusline+=%m             " modified
set statusline+=%r             " read-only
set statusline+=%y             " filetype
set statusline+=%w             " preview
set statusline+=%=             " split
set statusline+=Col:\ \%c      " column number
set statusline+=\              " whitespace
set statusline+=Lin:\ \%l\/\%L " line number/total
set statusline+=\              " ends with whitespace

" vimtex
" ======

let g:vimtex_compiler_progname = "nvr"
if has("macunix")
    let g:vimtex_view_method = "general"
    let g:vimtex_view_general_viewer
          \ = '/Applications/Skim.app/Contents/SharedSupport/displayline'
    let g:vimtex_view_general_options = '-r @line @pdf @tex'

    " This adds a callback hook that updates Skim after compilation
    let g:vimtex_latexmk_callback_hooks = ['UpdateSkim']
    function! UpdateSkim(status)
        if !a:status | return | endif

        et l:out = b:vimtex.out()
        let l:tex = expand('%:p')
        let l:cmd = [g:vimtex_view_general_viewer, '-r']
        if !empty(system('pgrep Skim'))
            call extend(l:cmd, ['-g'])
        endif
        if has('nvim')
            call jobstart(l:cmd + [line('.'), l:out, l:tex])
        elseif has('job')
            call job_start(l:cmd + [line('.'), l:out, l:tex])
        else
            call system(join(l:cmd + [line('.'), shellescape(l:out), shellescape(l:tex)], ' '))
        endif
    endfunction
else
    let g:vimtex_view_method = "zathura"
endif

" fzf
noremap <leader>f :Files<cr>
noremap <leader>b :Buffers<cr>

" deoplete
" ========

let g:deoplete#enable_at_startup = 1

" use tab to select from the deoplete menu
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

" autocommands
" ============

" markdown
augroup markdown
	autocmd!
	autocmd FileType markdown setlocal tw=80 wrap spell 
augroup END

" python
augroup python
	autocmd!
	autocmd FileType python
        \ setlocal colorcolumn=79 expandtab shiftwidth=4 tabstop=4 smarttab
    autocmd FileType python setlocal completeopt-=preview
augroup END

" c++
augroup csrc
	autocmd!
	autocmd FileType c,cpp setlocal expandtab sw=4 ts=4 smarttab expandtab
augroup END

" arduino
augroup arduino
	autocmd! 
	autocmd BufNewFile,BufRead *.pde setlocal ft=arduino
augroup END

" latex
let g:tex_flavor = "latex"
augroup tex
    autocmd!
    autocmd FileType tex setlocal spell
    autocmd FileType tex setlocal tw=0 cc=80
    autocmd FileType tex let tex_conceal=0
augroup END


let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'


" local config
" ============

" read vimlocal if it exists
set secure
silent! so vimlocal
