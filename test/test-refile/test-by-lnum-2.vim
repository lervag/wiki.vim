source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki
normal! 13G
silent call wiki#page#refile(#{target_page: 'target-1'})

" Check that content was properly moved
call assert_equal(
      \ readfile('wiki-tmp/ref-by-lnum-2-source.wiki'),
      \ readfile('wiki-tmp/index.wiki'))
call assert_equal(
      \ readfile('wiki-tmp/ref-by-lnum-2-target.wiki'),
      \ readfile('wiki-tmp/target-1.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ '[[target-1#Section 1]]',
      \ readfile('wiki-tmp/index.wiki')[6])
call assert_equal(
      \ '[[target-1#Section 1#Foo bar Baz]]',
      \ readfile('wiki-tmp/index.wiki')[7])
call assert_equal(
      \ '[[target-1#Section 1]]',
      \ readfile('wiki-tmp/links.wiki')[7])
call assert_equal(
      \ '[[target-1#Section 1#Foo bar Baz]]',
      \ readfile('wiki-tmp/links.wiki')[8])

call wiki#test#finished()
