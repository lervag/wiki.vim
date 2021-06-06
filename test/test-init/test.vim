source ../init.vim

" Initial load of wiki.vim
let g:wiki_filetypes = ['wiki', 'md']
runtime plugin/wiki.vim

" Test open existing wiki with no settings
silent edit ../wiki-basic/subwiki/test.wiki
call assert_true(exists('b:wiki'))

" Test open wiki from globally specified index
bwipeout!
let g:wiki_root = g:testroot . '/wiki-basic'
call assert_true(!exists('b:wiki'))
silent call wiki#goto_index()
call assert_true(exists('b:wiki'))

" Test open wiki with .md extension
bwipeout!
let g:wiki_root = g:testroot . '/wiki-markdown'
call assert_true(!exists('b:wiki'))
silent call wiki#goto_index()
call assert_true(exists('b:wiki'))

call wiki#test#finished()
