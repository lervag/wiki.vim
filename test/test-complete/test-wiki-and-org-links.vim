source ../init.vim
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

let s:candidates = wiki#test#completion('[[', 'li')
call assert_equal(4, len(s:candidates))

let s:candidates = wiki#test#completion('[[/', 'in')
call assert_equal(7, len(s:candidates))
call assert_equal('/', s:candidates[0].word[0])

let s:candidates = wiki#test#completion('[[', 'new')
call assert_equal(0, len(s:candidates))
let g:wiki_completion_case_sensitive = 0
let s:candidates = wiki#test#completion('[[', 'new')
call assert_equal(1, len(s:candidates))
let g:wiki_completion_case_sensitive = 1

silent edit ../wiki-basic/ToC-reference.wiki

let s:candidates = wiki#test#completion('[[#2 Next chapter#', '')
call assert_equal(3, len(s:candidates))
let s:candidates = wiki#test#completion('[[#2 n', '2 n')
call assert_equal(0, len(s:candidates))
let g:wiki_completion_case_sensitive = 0
let s:candidates = wiki#test#completion('[[#2 n', '2 n')
call assert_equal(2, len(s:candidates))
let g:wiki_completion_case_sensitive = 1

" Profiling on @lervag's personal wiki
" silent edit ~/.local/wiki/index.wiki
" profile start prof.log
" profile func *
" let s:candidates = wiki#test#completion('[[/', 'in')
" profile pause

call wiki#test#finished()
