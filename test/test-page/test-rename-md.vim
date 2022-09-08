source ../init.vim
let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
runtime plugin/wiki.vim

silent edit wiki-tmp/test\ 2.md

silent call wiki#page#rename_to('test 3')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/test 3.md',
      \ expand('%:p'))
let s:lines = readfile('wiki-tmp/test 1.md')
call assert_equal('[test 2](test 3.md)', s:lines[1])
call assert_equal('[[test 3.md]]', s:lines[4])

call wiki#test#finished()
