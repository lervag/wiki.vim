source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()

let s:links = s:graph.get_links_to(expand('%:p'))
for s:l in s:links
  let s:l.filename_from = wiki#paths#relative(s:l.filename_from, g:testroot)
endfor

call assert_equal(5, len(s:links))
call assert_equal('wiki-basic/links.wiki', s:links[0].filename_from)
call assert_equal('wiki-basic/links.wiki', s:links[1].filename_from)
call assert_equal('wiki-basic/links.wiki', s:links[2].filename_from)
call assert_equal('wiki-basic/links.wiki', s:links[3].filename_from)
call assert_equal('wiki-basic/subdir/BadName.wiki', s:links[4].filename_from)


let s:links = s:graph.get_links_from(expand('%:p'))
for s:l in s:links
  let s:l.filename_to = wiki#paths#relative(s:l.filename_to, g:testroot)
endfor

call assert_equal(2, len(s:links))
call assert_equal('wiki-basic/NewPage.wiki', s:links[0].filename_to)
call assert_equal('wiki-basic/sub/Foo.wiki', s:links[1].filename_to)

call wiki#test#finished()
