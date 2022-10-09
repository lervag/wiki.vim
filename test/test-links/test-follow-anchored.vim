source ../init.vim
let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

silent WikiIndex

normal! 16G
call wiki#link#follow()
call assert_equal(21, line('.'))

normal! 17G
call wiki#link#follow()
call assert_equal(21, line('.'))

call wiki#test#finished()
