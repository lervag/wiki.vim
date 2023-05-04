source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_filetypes = ['wiki', 'md']

runtime plugin/wiki.vim

let g:wiki_link_creation._.url_extension = '.wiki'

silent edit test.md
silent call wiki#goto_index()

" Should use .wiki extension when we navigate to the wiki
call assert_equal('wiki', expand('%:e'))

call wiki#test#finished()
