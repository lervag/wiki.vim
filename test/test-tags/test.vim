source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:tags = wiki#tags#get_all()
call assert_equal(2, len(s:tags))
call assert_equal(2, len(s:tags.tagged))
call assert_equal(2, len(s:tags.marked))

call wiki#test#finished()
