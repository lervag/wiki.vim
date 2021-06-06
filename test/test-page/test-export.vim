source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki

" Test default output directory
silent WikiExport
call assert_true(filereadable(g:wiki_export.output . '/index.pdf'))

" Test absolute output directory
let g:wiki_export.output = expand('<sfile>:p:h')
silent WikiExport
call assert_true(filereadable('index.pdf'))
call delete('index.pdf')

" Test relative output directory
let g:wiki_export.output = 'build'
silent WikiExport
call assert_true(filereadable('wiki-tmp/build/index.pdf'))

call wiki#test#finished()
