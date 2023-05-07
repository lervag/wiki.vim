set nocompatible
let &runtimepath =
      \ simplify(fnamemodify(expand('<sfile>'), ':h') . '/..')
      \ . ',' . &runtimepath
set noswapfile
set nomore
nnoremap q :qall!<cr>

let g:testroot = fnamemodify(expand('<cfile>'), ':p:h:h')

let g:wiki_cache_persistent = 0

let g:wiki_filetypes = ['wiki']
