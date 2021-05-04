source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/a.wiki
set hidden

silent execute "normal \<plug>(wiki-link-follow)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/b.wiki', ':p'),
      \ expand('%:p'))

silent execute "normal \<plug>(wiki-link-follow)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/c.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/b.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/a.wiki', ':p'),
      \ expand('%:p'))

set nohidden

silent execute "normal \<plug>(wiki-link-follow)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/b.wiki', ':p'),
      \ expand('%:p'))

silent execute "normal \<plug>(wiki-link-follow)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/c.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/b.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/a.wiki', ':p'),
      \ expand('%:p'))

if $QUIT | quitall! | endif
