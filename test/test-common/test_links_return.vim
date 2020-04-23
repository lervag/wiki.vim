source ../init.vim
runtime plugin/wiki.vim

silent edit ex1-basic/a.wiki
set hidden

silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal('ex1-basic/b.wiki', expand('%:.'))

silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal('ex1-basic/c.wiki', expand('%:.'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal('ex1-basic/b.wiki', expand('%:.'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal('ex1-basic/a.wiki', expand('%:.'))

set nohidden

silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal('ex1-basic/b.wiki', expand('%:.'))

silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal('ex1-basic/c.wiki', expand('%:.'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal('ex1-basic/b.wiki', expand('%:.'))

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal('ex1-basic/a.wiki', expand('%:.'))

if $QUIT | quitall! | endif
