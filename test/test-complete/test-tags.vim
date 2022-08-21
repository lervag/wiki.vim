source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0

silent edit ../wiki-basic/index.wiki

let s:candidates = wiki#test#completion(':t', 'tag')
call assert_equal(9, len(s:candidates))
let s:candidates = wiki#test#completion(':T', 'Tag')
call assert_equal(0, len(s:candidates))
let g:wiki_completion_case_sensitive = 0
let s:candidates = wiki#test#completion(':T', 'Tag')
call assert_equal(9, len(s:candidates))
let g:wiki_completion_case_sensitive = 1

let s:candidates = wiki#test#completion(':m', 'mar')
call assert_equal(1, len(s:candidates))
call assert_equal('marked', s:candidates[0].word)

call wiki#test#finished()
