source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki

function! s:complete(line) abort
  let l:lead = matchstr(a:line, '\%(\\\)\@<!\s\zs\S*$')
  return wiki#complete#refile(l:lead, a:line, len(a:line))
endfunction

" An option that is already used is not offered again
call assert_equal(
      \ ['-page', '-anchor', '-relation', '-lnum'],
      \ s:complete('WikiPageRefile '))
call assert_equal(['-page'], s:complete('WikiPageRefile -p'))
call assert_equal(
      \ ['-anchor', '-relation', '-lnum'],
      \ s:complete('WikiPageRefile -page target-2 '))

" A value that looks like an option is not mistaken for one
call assert_equal(
      \ ['-anchor', '-relation', '-lnum'],
      \ s:complete('WikiPageRefile -page my-page '))

" -lnum can not be combined with -anchor or -relation
call assert_equal(['-page'], s:complete('WikiPageRefile -lnum 5 '))
call assert_equal(
      \ ['-page', '-relation'],
      \ s:complete('WikiPageRefile -anchor #Intro '))

" Option values are completed, but a line number has no completion
call assert_equal(
      \ ['inside', 'before', 'after'],
      \ s:complete('WikiPageRefile -relation '))
call assert_equal([], s:complete('WikiPageRefile -lnum '))

" Anchors are completed for the page given by -page, with escaped spaces
call assert_equal(
      \ ['#Intro', '#Section\ 1', '#Section\ 1#Foo\ bar\ Baz'],
      \ s:complete('WikiPageRefile -anchor '))
call assert_equal(
      \ ['#First', '#First#Foo', '#First#Bar',
      \  '#Second', '#Second#Baz', '#Second#Foobar'],
      \ s:complete('WikiPageRefile -page target-2 -anchor '))

" An escaped space does not end an argument
call assert_equal(
      \ ['-page', '-relation'],
      \ s:complete('WikiPageRefile -anchor #Section\ 1 '))

call wiki#test#finished()
