source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-1.wiki
normal! 10G
silent call wiki#page#refile(#{target_lnum: 20})

" Check that content was properly removed from index and moved to targetA
call assert_equal(
      \ readfile('wiki-tmp/ref-same-file.wiki'),
      \ readfile('wiki-tmp/source-1.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ '[[source-1#Tasks#Bar#Subheading]]',
      \ readfile('wiki-tmp/links.wiki')[10])

call wiki#test#finished()
