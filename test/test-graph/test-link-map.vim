source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
let s:map = s:graph.get_map()

call assert_equal(207, len(s:map))
call assert_equal(4,
      \ len(s:map[fnamemodify('../wiki-basic/pageA.wiki', ':p')].in))
call assert_equal(0,
      \ len(s:map[fnamemodify('../wiki-basic/ToC.wiki', ':p')].out))

call wiki#test#finished()
