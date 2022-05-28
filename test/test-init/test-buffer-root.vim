source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_filetypes = ['wiki', 'md']
let g:wiki_link_extension = '.wiki'

runtime plugin/wiki.vim

silent edit test.md

" Should use .wiki extension when we navigate to the wiki
call assert_false(has_key(b:wiki, 'root'))

call wiki#test#finished()
