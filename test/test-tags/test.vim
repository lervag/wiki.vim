source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:tags = wiki#tags#get_all()
call wiki#test#assert_equal(len(s:tags), 2)
call wiki#test#assert_equal(len(s:tags.tagged), 2)
call wiki#test#assert_equal(len(s:tags.marked), 2)

if $QUIT | quitall! | endif
