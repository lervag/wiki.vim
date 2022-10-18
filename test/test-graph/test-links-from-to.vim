source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()

let s:filenames = uniq(sort(map(
      \ s:graph.get_links_to(expand('%:p')),
      \ 'wiki#paths#relative(v:val.filename_from, g:testroot)')
      \))
call assert_equal(2, len(s:filenames))
call assert_equal('wiki-basic/links.wiki', s:filenames[0])
call assert_equal('wiki-basic/subdir/BadName.wiki', s:filenames[1])

let s:filenames = uniq(sort(map(
      \ s:graph.get_links_from(expand('%:p')),
      \ 'wiki#paths#relative(v:val.filename_to, g:testroot)')
      \))
call assert_equal(2, len(s:filenames))
call assert_equal('wiki-basic/NewPage.wiki', s:filenames[0])
call assert_equal('wiki-basic/sub/Foo.wiki', s:filenames[1])

call wiki#test#finished()
