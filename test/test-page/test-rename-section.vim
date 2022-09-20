source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/pageA.wiki

call cursor(3, 1)
silent call wiki#page#rename_section('Subsection i')

call cursor(6, 1)
silent call wiki#page#rename_section('Subsection ii')

call cursor(7, 1)
silent call wiki#page#rename_section('Section II')

" This doessn't work because of issues with the graph
" call cursor(11, 1)
" call wiki#page#rename_section('New sub section')

let s:expected = readfile(expand('<sfile>:h') . '/wiki-tmp/pageB.wiki.ref')[1:]
let s:observed = readfile(expand('<sfile>:h') . '/wiki-tmp/pageB.wiki')[1:]
call assert_equal(s:expected, s:observed)

call wiki#test#finished()
