set runtimepath^=../..
set runtimepath^=fzf
set runtimepath^=fzf.vim
let s:root = fnamemodify(expand('<sfile>'), ':p:h')
let $PATH=$PATH . ':' . s:root . '/fzf/bin'

set nocompatible
set noswapfile
set nomore

filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:wiki_cache_persistent = 0
let g:wiki_filetypes = ['wiki']
let g:wiki_root = '../wiki-basic'

let g:wiki_select_method = {
      \ 'pages': function('wiki#fzf#pages'),
      \ 'tags': function('wiki#fzf#tags'),
      \ 'toc': function('wiki#fzf#toc'),
      \ 'links': function('wiki#fzf#links'),
      \}

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

" WikiTags
" WikiPages
