source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
let s:tree = s:graph.get_tree_to(expand('%:p'), 1)

call assert_equal('index', s:tree.node)
call assert_false(s:tree.cycle)

let s:children = sort(map(copy(s:tree.children), { _, x -> x.node }))
call assert_equal(['links', 'subdir/BadName'], s:children)

for s:child in s:tree.children
  call assert_equal([], s:child.children)
endfor

call wiki#test#finished()
