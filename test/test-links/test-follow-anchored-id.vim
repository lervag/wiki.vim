source ../init.vim
let g:wiki_root = g:testroot . '/wiki-markdown'
let g:wiki_filetypes = ['md']
runtime plugin/wiki.vim

silent WikiIndex

normal! 7G$
call wiki#link#follow()
call assert_equal(1, line('.'))

normal! 8G$
call wiki#link#follow()
call assert_equal(18, line('.'))

normal! 9G
call wiki#link#follow()
call assert_equal(16, line('.'))

normal! 10G
call wiki#link#follow()
call assert_equal(22, line('.'))

normal! 11G
call wiki#link#follow()
call assert_equal(11, line('.'))

normal! 12G
call wiki#link#follow()
call assert_equal(12, line('.'))

normal! 13G
call wiki#link#follow()
call assert_equal(13, line('.'))

call wiki#test#finished()
