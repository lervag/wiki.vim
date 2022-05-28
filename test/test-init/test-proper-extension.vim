source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_filetypes = ['wiki', 'md']
let g:wiki_link_extension = '.wiki'

runtime plugin/wiki.vim

silent edit test.md
silent call wiki#goto_index()

" Should use .wiki extension when we navigate to the wiki
call assert_equal('wiki', expand('%:e'))

call wiki#test#finished()
