source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0

silent edit ex1-basic/index.wiki

let s:candidates = wiki#test#completion('[[', 'li')
call wiki#test#assert_equal(2, len(s:candidates))

let s:candidates = wiki#test#completion('[[/', 'in')
call wiki#test#assert_equal(3, len(s:candidates))
call wiki#test#assert_equal('/', s:candidates[0].word[0])

silent edit ex1-basic/ToC-reference.wiki

let s:candidates = wiki#test#completion('[[#2 Next chapter#', '')
call wiki#test#assert_equal(3, len(s:candidates))

" Profiling on @lervag's personal wiki
" silent edit ~/documents/wiki/index.wiki
" profile start prof.log
" profile func *
" let s:candidates = wiki#test#completion('[[/', 'in')
" profile pause

if $QUIT | quitall! | endif
