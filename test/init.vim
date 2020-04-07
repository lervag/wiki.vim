set nocompatible
let &runtimepath =
      \ simplify(fnamemodify(expand('<sfile>'), ':h') . '/..')
      \ . ',' . &runtimepath
set noswapfile
set nomore
nnoremap q :qall!<cr>
