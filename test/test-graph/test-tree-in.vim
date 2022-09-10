source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
let s:tree = sort(values(s:graph.get_tree_to(expand('%:p'), 1)))

call assert_equal(3, len(s:tree))
call assert_equal('index', s:tree[0])
call assert_equal('index ← links', s:tree[1])
call assert_equal('index ← subdir/BadName', s:tree[2])

call wiki#test#finished()
