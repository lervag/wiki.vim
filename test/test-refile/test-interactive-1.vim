source ../init.vim
runtime plugin/wiki.vim

" Stub the page prompt. The echo of input() can not be silenced, so the real
" prompt would pollute the output of the test suite.
let g:wiki_ui_method = #{
      \ confirm: 'legacy',
      \ input: 'test',
      \ select: 'legacy',
      \}
let g:wiki_test_input = 'target-2'

silent edit wiki-tmp/index.wiki
normal! 13G

" Select entry 5, which is "#Second", from the section menu
call feedkeys('5', 'nt')
redir => s:msg | silent call wiki#page#refile() | redir END

" Check that content was properly moved
call assert_equal(
      \ readfile('wiki-tmp/ref-interactive-source.wiki'),
      \ readfile('wiki-tmp/index.wiki'))
call assert_equal(
      \ readfile('wiki-tmp/ref-interactive-target.wiki'),
      \ readfile('wiki-tmp/target-2.wiki'))

call wiki#test#finished()
