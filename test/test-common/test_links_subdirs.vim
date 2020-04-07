source ../init.vim
runtime plugin/wiki.vim

silent edit ex4-subdirs/index.wiki
set hidden

" Test toggle normal on regular markdown links using wiki style links
execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/index.wiki')

execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/subsub/index.wiki')

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/index.wiki')

execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/index.wiki')

if $QUIT | quitall! | endif
