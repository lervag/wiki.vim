source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki
normal! 13G
silent call wiki#page#refile(#{target_anchor_before: '#Intro'})
call assert_equal(
      \ readfile('wiki-tmp/ref-by-anchor-before-1.wiki'),
      \ readfile('wiki-tmp/index.wiki'))

call wiki#test#finished()
