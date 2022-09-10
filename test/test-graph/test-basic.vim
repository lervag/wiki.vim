source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
call assert_equal(
      \ '../wiki-basic',
      \ wiki#paths#relative(s:graph.root, expand('<sfile>:p:h'))
      \)
call assert_equal('wiki', s:graph.extension)

call wiki#test#finished()
