source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-2.wiki
normal! 8G
silent call wiki#page#refile(#{
      \ target_page: 'target-2',
      \ target_anchor: '#First#Foo',
      \ target_relation: 'before'
      \})
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-before-2.wiki'),
      \ readfile('wiki-tmp/target-2.wiki'))

call wiki#test#finished()
