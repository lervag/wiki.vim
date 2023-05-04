source ../init.vim
let g:wiki_filetypes = ['org']
runtime plugin/wiki.vim

silent edit wiki-tmp/test\ 2.org

silent call wiki#page#rename(#{new_name: 'test 3'})
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/test 3.org',
      \ expand('%:p'))
let s:lines = readfile('wiki-tmp/test 1.org')
call assert_equal('[[test 3.org][test 2]]', s:lines[1])
call assert_equal('[[test 3.org]]', s:lines[4])

call wiki#test#finished()
