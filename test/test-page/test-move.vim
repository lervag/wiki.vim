source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/BadName.wiki

silent call wiki#page#rename('subdir/GoodName')
call wiki#test#assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/subdir/GoodName.wiki',
      \ expand('%:p'))

silent edit wiki-tmp/index.wiki
silent call wiki#page#rename('nosubdir/index')
call wiki#test#assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/nosubdir/index.wiki',
      \ expand('%:p'))
quitall!
