source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
let s:tree = sort(values(s:graph.get_tree_from(expand('%:p'), 1)))

call assert_equal(3, len(s:tree))
call assert_equal('index', s:tree[0])
call assert_equal('index → NewPage', s:tree[1])
call assert_equal('index → sub/Foo', s:tree[2])

call wiki#test#finished()
