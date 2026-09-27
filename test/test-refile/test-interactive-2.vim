source ../init.vim
runtime plugin/wiki.vim

let g:wiki_log_verbose = 0

" Stub the page prompt. The echo of input() can not be silenced, so the real
" prompt would pollute the output of the test suite.
let g:wiki_ui_method = #{
      \ confirm: 'legacy',
      \ input: 'test',
      \ select: 'legacy',
      \}

silent edit wiki-tmp/index.wiki
normal! 13G

" The source section and its subsections are not offered as targets
let s:source = wiki#page#refile#collect_source()
call assert_equal(
      \ ['[end of page]', '#Intro'],
      \ wiki#page#refile#get_target_choices(s:source.path, s:source))

" Abort the section menu
call feedkeys('x', 'nt')
redir => s:msg | silent call wiki#page#refile() | redir END

call assert_equal([], wiki#log#get())
call assert_equal(
      \ readfile('wiki/index.wiki'),
      \ readfile('wiki-tmp/index.wiki'))

" Select "#Intro" from the section menu
call feedkeys('2', 'nt')
redir => s:msg | silent call wiki#page#refile() | redir END

call assert_equal(
      \ readfile('wiki-tmp/ref-interactive-2.wiki'),
      \ readfile('wiki-tmp/index.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ '[[index#Intro#Section 1]]',
      \ readfile('wiki-tmp/links.wiki')[7])

call wiki#test#finished()
