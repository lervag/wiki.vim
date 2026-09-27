source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

" Complete page names. Note that this must return the list of candidates, not
" merely filter them in place.
call assert_equal(['pageA', 'pageB'], wiki#complete#url('page', 'page', 4))

" An empty lead completes every page
let s:candidates = wiki#complete#url('', '', 0)
call assert_equal(v:t_list, type(s:candidates))
call assert_true(index(s:candidates, 'pageA') >= 0)
call assert_true(index(s:candidates, 'index') >= 0)

" Complete anchors within a page
call assert_equal(
      \ ['index#Intro', 'index#Section 1'],
      \ wiki#complete#url('index#', 'index#', 6))

call wiki#test#finished()
