source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki

" Test default output directory
silent WikiExport
call wiki#test#assert(filereadable(g:wiki_export.output . '/index.pdf'))

" Test absolute output directory
let g:wiki_export.output = expand('<sfile>:p:h')
silent WikiExport
call wiki#test#assert(filereadable('index.pdf'))
call delete('index.pdf')

" Test relative output directory
let g:wiki_export.output = 'build'
silent WikiExport
call wiki#test#assert(filereadable('wiki-tmp/build/index.pdf'))

if $QUIT | quitall! | endif
