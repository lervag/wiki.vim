set runtimepath^=../..
set nocompatible
set noswapfile
set nomore

filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:wiki_cache_persistent = 0
let g:wiki_filetypes = ['wiki', 'md']
let g:wiki_root = '../wiki-markdown'

let g:wiki_link_creation = {
      \ 'md': {
      \   'link_type': 'wiki',
      \   'url_extension': '',
      \ },
      \}
let g:wiki_mappings_local = {
      \ "i_<plug>(wiki-link-add)": "<c-a>",
      \}

runtime plugin/wiki.vim

silent edit ../wiki-markdown/subwiki/index.md

" WikiTags
" WikiPages
