source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/BadName.wiki

silent call wiki#page#rename('GoodName')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[4])

silent call wiki#page#rename('newdir/GoodName', 'create')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/newdir/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[newdir/GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[4])

silent edit wiki-tmp/subdir/BadName.wiki
silent call wiki#page#rename('GoodName')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/subdir/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[subdir/GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[5])

call wiki#test#finished()
