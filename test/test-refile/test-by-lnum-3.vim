source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/index.wiki
normal! 15G
silent call wiki#page#refile(#{
      \ target_page: 'target-2',
      \ target_lnum: 10
      \})

" Check that content was properly moved
call assert_equal(
      \ readfile('wiki-tmp/ref-by-lnum-3-source.wiki'),
      \ readfile('wiki-tmp/index.wiki'))
call assert_equal(
      \ readfile('wiki-tmp/ref-by-lnum-3-target.wiki'),
      \ readfile('wiki-tmp/target-2.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ '[[target-2#Second#Foo bar Baz]]',
      \ readfile('wiki-tmp/index.wiki')[7])
call assert_equal(
      \ '[[target-2#Second#Foo bar Baz]]',
      \ readfile('wiki-tmp/links.wiki')[8])

call wiki#test#finished()
