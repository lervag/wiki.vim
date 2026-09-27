source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/nested.wiki
normal! 9G
silent call wiki#page#refile(#{
      \ target_anchor: '#Target',
      \ target_relation: 'inside'
      \})

" The target section has both its own text and a subsection. The refiled
" section must end up below the text that belongs to the target section, but
" above the subsections of the target section.
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-inside-2.wiki'),
      \ readfile('wiki-tmp/nested.wiki'))

call wiki#test#finished()
