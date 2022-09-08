source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/BadName.wiki

silent call wiki#page#rename_to('GoodName')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[4])

silent call wiki#page#rename_to('newdir/GoodName', 'create')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/newdir/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[newdir/GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[4])

silent edit wiki-tmp/subdir/BadName.wiki
silent call wiki#page#rename_to('GoodName')
call assert_equal(
      \ expand('<sfile>:h') . '/wiki-tmp/subdir/GoodName.wiki',
      \ expand('%:p'))
call assert_equal(
      \ '[[subdir/GoodName]]',
      \ readfile('wiki-tmp/rename-links.wiki')[5])

silent edit wiki-tmp/sub/Foo.wiki
silent call wiki#page#rename_to('Bar')
call assert_equal(
      \ '[[sub/Bar]]',
      \ readfile('wiki-tmp/index.wiki')[8])
call assert_equal(
      \ '[[Bar]]',
      \ readfile('wiki-tmp/sub/index.wiki')[4])

call wiki#test#finished()
