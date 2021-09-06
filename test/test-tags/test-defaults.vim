source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0

silent edit ../wiki-basic/index.wiki

let s:tags = wiki#tags#get_all()
call assert_equal(5, len(s:tags))
call assert_equal(1, len(s:tags.tag1))
call assert_equal(2, len(s:tags.marked))

call wiki#test#finished()
