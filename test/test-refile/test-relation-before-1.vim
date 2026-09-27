source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki
normal! 13G
silent call wiki#page#refile(#{
      \ target_anchor: '#Intro',
      \ target_relation: 'before'
      \})
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-before-1.wiki'),
      \ readfile('wiki-tmp/index.wiki'))

call wiki#test#finished()
