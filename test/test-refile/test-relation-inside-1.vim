source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/source-1.wiki
normal! 10G
silent call wiki#page#refile(#{
      \ target_anchor: '#Tasks#Baz',
      \ target_relation: 'inside'
      \})

" Check that the section and its subsection were moved and demoted
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-inside-1.wiki'),
      \ readfile('wiki-tmp/source-1.wiki'))

" Check that all links to the previous location are updated
call assert_equal(
      \ 'Link to: [[#Tasks#Baz#Bar]]',
      \ readfile('wiki-tmp/source-1.wiki')[1])
call assert_equal(
      \ '[[source-1#Tasks#Baz#Bar#Subheading]]',
      \ readfile('wiki-tmp/links.wiki')[10])

call wiki#test#finished()
