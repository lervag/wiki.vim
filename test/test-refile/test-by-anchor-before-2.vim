source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-2.wiki
normal! 8G
silent call wiki#page#refile(#{
      \ target_page: 'target-2',
      \ target_anchor_before: '#First#Foo'
      \})
call assert_equal(
      \ readfile('wiki-tmp/ref-by-anchor-before-2.wiki'),
      \ readfile('wiki-tmp/target-2.wiki'))

call wiki#test#finished()
