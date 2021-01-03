set nocompatible
let &rtp = '../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:wiki_filetypes = ['md']

let g:wiki_map_link_create = 'Create'
let g:wiki_map_create_page = 'Create'
function Create(text) abort
  return substitute(tolower(a:text), '\.', '', 'g')
endfunction

let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = '.md'
