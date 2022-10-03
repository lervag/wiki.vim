source ../init.vim
let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

silent WikiIndex

normal! 15G
call wiki#link#follow()
call assert_equal(20, line('.'))

normal! 16G
call wiki#link#follow()
call assert_equal(20, line('.'))

call wiki#test#finished()
