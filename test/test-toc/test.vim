source ../init.vim
runtime plugin/wiki.vim

set shiftwidth=2
set expandtab

" Open ToC test page, update ToC and test against reference
silent edit ../wiki-basic/ToC.wiki

WikiPageToc
call wiki#test#assert_equal(
      \ getline(1, '$'),
      \ readfile('../wiki-basic/ToC-reference.wiki'))

if $QUIT | quitall! | endif
