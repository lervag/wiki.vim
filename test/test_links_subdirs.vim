source init.vim
runtime plugin/wiki.vim

silent edit ex4-subdirs/index.wiki

if empty($QUIT) | finish | endif

" Test toggle normal on regular markdown links using wiki style links
silent execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/index.wiki')

silent execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<plug>(wiki-link-open)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/subsub/index.wiki')

silent execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/sub/index.wiki')

silent execute "normal \<plug>(wiki-link-return)"
call wiki#test#assert_equal(expand('%:.'), 'ex4-subdirs/index.wiki')
