source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:graph = wiki#graph#builder#get()
let s:broken_links = s:graph.get_broken_links_global()

call assert_equal(2, len(s:broken_links))
call assert_equal('wiki:file with spaces', s:broken_links[0].content)
call assert_equal('wiki:file with spaces', s:broken_links[1].content)

call wiki#test#finished()
