source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/pageA.wiki

call cursor(3, 1)
silent call wiki#page#rename_section('Subsection i')

call cursor(6, 1)
silent call wiki#page#rename_section('Subsection ii')

call cursor(7, 1)
silent call wiki#page#rename_section('Section II')

" Clear cache here because (cache ftime has 1 second resolution, which is too
" slow for these tests)
call wiki#cache#clear('toc')

call cursor(11, 1)
silent call wiki#page#rename_section('New sub section')

let s:expected = readfile(expand('<sfile>:h') . '/wiki-tmp/pageA.wiki.ref')[1:]
let s:observed = readfile(expand('<sfile>:h') . '/wiki-tmp/pageA.wiki')[1:]
call assert_equal(s:expected, s:observed)

let s:expected = readfile(expand('<sfile>:h') . '/wiki-tmp/pageB.wiki.ref')[1:]
let s:observed = readfile(expand('<sfile>:h') . '/wiki-tmp/pageB.wiki')[1:]
call assert_equal(s:expected, s:observed)

call wiki#test#finished()
