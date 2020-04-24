source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/BadName.wiki

silent call wiki#page#rename('GoodName')
call wiki#test#assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/GoodName.wiki',
      \ expand('%:p'))
call wiki#test#assert_equal('[[GoodName]]', readfile('wiki-tmp/index.wiki')[4])

silent edit wiki-tmp/subdir/BadName.wiki
silent call wiki#page#rename('GoodName')
call wiki#test#assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/subdir/GoodName.wiki',
      \ expand('%:p'))
call wiki#test#assert_equal('[[subdir/GoodName]]', readfile('wiki-tmp/index.wiki')[5])

if $QUIT | quitall! | endif
