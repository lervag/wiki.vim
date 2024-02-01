set runtimepath^=../..
set nocompatible
set noswapfile
set nomore

filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:wiki_cache_persistent = 0
let g:wiki_filetypes = ['wiki']
let g:wiki_root = '../wiki-basic'

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

" WikiTags
" WikiPages
