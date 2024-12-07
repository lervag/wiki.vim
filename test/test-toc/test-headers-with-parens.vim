source ../init.vim
let g:wiki_filetypes = ['md']

runtime plugin/wiki.vim

set shiftwidth=2
set expandtab

silent edit aux/headers-with-parens-input.md

WikiTocGenerate
call assert_equal(
      \ readfile('aux/headers-with-parens-reference.md'),
      \ getline(1, '$'))

call wiki#test#finished()
