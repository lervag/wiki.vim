source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-3.wiki
normal! 3G
silent call wiki#page#refile(#{
      \ target_anchor: '#Other#Sub',
      \ target_relation: 'inside'
      \})

" Header levels are adjusted, but header-like lines inside fenced code blocks
" are left alone
call assert_equal(
      \ readfile('wiki-tmp/ref-code-block.wiki'),
      \ readfile('wiki-tmp/source-3.wiki'))

call wiki#test#finished()
