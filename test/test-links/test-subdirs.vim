source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/test-links-subdirs.wiki
set hidden

" Test toggle normal on regular markdown links using wiki style links
execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/sub/index.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/sub/subsub/index.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/sub/index.wiki', ':p'),
      \ expand('%:p'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(
      \ fnamemodify('../wiki-basic/test-links-subdirs.wiki', ':p'),
      \ expand('%:p'))

if $QUIT | quitall! | endif
