call plug#begin('~/.vim/bundle')
Plug 'lervag/wiki.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

set hidden
set conceallevel=0

let g:wiki_root = '../../test-common/ex2-markdown'
let g:wiki_filetypes = ['md']
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = '.md'

let g:coc_global_extensions = [
      \ 'coc-omni',
      \]

