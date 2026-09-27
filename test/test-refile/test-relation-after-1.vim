source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-1.wiki
normal! 10G
silent call wiki#page#refile(#{
      \ target_anchor: '#Tasks',
      \ target_relation: 'after'
      \})

" Check that the section and its subsection were moved and promoted
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-after-1.wiki'),
      \ readfile('wiki-tmp/source-1.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ 'Link to: [[#Bar]]',
      \ readfile('wiki-tmp/source-1.wiki')[1])
call assert_equal(
      \ '[[source-1#Bar#Subheading]]',
      \ readfile('wiki-tmp/links.wiki')[10])

call wiki#test#finished()
